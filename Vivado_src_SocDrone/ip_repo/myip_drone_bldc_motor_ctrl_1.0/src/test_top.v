`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/19 09:18:13
// Design Name: 
// Module Name: test_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module decoder_7seg_top(
    input [3:0] sw_value,   // 입력: 4비트 스위치 값
    output  [7:0] seg_7, // 출력: 7세그먼트 신호
    output  [3:0] com    // 출력: 커먼 신호
);
    
    assign com = 4'b0000;  // 고정된 커먼 신호 할당
    
    // decoder_7seg 모듈 인스턴스화
    decoder_7seg fnd(
        .hex_value(sw_value),  // sw_value를 decoder_7seg 모듈의 hex_value에 연결
        .seg_7(seg_7)          // decoder_7seg 모듈의 seg_7에 seg_7 연결
    );

endmodule

module fnd_test_top(
    input clk,               // 입력: 클럭
    input reset_p,           // 입력: 비동기 리셋
    input [15:0] value,      // 입력: 16비트 값
    output  [7:0] seg_7,  // 출력: 7세그먼트 신호
    output  [3:0] com     // 출력: 커먼 신호
);

    // fnd_4digit_cntr 모듈 인스턴스화
    fnd_4digit_cntr fnd(
        .clk(clk),
        .reset_p(reset_p),
        .value(value),
        .seg_7(seg_7),
        .com(com)
    );

endmodule




//  기본 시계 타이머 (set 모드 - 초 증가, 분 증가 버튼)
module watch_top(
    input clk, reset_p,       // 클럭 신호, 리셋 신호 (기본 10ns, active high)
    input [2:0] btn,          // 3비트 버튼 입력 (모드, 초 증가, 분 증가)
    output [7:0] seg_7,       // 7세그먼트 디스플레이 출력
    output [3:0] com,         // 공통 신호 출력(7세그먼트 4개)
    output mode_led           // 모드 LED 출력
);

    // wire 선언 및 인스턴스 연결 
    wire mode, sec_btn, min_btn;
    wire set_watch;                                                  // set 모드
    wire inc_sec, inc_min;                                       // increase (초 증가, 분 증가)
    wire clk_usec, clk_msec, clk_sec, clk_min;      // 클럭 분주기  인스턴스
    wire [3:0] sec1, sec10, min1, min10;            //  bcd 인스턴스 (각 4비트씩 4개)
    wire [15:0] value;                                           //  sec1, sec10, min1, min10 = value 값으로 묶어(4bit * 4 = 16bit)

    // 모드 변경 버튼 카운터 (0번 버튼 할당)
    button_cntr btn_mode( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[0]), .btn_pedge(mode)
    );

    // 초 증가 버튼 카운터 (1번 버튼 할당)
    button_cntr btn_sec( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[1]), .btn_pedge(sec_btn)
    );

    // 분 증가 버튼 카운터 (2번 버튼 할당)
    button_cntr btn_min( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[2]), .btn_pedge(min_btn)
    );

    // 모드 설정 T 플립플롭 (T 플립 플롭을 사용하여 모드 전환시 값 저장)
    T_flip_flop_p t_mode(
        .clk(clk), .reset_p(reset_p), 
        .t(mode), .q(set_watch)
    );

    // 마이크로초 클럭 분주기  (기본 클럭인 10ns 를 100분주기를 통하여 1us (1 micro sec) 출력 - cp_div_100(clk_usec))
    clock_div_100 usec_clk(
        .clk(clk), .reset_p(reset_p),
        .cp_div_100(clk_usec)   // cp - clock pulse , div - divider = 클럭 펄스 분주기
    );

    // 밀리초 클럭 분주기 (출력받은 1us를 .clk_source(clk_usec) 클럭 소스에 입력하여 1000분 주기를 통하여 1ms (1 milli sec) 출력 - cp_div_1000(clk_msec))
    clock_div_1000 msec_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_usec),
        .cp_div_1000_nedge(clk_msec)
    );

    // 초 클럭 분주기 (출력받은 1ms를 .clk_source(clk_msec) 클럭 소스에 입력하여 1000분 주기를 통하여 1s (1 sec) 출력 - cp_div_1000(clk_sec))
    clock_div_1000 sec_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_msec),
        .cp_div_1000_nedge(clk_sec)
    );

    // 분 클럭 분주기 (출력받은 1sec 를 .clk_source(clk_sec) 클럭 소스에 입력하여 60분 주기를 통하여 1min 출력 - cp_div_60(clk_min))
    
    clock_div_60 min_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_sec),
        .cp_div_60_nedge(clk_min)
    );

    // BCD - segment 0부터 9까지  10진수로 나타냄 , bcd_60_sec(분주기에서 만든 출력 (clk_sec = inc_sec)을  .clk_time(inc_sec) 입력 후 bcd1(sec1) 1의자리 , bcd10(sec10) 10의자리 입력)
   // *중요* .clk_source(clk_sec)이 아닌 (inc_sec) 을 넣은 이유 : inc_sec을 넣어야  밑에 선언한 assign inc_sec = set_watch ? sec_btn : clk_sec; 동작
   //  clk_sec을 대입시 set모드 동작 및 초 증가 x (그냥 일반 타이머임), 하지만 inc_sec 대입시 set모드(초 증가) 및 기본모드 둘다 사용가능  
    counter_bcd_60 counter_sec(
        .clk(clk), .reset_p(reset_p),
        .clk_time(inc_sec),
        .bcd1(sec1), .bcd10(sec10)
    );

    // bcd_60_min(분주기에서 만든 출력 (clk_min = inc_min)을  .clk_time(inc_min) 입력 후 bcd1(min1) 1의자리 , bcd10(min10) 10의자리 입력)
   //  clk_min을 대입시 set모드 동작 및 초 증가 x (그냥 일반 타이머임), 하지만 inc_min 대입시 set모드(분 증가) 및 기본모드 둘다 사용가능  
    counter_bcd_60 counter_min(
        .clk(clk), .reset_p(reset_p),
        .clk_time(inc_min),
        .bcd1(min1), .bcd10(min10)
    );

    // 4자리 FND 디스플레이 컨트롤러 인스턴스 출력 값 대입 (+ value)
    fnd_4digit_cntr fnd(
        .clk(clk), .reset_p(reset_p), 
        .value(value), .seg_7(seg_7), .com(com)
    );

    // 값 할당
    assign value = {min10, min1, sec10, sec1};             // sec1, sec10, min1, min10 = value 값으로 묶어(4bit * 4 = 16bit) 값 할당
    assign inc_sec = set_watch ? sec_btn : clk_sec;       // set_watch 모드에서 sec_btn (1:참) 입력 시 increase_sec(초 증가), clk_sec (0:거짓) 입력 시 현상 유지   
    assign inc_min = set_watch ? min_btn : clk_min;     // set_watch 모드에서 min_btn (1:참) 입력 시 increase_min(분 증가), clk_min (0:거짓) 입력 시 현상 유지   
    assign mode_led = set_watch;                                   // set_watch 모드 시 led 모드 동작 (led 켜짐) 

endmodule




//  loadable 시계 타이머 :  기존 watch_top에서 발생하는 오류(mux에서 하강엣지 시 1min 증가)를 없앤 코드
// (clk_sec과 btn_sec 따로 선언 )(set 모드 - 초 증가, 분 증가 버튼)
module loadable_watch_top(

        input clk, reset_p,
        input [2:0] btn,
        output [7:0] seg_7,
        output [3:0] com,
        output mode_led);
        
        wire mode, sec_btn, min_btn ;
        wire set_watch;
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;       
        wire [3:0] watch_sec1, watch_sec10, watch_min1, watch_min10;    // 에러를 없애기 위해 (반전) 따로 선언  
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10;                        // 에러를 없애기 위해 (반전) 따로 선언  
        wire[15:0] value, set_value, watch_value;
        wire watch_time_load_en, set_time_load_en;                                       // 기본 모드, set모드 load_enable 선언
        
        button_cntr btn_mode( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(mode));
                
        button_cntr btn_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(sec_btn));
                
        button_cntr btn_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(min_btn));
        
        T_flip_flop_p t_mode(
                .clk(clk), .reset_p(reset_p), 
                .t(mode), .q(set_watch));
    
    // 엣지 검출기: set_watch 신호의 상승 엣지와 하강 엣지를 감지하여
    // 각각 set_time_load_en 및 watch_time_load_en 신호를 생성.
    // 이를 통해 모드 전환 시 정확한 타이밍에 로드 동작을 수행.
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(set_watch), 
                    .n_edge(watch_time_load_en), .p_edge(set_time_load_en)); 
        

        clock_div_100 usec_clk(
             .clk(clk), .reset_p(reset_p),
             .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
            .clk(clk), .reset_p(reset_p),    
            .clk_source(clk_usec),
            .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
            
        clock_div_60 min_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(inc_sec),
            .cp_div_60_nedge(clk_min));
       
       
       // loadable watch의 특징 
       // 기존 watch_top과 다르게 { .load_enable( ), .load_bcd1( ), .load_bcd10( ) } 구문이 추가되어있음.
       // 또한 sec_watch 와 sec_set 인스턴스에서 입력값이 { .bcd1( ), .bcd10( ) }  set <---> watch 서로 반대되는것을 확인
       // 이 뜻은 loadable의 특성(반전값을 저장하여 오류제거)상 set은 watch값을 watch는 set값을 저장하는것을 알 수있음.
       // load_enable 또한 값이 반전되있으며 enable값이 1(on)일때 활성화함      

       loadable_counter_bcd_60 sec_watch(
                  .clk(clk), .reset_p(reset_p),
                  .clk_time(clk_sec), 
                  .load_enable(watch_time_load_en),
                  .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                  .bcd1(watch_sec1), .bcd10(watch_sec10));
                  
       loadable_counter_bcd_60 min_watch(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .load_enable(watch_time_load_en),
                .load_bcd1(set_min1), .load_bcd10(set_min10),
                .bcd1(watch_min1), .bcd10(watch_min10));
       
         loadable_counter_bcd_60 sec_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(sec_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_sec1), .load_bcd10(watch_sec10),
                .bcd1(set_sec1), .bcd10(set_sec10));
                
          loadable_counter_bcd_60 min_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(min_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_min1), .load_bcd10(watch_min10),
                .bcd1(set_min1), .bcd10(set_min10));
        
        
       assign inc_sec = set_watch ? sec_btn : clk_sec;
     // 안씀 -  assign inc_min = set_watch ? min_btn : clk_min;
       assign mode_led = set_watch;
       assign set_value = {set_min10,set_min1, set_sec10, set_sec1};
       assign watch_value = {watch_min10,watch_min1,watch_sec10,watch_sec1};
       assign value = set_watch ? set_value : watch_value;          // set value값(1) 과 watch value(0) 값 결정
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);


endmodule


module loadable_watch_exam_top(

        input clk, reset_p,
        input [2:0] btn,
        output [15:0] value);
        
        wire mode, sec_btn, min_btn ;
        wire set_watch;
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;       
        wire [3:0] watch_sec1, watch_sec10, watch_min1, watch_min10;    // 에러를 없애기 위해 (반전) 따로 선언  
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10;                        // 에러를 없애기 위해 (반전) 따로 선언  
        wire[15:0] set_value, watch_value;
        wire watch_time_load_en, set_time_load_en;                                       // 기본 모드, set모드 load_enable 선언
        

                
        button_cntr btn_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(sec_btn));
                
        button_cntr btn_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(min_btn));
                
        button_cntr btn_mode( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(mode));
        
        T_flip_flop_p t_mode(
                .clk(clk), .reset_p(reset_p), 
                .t(mode), .q(set_watch));
    
    // 엣지 검출기: set_watch 신호의 상승 엣지와 하강 엣지를 감지하여
    // 각각 set_time_load_en 및 watch_time_load_en 신호를 생성.
    // 이를 통해 모드 전환 시 정확한 타이밍에 로드 동작을 수행.
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(set_watch), 
                    .n_edge(watch_time_load_en), .p_edge(set_time_load_en)); 
        

        clock_div_100 usec_clk(
             .clk(clk), .reset_p(reset_p),
             .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
            .clk(clk), .reset_p(reset_p),    
            .clk_source(clk_usec),
            .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
            
        clock_div_60 min_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(inc_sec),
            .cp_div_60_nedge(clk_min));
       
       
       // loadable watch의 특징 
       // 기존 watch_top과 다르게 { .load_enable( ), .load_bcd1( ), .load_bcd10( ) } 구문이 추가되어있음.
       // 또한 sec_watch 와 sec_set 인스턴스에서 입력값이 { .bcd1( ), .bcd10( ) }  set <---> watch 서로 반대되는것을 확인
       // 이 뜻은 loadable의 특성(반전값을 저장하여 오류제거)상 set은 watch값을 watch는 set값을 저장하는것을 알 수있음.
       // load_enable 또한 값이 반전되있으며 enable값이 1(on)일때 활성화함      

       loadable_counter_bcd_60 sec_watch(
                  .clk(clk), .reset_p(reset_p),
                  .clk_time(clk_sec), 
                  .load_enable(watch_time_load_en),
                  .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                  .bcd1(watch_sec1), .bcd10(watch_sec10));
                  
       loadable_counter_bcd_60 min_watch(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .load_enable(watch_time_load_en),
                .load_bcd1(set_min1), .load_bcd10(set_min10),
                .bcd1(watch_min1), .bcd10(watch_min10));
       
         loadable_counter_bcd_60 sec_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(sec_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_sec1), .load_bcd10(watch_sec10),
                .bcd1(set_sec1), .bcd10(set_sec10));
                
          loadable_counter_bcd_60 min_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(min_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_min1), .load_bcd10(watch_min10),
                .bcd1(set_min1), .bcd10(set_min10));
        
        
       assign inc_sec = set_watch ? sec_btn : clk_sec;
     // 안씀 -  assign inc_min = set_watch ? min_btn : clk_min;
     //  assign mode_led = set_watch;
       assign set_value = {set_min10,set_min1, set_sec10, set_sec1};
       assign watch_value = {watch_min10,watch_min1,watch_sec10,watch_sec1};
       assign value = set_watch ? set_value : watch_value;          // set value값(1) 과 watch value(0) 값 결정
     //   fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);


endmodule


module stop_watch_top(

        input clk, reset_p,
        input [1:0] btn,            // 두 개의 버튼 입력 (시작/정지, 랩)
        output [3:0] com,
        output [7:0] seg_7);
        
        wire btn0_pedge, btn1_pedge, start_stop, lap;   // 버튼 펄스 에지 신호, 시작/정지 및 랩 상태 신호
        wire clk_start;                                                         // 시작/정지 상태에 따라 클럭 신호 설정
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] sec1, sec10, min1, min10;                  // 초 및 분의 BCD 출력
        wire [15:0] cur_time ;
        reg [15:0] lap_time;                                              // 랩 타임 저장
        wire[15:0] value;
       
        // 표시할 값은 랩 상태에 따라 현재 시간 또는 랩 타임으로 설정
        assign value = lap ? lap_time : cur_time;
        
        // 시작/정지 상태에 따라 클럭 신호 설정
        assign clk_start = start_stop ? clk : 0; 
        
       // 현재 시간 값을 BCD 출력으로 결합
        assign cur_time = {min10, min1, sec10, sec1};
        
        // 0번 버튼 시작/정지 
        button_cntr btn_start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn0_pedge));
        
        // T 플립플롭을 사용하여 시작/정지 상태 전환      
        T_flip_flop_p t_start(
                .clk(clk), .reset_p(reset_p), 
                .t(btn0_pedge), .q(start_stop));
       
        // 1번 버튼 랩 적용        
        button_cntr btn_lap( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn1_pedge));
        
        // T 플립플롭을 사용하여 랩 상태 전환        
        T_flip_flop_p t_lap(
                .clk(clk), .reset_p(reset_p), 
                .t(btn1_pedge), .q(lap));       

          // 클럭 분주기 설정 
        clock_div_100 usec_clk(
                .clk(clk_start), .reset_p(reset_p),
                .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
                .clk(clk_start), .reset_p(reset_p),    
                .clk_source(clk_usec),
                .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
                .clk(clk_start), .reset_p(reset_p),     
                .clk_source(clk_msec),
                .cp_div_1000_nedge(clk_sec));
            
        clock_div_60 min_clk(
                .clk(clk_start), .reset_p(reset_p),     
                .clk_source(clk_sec),
                .cp_div_60_nedge(clk_min));
                
        // bcd 설정
        counter_bcd_60 counter_sec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_sec),
                .bcd1(sec1), .bcd10(sec10)); 
                  
        counter_bcd_60 counter_min(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .bcd1(min1), .bcd10(min10));

       
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
       
      // 랩 타임 저장 로직
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;
               else if(btn1_pedge)lap_time = cur_time;  // 1번 버튼 상승엣지(눌렸을때 high-상승엣지)
        end                                                                     //랩 버튼이 눌렸을 때, 현재 시간을 lap_time에 저장


endmodule


module stop_watch_exam_top(

        input clk, reset_p,
        input [1:0] btn,            // 두 개의 버튼 입력 (시작/정지, 랩)
        output [15:0] value);
        
        wire btn0_pedge, btn1_pedge, start_stop, lap;   // 버튼 펄스 에지 신호, 시작/정지 및 랩 상태 신호
        wire clk_start;                                                         // 시작/정지 상태에 따라 클럭 신호 설정
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] sec1, sec10, min1, min10;                  // 초 및 분의 BCD 출력
        wire [15:0] cur_time ;
        reg [15:0] lap_time;                                              // 랩 타임 저장

       
        // 표시할 값은 랩 상태에 따라 현재 시간 또는 랩 타임으로 설정
        assign value = lap ? lap_time : cur_time;
        
        // 시작/정지 상태에 따라 클럭 신호 설정
        assign clk_start = start_stop ? clk : 0; 
        
       // 현재 시간 값을 BCD 출력으로 결합
        assign cur_time = {min10, min1, sec10, sec1};
        
        // 0번 버튼 시작/정지 
        button_cntr btn_start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn0_pedge));
        
        // T 플립플롭을 사용하여 시작/정지 상태 전환      
        T_flip_flop_p t_start(
                .clk(clk), .reset_p(reset_p), 
                .t(btn0_pedge), .q(start_stop));
       
        // 1번 버튼 랩 적용        
        button_cntr btn_lap( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn1_pedge));
        
        // T 플립플롭을 사용하여 랩 상태 전환        
        T_flip_flop_p t_lap(
                .clk(clk), .reset_p(reset_p), 
                .t(btn1_pedge), .q(lap));       

          // 클럭 분주기 설정 
        clock_div_100 usec_clk(
                .clk(clk_start), .reset_p(reset_p),
                .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
                .clk(clk_start), .reset_p(reset_p),    
                .clk_source(clk_usec),
                .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
                .clk(clk_start), .reset_p(reset_p),     
                .clk_source(clk_msec),
                .cp_div_1000_nedge(clk_sec));
            
        clock_div_60 min_clk(
                .clk(clk_start), .reset_p(reset_p),     
                .clk_source(clk_sec),
                .cp_div_60_nedge(clk_min));
                
        // bcd 설정
        counter_bcd_60 counter_sec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_sec),
                .bcd1(sec1), .bcd10(sec10)); 
                  
        counter_bcd_60 counter_min(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .bcd1(min1), .bcd10(min10));

       
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
       
      // 랩 타임 저장 로직
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;
               else if(btn1_pedge)lap_time = cur_time;  // 1번 버튼 상승엣지(눌렸을때 high-상승엣지)
        end                                                                     //랩 버튼이 눌렸을 때, 현재 시간을 lap_time에 저장


endmodule



// sec : msec 타이머 
module stop_watch_top_sec(
        input clk, reset_p,
        input [1:0] btn,
        output [3:0] com,
        output [7:0] seg_7);
        
        wire btn0_pedge, btn1_pedge, start_stop, lap;
        
        button_cntr btn_start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn0_pedge));
                
        T_flip_flop_p t_start(
                .clk(clk), .reset_p(reset_p), 
                .t(btn0_pedge), .q(start_stop));
                
        button_cntr btn_lap( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn1_pedge));
                
        T_flip_flop_p t_lap(
                .clk(clk), .reset_p(reset_p), 
                .t(btn1_pedge), .q(lap));       
                
        wire clk_start;
        assign clk_start = start_stop ? clk : 0;   // 시작/정지 상태에 따라 클럭 신호 설정
                
        wire clk_usec, clk_msec, clk_sec, clk_min, clk_10msec;
        
        clock_div_100 usec_clk(
                .clk(clk_start), .reset_p(reset_p),
                .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
                .clk(clk_start), .reset_p(reset_p),    
                .clk_source(clk_usec),
                .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
                .clk(clk_start), .reset_p(reset_p),     
                .clk_source(clk_msec),
                .cp_div_1000_nedge(clk_sec));
         
         // 10 밀리초 단위 클럭 분주기 모듈 인스턴스화       
         clock_div_10 msecc_clk(                         // msecc : 인스턴스 명 오류로 인해 임시 변경
                .clk(clk_start), .reset_p(reset_p),
                .clk_source(clk_msec), .cp_div_10_nedge(clk_10msec));   // 10단위 msec
                
        wire [3:0] msec1, msec10, sec1, sec10;      // 개당 4비트
      
         // 밀리초 카운터 모듈 인스턴스화 (0~99 BCD 카운터)        
        counter_bcd_100 counter_msec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_10msec),                      // 10단위 msec
                .bcd1(msec1), .bcd10(msec10));      
         
        // 초 카운터 모듈 인스턴스화 (0~59 BCD 카운터)                 
        counter_bcd_60 counter_sec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_sec),
                .bcd1(sec1), .bcd10(sec10)); 
                  
       wire [15:0] cur_time ;       
       
       // 현재 시간 값을 BCD 출력으로 결합
       assign cur_time = {sec10, sec1, msec10, msec1};  // 세그먼트 자릿수 나열 (왼쪽부터 10,1sec : 10,1 ms) 
      
       // 랩 타임 저장 로직
       reg [15:0] lap_time;
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;                                         // 리셋 신호가 활성화된 경우, lap_time을 0으로 초기화
               else if(btn1_pedge)lap_time = cur_time;      // 랩 버튼이 눌렸을 때, 현재 시간을 lap_time에 저장
        end

       wire[15:0] value;
       
        // 표시할 값은 랩 상태에 따라 현재 시간 또는 랩 타임으로 설정
       assign value = lap ? lap_time : cur_time;
       
       // 4자리 7-세그먼트 디스플레이 컨트롤러 모듈 인스턴스화
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);

endmodule




module cook_timer(
        input clk, reset_p,             // clk: 메인 클럭 신호, reset_p: 리셋 신호 (높은 활성)
        input [3:0] btn,                // 4개의 버튼 입력
        output [3:0] com,               // 4자리 7세그먼트 디스플레이의 공통 제어 신호
        output [7:0] seg_7,             // 7세그먼트 디스플레이의 세그먼트 제어 신호
        output reg timeout_led        // 타이머가 0이 되었을 때 켜지는 LED
     //   output buzz,                    // 타이머가 0이 되었을 때 활성화되는 부저 신호
     // output buzz_clk
        );               // 부저용 클럭 신호
        
        wire [3:0] btn_pedge;           // 버튼의 양의 에지를 감지하는 신호
        wire [15:0] value, set_time, cur_time; // value: 현재 또는 설정된 시간, set_time: 설정된 시간, cur_time: 현재 시간
        wire load_enable;               // 시간 설정을 로드하기 위한 신호
        wire clk_usec, clk_msec, clk_sec; // 각각 마이크로초, 밀리초, 초 클럭 신호
        wire alarm_off, inc_min, inc_sec, btn_start; // 알람 끄기, 분 증가, 초 증가, 시작 버튼 신호
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10; // 설정된 초와 분의 BCD 값
        wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10; // 현재 초와 분의 BCD 값
        wire dec_clk;                   // 감소 클럭 신호
        
        reg start_stop;                 // 타이머의 시작/정지 상태를 나타내는 레지스터
        
        reg [16:0] clk_div;             // 클럭 분주기
        always @(posedge clk) clk_div = clk_div + 1; // 클럭을 분주하여 부저 클럭 신호 생성
        
        assign buzz_clk = timeout_led ? clk_div[13] : 0; // 타임아웃 시 부저 클럭 신호 출력
        assign buzz = timeout_led; // 타임아웃 시 부저 신호 출력
        
        // 시작 버튼 컨트롤
        button_cntr start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));
                 
        // 타이머 제어 로직
        always @(posedge clk or posedge reset_p) begin
                if (reset_p) begin
                        start_stop = 0;
                        timeout_led = 0;
                end
                else begin 
                    if (btn_start) start_stop = ~start_stop; // 시작/정지 버튼이 눌리면 상태 변경
                    else if (cur_time == 0 && start_stop) begin 
                        start_stop = 0;
                        timeout_led = 1; // 타이머가 0에 도달하면 LED 켜기
                    end
                    else if (alarm_off) timeout_led = 0; // 알람 끄기 버튼이 눌리면 LED 끄기
                end
        end    
        
        // 엣지 검출기
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(start_stop), 
                    .p_edge(load_enable)); 
        
        // 초 증가 버튼 컨트롤
        button_cntr btn_inc_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));
                
        // 분 증가 버튼 컨트롤
        button_cntr btn_inc_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2]));
                
        // 알람 정지 버튼 컨트롤
        button_cntr btn_alarm_stop( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[3]), .btn_pedge(btn_pedge[3]));       
        
        // 마이크로초 클럭 분주기
        clock_div_100 usec_clk(
               .clk(clk), .reset_p(reset_p),
               .cp_div_100(clk_usec));   

        // 밀리초 클럭 분주기
        clock_div_1000 msec_clk(
             .clk(clk), .reset_p(reset_p),
             .clk_source(clk_usec),
             .cp_div_1000_nedge(clk_msec));

        // 초 클럭 분주기
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
       
        // 버튼 신호 매핑
        assign {alarm_off, inc_sec, btn_start, inc_min} = btn_pedge;
       
        // 설정된 시간의 BCD 카운터 (초)
        counter_bcd_60 counter_sec(
                    .clk(clk), .reset_p(reset_p),
                    .clk_time(inc_sec),
                    .bcd1(set_sec1), .bcd10(set_sec10));

        // 설정된 시간의 BCD 카운터 (분)
        counter_bcd_60 counter_min(
                   .clk(clk), .reset_p(reset_p),
                   .clk_time(inc_min),
                   .bcd1(set_min1), .bcd10(set_min10));
           
        // 현재 시간의 다운 카운터 (초)
        loadable_down_counter_bcd_60 cur_sec(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(clk_sec),
                    .load_enable(btn_start),
                    .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                    .bcd1(cur_sec1), .bcd10(cur_sec10),
                    .dec_clk(dec_clk));
                    
        // 현재 시간의 다운 카운터 (분)
        loadable_down_counter_bcd_60 cur_min(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(dec_clk),
                    .load_enable(btn_start),
                    .load_bcd1(set_min1), .load_bcd10(set_min10),
                    .bcd1(cur_min1), .bcd10(cur_min10));

        // 설정된 시간과 현재 시간 결합
        assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
        assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
        
        // 현재 시간 또는 설정된 시간을 선택하여 출력
        assign value = start_stop ? cur_time : set_time;
        
        // 4자리 7세그먼트 디스플레이 제어
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);     
endmodule


module cook_timer_exam(
        input clk, reset_p,             // clk: 메인 클럭 신호, reset_p: 리셋 신호 (높은 활성)
        input [2:0] btn,                 // 4개의 버튼 입력
        input alarm_off,
        output [15:0] value,               
        output reg timeout_led       // 타이머가 0이 되었을 때 켜지는 LED
);               // 부저용 클럭 신호
        
        wire [2:0] btn_pedge;           // 버튼의 양의 에지를 감지하는 신호
        wire [15:0] set_time, cur_time; // value: 현재 또는 설정된 시간, set_time: 설정된 시간, cur_time: 현재 시간
        wire load_enable;               // 시간 설정을 로드하기 위한 신호
        wire clk_usec, clk_msec, clk_sec; // 각각 마이크로초, 밀리초, 초 클럭 신호
        wire  inc_min, inc_sec, btn_start; // 알람 끄기, 분 증가, 초 증가, 시작 버튼 신호
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10; // 설정된 초와 분의 BCD 값
        wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10; // 현재 초와 분의 BCD 값
        wire dec_clk;                   // 감소 클럭 신호
        
        reg start_stop;                 // 타이머의 시작/정지 상태를 나타내는 레지스터
        
        reg [16:0] clk_div;             // 클럭 분주기
        always @(posedge clk) clk_div = clk_div + 1; // 클럭을 분주하여 부저 클럭 신호 생성
        
//        assign buzz_clk = timeout_led ? clk_div[13] : 0; // 타임아웃 시 부저 클럭 신호 출력
//        assign buzz = timeout_led; // 타임아웃 시 부저 신호 출력
        

                 
        // 타이머 제어 로직
        always @(posedge clk or posedge reset_p) begin
                if (reset_p) begin
                        start_stop = 0;
                        timeout_led = 0;
                end
                else begin 
                    if (btn_start) start_stop = ~start_stop; // 시작/정지 버튼이 눌리면 상태 변경
                    else if (cur_time == 0 && start_stop) begin 
                        start_stop = 0;
                        timeout_led = 1; // 타이머가 0에 도달하면 LED 켜기
                    end
                    else if (alarm_off) timeout_led = 0; // 알람 끄기 버튼이 눌리면 LED 끄기
                end
        end    
        
        // assign sw = alarm_off;
        
        // 엣지 검출기
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(start_stop), 
                    .p_edge(load_enable)); 
        
                        
        // 초 증가 버튼 컨트롤
        button_cntr btn_inc_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));
                
        // 분 증가 버튼 컨트롤
        button_cntr btn_inc_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));
                
         // 시작 버튼 컨트롤
        button_cntr start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2]));
                
//        // 알람 정지 버튼 컨트롤
//        button_cntr btn_alarm_stop( 
//                .clk(clk), .reset_p(reset_p),
//                .btn(btn[3]), .btn_pedge(btn_pedge[3]));       
        
        // 마이크로초 클럭 분주기
        clock_div_100 usec_clk(
               .clk(clk), .reset_p(reset_p),
               .cp_div_100(clk_usec));   

        // 밀리초 클럭 분주기
        clock_div_1000 msec_clk(
             .clk(clk), .reset_p(reset_p),
             .clk_source(clk_usec),
             .cp_div_1000_nedge(clk_msec));

        // 초 클럭 분주기
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
       
        // 버튼 신호 매핑
        assign {inc_sec, btn_start, inc_min} = btn_pedge;
       
        // 설정된 시간의 BCD 카운터 (초)
        counter_bcd_60 counter_sec(
                    .clk(clk), .reset_p(reset_p),
                    .clk_time(inc_sec),
                    .bcd1(set_sec1), .bcd10(set_sec10));

        // 설정된 시간의 BCD 카운터 (분)
        counter_bcd_60 counter_min(
                   .clk(clk), .reset_p(reset_p),
                   .clk_time(inc_min),
                   .bcd1(set_min1), .bcd10(set_min10));
           
        // 현재 시간의 다운 카운터 (초)
        loadable_down_counter_bcd_60 cur_sec(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(clk_sec),
                    .load_enable(load_enable),
                    .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                    .bcd1(cur_sec1), .bcd10(cur_sec10),
                    .dec_clk(dec_clk));
                    
        // 현재 시간의 다운 카운터 (분)
        loadable_down_counter_bcd_60 cur_min(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(dec_clk),
                    .load_enable(load_enable),
                    .load_bcd1(set_min1), .load_bcd10(set_min10),
                    .bcd1(cur_min1), .bcd10(cur_min10));

        // 설정된 시간과 현재 시간 결합
        assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
        assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
        
        // 현재 시간 또는 설정된 시간을 선택하여 출력
        assign value = start_stop ? cur_time : set_time;
        
        // 4자리 7세그먼트 디스플레이 제어
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);     
endmodule



module key_pad_test_top(
            input clk, reset_p,
            input [3:0] row,
            output [3:0] col,
            output [3:0] com,
            output [7:0] seg_7,
            output key_valid);
            
        wire [3:0] key_value;
        
        
        keypad_cntr_FSM keypad(clk, reset_p, row, col, key_value, key_valid );
        
        wire [15:0] value;
        assign value = {12'b0, key_value};
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
endmodule


module dht11_test_top(
           input clk, reset_p,
           inout dht11_data, 
           output [3:0] com,
           output [7:0] seg_7,
           output [15:0] led);
           
           wire  [7:0] humidity, temperature; 
           dht11_cntr dht11(clk, reset_p, dht11_data, humidity, temperature, led);

           wire [15:0] bcd_humi, bcd_tmpr;
           bin_to_dec b2d_humi(.bin({4'b0000, humidity}), .bcd(bcd_humi));
           bin_to_dec b2d_tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr)); 
            
           wire [15:0] value;
           assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};
           fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
            
            
endmodule


module uls_test_top(
           input clk, reset_p,
           input echo, 
           output trig,
           output [3:0] com,
           output [7:0] seg_7,
           output [15:0] led);
           
           wire  [15:0] distance;
           ultrasound_cntr uls(.clk(clk), .reset_p(reset_p), .echo(echo), .trig(trig), .distance(distance), .led(led));

           wire [15:0] distance_bcd;        // distance bcd 표현 
           bin_to_dec b2d_distance(.bin(distance[11:0]), .bcd(distance_bcd));
           
           assign value = {distance_bcd};           
           fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(distance_bcd), .seg_7(seg_7), .com(com));
            
            
endmodule




module mf_watch_top(
    input clk, reset_p,          
    input [3:0] btn,                 
    input alarm_off,
    output [7:0] seg_7,             
    output [3:0] com,            
    output [15:0]led );


    parameter WATCH             = 3'b001;    
    parameter STOP_WATCH  = 3'b010; 
    parameter COOK_TIMER    = 3'b100; 
    
    wire [3:0]btn_pedge;
    wire alarm_off_pedge;
    
    reg [2:0] state, next_state;
    assign led[2:0] = state;
    
    
        button_cntr start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0])
        );
        
        
        // 엣지 검출기
        edge_detector_p ed(
                  .clk(clk), .reset_p(reset_p), .cp(alarm_off), 
                  .p_edge(alarm_off_pedge)); 
                    
        
        wire [15:0] w_value, stop_w_value, cook_w_value ;
        
        
        //모드 변경시 이전 타이머 동작 정지
        wire w_clk, sw_clk, cw_clk; 
        
        assign cw_clk = (COOK_TIMER == state) ? clk : 0;
        assign sw_clk = (STOP_WATCH == state) ? clk : 0;
        assign w_clk = (WATCH == state) ? clk : 0;
        
        
        loadable_watch_exam_top inst(
                .clk(w_clk), .reset_p(reset_p),
                .btn(btn[3:1]), .value(w_value)
         );
                    
        stop_watch_exam_top inst1(
                .clk(sw_clk), .reset_p(reset_p),
                .btn(btn[2:1]), .value(stop_w_value)
        );
                
        cook_timer_exam inst2(
                .clk(cw_clk), .reset_p(reset_p),          
                .btn(btn[3:1]), . value(cook_w_value),
                .alarm_off(alarm_off_pedge),
                .timeout_led(led[3])
        );             
    
        reg [15:0] fnd_value;

        

        
    always @(negedge clk or posedge reset_p) begin
                    if (reset_p)
                        state = WATCH;  
                    else
                        state = next_state;  
                end
            

                always @(negedge clk or posedge reset_p) begin
                                    if (reset_p) begin         
                                             next_state = WATCH;      
                                     end
                            else begin
                                       
                 
                 case(state)    
                                WATCH : begin  
                                        if(btn_pedge) begin        
                                                next_state = STOP_WATCH;
                                        end
                                        else begin 
                                                fnd_value = w_value;
                                        end
                                end
                                STOP_WATCH : begin  
                                        if(btn_pedge) begin        
                                                next_state = COOK_TIMER;          
                                        end
                                        else begin
                                                fnd_value = stop_w_value ;
                                        end
                                end
                                COOK_TIMER : begin  
                                        if(btn_pedge) begin        
                                                next_state = WATCH;          
                                        end
                                        else begin
                                                fnd_value = cook_w_value ;
                                        end
                                end
                    endcase
            end
      end      
      
       fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(fnd_value), .seg_7(seg_7), .com(com));
endmodule




module led_pwm_top(
          input clk, reset_p,
          output led_pwm, led_r, led_g, led_b );
          
          
          reg [31:0] clk_div;
          always @(posedge clk) clk_div = clk_div + 1;
          
          pwm_128step_led pwm_led(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[27:21]),
                .pwm(led_pwm)
                );
                
          pwm_128step_led pwm_led_r(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[31:25]),
                .pwm(led_r)
                );
                
           pwm_128step_led pwm_led_g(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[30:24]),
                .pwm(led_g)
                );
                
            pwm_128step_led pwm_led_b(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[29:23]),
                .pwm(led_b)
                );

endmodule


module dc_motor_pwm_top(
          input clk, reset_p,      
          output motor_pwm,
          output [3:0] com,
          output [7:0] seg_7
          );
          
          
          reg [32:0] clk_div;
          always @(posedge clk) clk_div = clk_div + 1;
          
          pwm_128step_motor pwm_motor(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[32:26]),
                .pwm(motor_pwm)
                );
         
         wire [15:0] duty_bcd;       
         bin_to_dec b2d_distance(.bin({5'b0, clk_div[32:26]}), .bcd(duty_bcd));       
         
         fnd_4digit_cntr fnd(.clk(clk),  .value(duty_bcd), .seg_7(seg_7), .com(com));
endmodule



module servo_motor_pwm_top(
          input clk, reset_p,
          input [2:0] btn,
          output servo_pwm
          );
          
          
          reg [6:0] duty;

          // 128 pwm instance
          pwm_128step_servo pwm_motor(
                .clk(clk),  .reset_p(reset_p),
                .duty(duty),
                .pwm(servo_pwm)
                );
                
        
         wire [2:0]btn_pedge;
         
          // 버튼 사용 - 버튼 상승에지 검출
          button_cntr mid( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0])
        );
        

           button_cntr left( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1])
        );
        
           button_cntr right( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2])
        );


          // 버튼 - 서보 모터 동작
          always @(negedge clk or posedge reset_p) begin
                    if (reset_p)begin
                            duty = 0 ;
                    end
                    
                    else if(btn_pedge[0])begin
                            duty = 9 ;     // 0
                    end
                    
                    else if(btn_pedge[1])begin
                            duty =  16;     // -90
                    end
                    
                    else if(btn_pedge[2])begin
                            duty = 3;        // 90
                    end
             end

endmodule




module servo_motor_pwm_top_um(
          input clk, reset_p,
          input  btn,
          output servo_pwm,
          output [3:0] com,
          output [7:0] seg_7
          );
          
          
          integer  clk_div;
          always @(posedge clk) clk_div = clk_div + 1;


         wire clk_div_nedge;
         wire btn_nedge;
         edge_detector_n ed(
                  .clk(clk), .reset_p(reset_p), .cp(clk_div[20]), 
                  .n_edge(clk_div_nedge)
        ); 
        
        button_cntr mid( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn), .btn_nedge(btn_nedge)
        );
        
          
          integer cnt;
          reg down_up;
          
          always @(posedge clk or posedge reset_p)begin
                   if(reset_p)begin
                        cnt = 6;
                        down_up = 0;
                   end      
                   else if(clk_div_nedge) begin
                            if(down_up)begin
                                    if (cnt <= 6)down_up = 0;
                                    else cnt = cnt - 1;
                            end
                            else begin
                                    if (cnt >= 32)down_up = 1;
                                   else cnt = cnt + 1;
                           end   
                    end      
           else if(btn_nedge)down_up = ~ down_up;
     end
 


          // 128 pwm instance
          pwm_128step_freq
           #(.pwm_freq(50)) 
          pwm_motor(
                .clk(clk),  .reset_p(reset_p),
                .duty(cnt),
                .pwm(servo_pwm)
                );
                
        
         wire [15:0] duty_bcd;
         
         bin_to_dec b2d_distance(.bin({cnt}), .bcd(duty_bcd));       
         
         fnd_4digit_cntr fnd(.clk(clk),  .value(duty_bcd), .seg_7(seg_7), .com(com));

endmodule





module adc_top (
        input clk, reset_p,
        input vauxp6, vauxn6,
        output [3:0] com,
        output [7:0] seg_7
);

    wire  [4:0]channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
    (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out)           // End of Conversion Signal
);
 
        
        wire eoc_out_pedge;
         edge_detector_p ed(
                  .clk(clk), .reset_p(reset_p), .cp(eoc_out), 
                  .p_edge(eoc_out_pedge)
        );   
         
         reg [11:0] adc_value;
         always @(posedge clk or posedge reset_p)begin
                    if(reset_p)adc_value = 0;
                    else if(eoc_out_pedge)begin
                           adc_value = do_out[15:4];
                    end
          end                     
        
          wire [15:0] adc_value_bcd;
          bin_to_dec btd_duty(.bin(adc_value), .bcd(adc_value_bcd));       
         
          fnd_4digit_cntr fnd(.clk(clk),  .value(adc_value_bcd), .seg_7(seg_7), .com(com));

endmodule




module led_dimmer_top (
        input clk, reset_p,
        input vauxp6, vauxn6,
        output led_pwm,
        output [3:0] com,
        output [7:0] seg_7
);

    wire  [4:0]channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
    (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out)           // End of Conversion Signal
);
 
        
        wire eoc_out_pedge;
         edge_detector_p ed(
                  .clk(clk), .reset_p(reset_p), .cp(eoc_out), 
                  .p_edge(eoc_out_pedge)
        );   
         
         reg [11:0] adc_value;
         always @(posedge clk or posedge reset_p)begin
                    if(reset_p)adc_value = 0;
                    else if(eoc_out_pedge)begin
                           adc_value = do_out[15:4];
                    end
          end                     
        

          pwm_128step_led dimmer(
                .clk(clk),  .reset_p(reset_p),
                .duty(adc_value[11:5]),
                .pwm(led_pwm));
        
        
        
        
          wire [15:0] adc_value_bcd;
          bin_to_dec btd_duty(.bin({5'b0, do_out[11:5]}), .bcd(adc_value_bcd));       
         
          fnd_4digit_cntr fnd(.clk(clk),  .value(adc_value_bcd), .seg_7(seg_7), .com(com));

endmodule


module adc_sequence2_top(

    input clk,reset_p,              // 시스템 클럭 및 리셋 신호 입력
    input vauxp6, vauxn6,           // 보조 채널 6의 양(+) 및 음(-) 입력
    input vauxp15, vauxn15,         // 보조 채널 15의 양(+) 및 음(-) 입력
    output led_r, led_g,            // LED 출력 
    output [3:0] com,               
    output [7:0] seg_7         
);

    wire [4:0] channel_out;         // 선택된 ADC 채널 출력
    wire eoc_out;                   // 변환 완료(End of Conversion) 신호 출력
    wire [15:0] do_out;             // ADC 데이터 출력

    // XADC 시퀀서 모듈 인스턴스
    xadc_sequencer adc_seq2 (
        .daddr_in({2'b0, channel_out}), // 동적 재구성 포트의 주소 버스
        .dclk_in(clk),                  // 동적 재구성 포트의 클럭 입력
        .den_in(eoc_out),               // 동적 재구성 포트의 활성화 신호
        .reset_in(reset_p),             // 시스템 모니터 제어 로직의 리셋 신호
        .vauxp6(vauxp6),                // 보조 채널 6의 양(+) 입력
        .vauxn6(vauxn6),                // 보조 채널 6의 음(-) 입력
        .vauxp15(vauxp15),              // 보조 채널 15의 양(+) 입력
        .vauxn15(vauxn15),              // 보조 채널 15의 음(-) 입력
        .channel_out(channel_out),      // 선택된 채널 출력
        .do_out(do_out),                // 동적 재구성 포트의 데이터 출력 버스
        .eoc_out(eoc_out)               // 변환 완료 신호
    );
    
    wire eoc_out_pedge;               // 변환 완료 신호의 양(+) 에지 검출 신호
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), 
        .cp(eoc_out), .p_edge(eoc_out_pedge)
    ); 

    reg [11:0] adc_value_x, adc_value_y;   // ADC 결과를 저장할 레지스터

    // ADC 값을 레지스터에 저장하는 Always 블록
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            adc_value_x = 0;           // 리셋 시 ADC 값을 0으로 초기화
            adc_value_y = 0;
        end
        else if (eoc_out_pedge) begin  // 변환 완료 신호의 양(+) 에지 검출 시
            case (channel_out[3:0])
                6: adc_value_x = do_out[15 : 4];  // 채널 6의 ADC 결과 저장
                15: adc_value_y = do_out[15 : 4]; // 채널 15의 ADC 결과 저장
            endcase
        end                     
    end
    
     pwm_128step_led pwm_r(
        .clk(clk),  .reset_p(reset_p),
        .duty(adc_value_x[11:5]),
        .pwm(led_r));
                
     pwm_128step_led pwm_g(
        .clk(clk),  .reset_p(reset_p),
        .duty(adc_value_y[11:5]),
        .pwm(led_g));
    


    wire [15:0] value, adc_value_bcd_x, adc_value_bcd_y;
    
    // ADC 결과를 BCD로 변환
    bin_to_dec bcd_x(
        .bin({6'b0, adc_value_x[11:6]}), 
        .bcd(adc_value_bcd_x)
    );       
    bin_to_dec bcd_y(
        .bin({6'b0, adc_value_y[11:6]}), 
        .bcd(adc_value_bcd_y)
    );
    
    // 4자리 7-세그먼트 디스플레이에 표시할 값을 설정
    assign value = {adc_value_bcd_x[7:0], adc_value_bcd_y[7:0]};
    
    // 4자리 7-세그먼트 디스플레이 제어 모듈 인스턴스
    fnd_4digit_cntr fnd(
        .clk(clk), 
        .value(value), 
        .seg_7(seg_7), 
        .com(com)
    );

endmodule



module I2C_master_top(
            input clk, reset_p,
            input [1:0]btn,
            output sda, scl,
            output [6:0]led);
    
            reg [7:0] data;
            reg comm_go;
    
    
            I2C_master(
                        .clk(clk), 
                        .reset_p(reset_p),
                        .addr(7'h27), 
                        .data(data), 
                        .rd_wr(0), 
                        .comm_go(comm_go), 
                        .sda(sda), 
                        .scl(scl),
                        .led(led));
                        
            wire [1:0] btn_pedge;
            button_cntr btn_0( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));
           
             button_cntr btn_1( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));
            
            always @(posedge clk or posedge reset_p) begin
                    if(reset_p)begin
                            data = 0;
                            comm_go = 0;
                    end
                    else begin
                            if(btn_pedge[0])begin
                                   data = 8'b0000_0000;
                                   comm_go = 1;              
                            end
                            else if(btn_pedge[1])begin
                                    data = 8'b1111_1111;
                                    comm_go = 1;
                            end
                            else comm_go = 0;
                     end
              end
                          
endmodule



module i2c_txtlcd_test_top(
        input clk, reset_p,            // 시스템 클럭과 리셋 신호 입력
        input [3:0]btn,                // 4개의 버튼 입력
        output scl, sda);              // I2C 클럭과 데이터 라인 출력

        // 상태 정의: 각 상태는 6비트로 표현
        parameter IDLE                                 = 6'b00_0001;  // 대기 상태
        parameter INIT                                  = 6'b00_0010;  // 초기화 상태
        parameter SEND_BYTE                     = 6'b00_0100;  // 데이터 전송 상태
        parameter SHIFT_RIGHT_DISPLAY   = 6'b00_1000;  
        parameter SHIFT_LEFT_DISPLAY     = 6'b01_0000;  
        
        
        // 100us 단위의 클럭 생성
        wire clk_usec;
        clock_div_100 usec_clk(
                .clk(clk),                  // 입력 클럭
                .reset_p(reset_p),          // 리셋 신호
                .clk_div_100(clk_usec)      // 100us 단위 클럭 출력
            );
        
        // 100us 단위로 카운트하는 레지스터 및 카운터 활성화 신호
        reg [21:0] count_usec;  
        reg count_usec_e;       

        // 카운터 로직
        always @(negedge clk or posedge reset_p) begin
            if (reset_p) begin
                count_usec = 0;  // 리셋 시 카운터 초기화
            end else begin
                if (clk_usec && count_usec_e) 
                    count_usec = count_usec + 1;  // 카운터 증가
                else if (!count_usec_e) 
                    count_usec = 0;  // 카운터 초기화
            end
        end
        
        // 버튼의 상승 에지(pedge) 검출을 위한 로직
        wire [3:0] btn_pedge;
        button_cntr btn_0( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));   // 버튼 0의 상승 에지 검출

        button_cntr btn_1( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));   // 버튼 1의 상승 에지 검출

        button_cntr btn_2( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2]));   // 버튼 2의 상승 에지 검출

        button_cntr btn_3( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[3]), .btn_pedge(btn_pedge[3]));   // 버튼 3의 상승 에지 검출

        // I2C LCD에 전송할 데이터 버퍼와 제어 신호들
        reg [7:0] send_buffer;  // 전송할 데이터 버퍼
        reg send, rs;           // 전송 시작 신호 및 레지스터 선택 신호
        wire busy;              // I2C 전송 중 상태 신호
        
        // I2C LCD 모듈로 데이터 전송
        i2c_lcd_send_byte(.clk(clk), .reset_p(reset_p),
                .addr(7'h27),                  // LCD의 I2C 주소
                .send_buffer(send_buffer),     // 전송할 데이터 버퍼
                .send(send),                   // 전송 시작 신호
                .rs(rs),                       // 레지스터 선택 신호 (명령/데이터)
                .scl(scl),                     // I2C 클럭 출력
                .sda(sda),                     // I2C 데이터 출력
                .busy(busy));                  // I2C 전송 중 상태 신호
        
        // FSM 상태 레지스터
        reg [5:0] state, next_state;
        always @(negedge clk or posedge reset_p) begin
            if (reset_p)
                state = IDLE;  // 리셋 시 초기 상태로 전환
            else 
                state = next_state;  // 다음 상태로 전이
        end
        
        // 초기화 플래그 및 데이터 카운터
        reg init_flag;
        reg [5:0] cnt_data; // 2^3 = 8 -> A B C D E F G H 
        
        // FSM 상태 전이 및 동작
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) begin
                init_flag = 0;            // 초기화 플래그 초기화
                next_state = IDLE;        // IDLE 상태로 전환
                send = 0;                 // 전송 비활성화
                send_buffer = 0;          // 데이터 버퍼 초기화
                cnt_data = 0;             // 데이터 카운터 초기화
                rs = 0;                   // 레지스터 선택 초기화
            end else begin
                case(state)
                    IDLE: begin
                        if (init_flag) begin
                            if (btn_pedge[0]) next_state = SEND_BYTE;  // 버튼이 눌리면 SEND_BYTE 상태로 전환                               
                            if(btn_pedge[1])  next_state = SHIFT_LEFT_DISPLAY;  
                            if(btn_pedge[2])  next_state = SHIFT_RIGHT_DISPLAY;  
                        end else begin
                            if (count_usec <= 22'd80_000) begin
                                count_usec_e = 1;  // 80ms 동안 대기
                            end else begin
                                init_flag = 1;  // 초기화 완료 플래그 설정
                                next_state = INIT;  // INIT 상태로 전환
                                count_usec_e = 0;  // 카운터 비활성화
                            end
                        end
                    end
                    INIT: begin
                        if (busy) begin
                            send = 0;  // 전송 완료 시 전송 비활성화
                            if (cnt_data >= 6) begin
                                cnt_data = 0;  // 데이터 카운터 초기화
                                next_state = IDLE;  // IDLE 상태로 전환
                                init_flag = 1;  // 초기화 완료 플래그 설정
                            end
                        end else if(send == 0) begin
                            case(cnt_data)
                                0: send_buffer = 8'h33;  // 초기화 명령 전송
                                1: send_buffer = 8'h32;
                                2: send_buffer = 8'h28;
                                3: send_buffer = 8'h0c;
                                4: send_buffer = 8'h01;
                                5: send_buffer = 8'h06;
                            endcase
                            send = 1;  // 데이터 전송 시작
                            cnt_data = cnt_data + 1;  // 데이터 카운터 증가
                        end
                    end
                    SEND_BYTE: begin
                        if (busy) begin
                            next_state = IDLE;  // 전송 완료 시 IDLE 상태로 전환
                            send = 0;  // 전송 비활성화
                            if(cnt_data >= 9) cnt_data = 0;
                            cnt_data = cnt_data + 1;
                        end 
                        else begin
                            rs = 1;  // 데이터 모드로 설정
                            send_buffer = "0" + cnt_data;  // 전송할 데이터 설정
                            send = 1;  // 전송 시작
                        end
                 end 
                         SHIFT_LEFT_DISPLAY: begin
                            if (busy) begin
                                next_state = IDLE;  // 전송 완료 시 IDLE 상태로 전환
                                send = 0;  // 전송 비활성화
                        end 
                        else begin
                            rs = 0;  // 데이터 모드로 설정
                            send_buffer = 8'h18;  // 전송할 데이터 설정
                            send = 1;  // 전송 시작
                        end
                     end
                         SHIFT_RIGHT_DISPLAY: begin
                            if (busy) begin
                                next_state = IDLE;  // 전송 완료 시 IDLE 상태로 전환
                                send = 0;  // 전송 비활성화
                        end 
                        else begin
                            rs = 0;  // 데이터 모드로 설정
                            send_buffer = 8'h1c;  // 전송할 데이터 설정
                            send = 1;  // 전송 시작
                        end
                    end
                endcase
            end
        end
        
endmodule



module stop_watch_reg(
    input clk, reset_p,
    input [1:0] control_reg,
    output [3:0] com,
    output [7:0] seg_7
);
    
    wire start_stop, lap, lap_pedge;
    assign {start_stop, lap} = control_reg;
    
    edge_detector_p ed_div(
        .clk(clk), .reset_p(reset_p), .cp(lap), .p_edge(lap_pedge));
       
    
    wire clk_start;
    assign clk_start = start_stop ? clk : 0;
    
    wire clk_usec, clk_msec, clk_min;
    clock_div_100 usec_clk(                              
        .clk(clk_start),                          // clk占쏙옙 clk占쏙옙 占쏙옙트占쏙옙 占쏙옙占쏙옙              
        .reset_p(reset_p),                  // reset_p占쏙옙 reset_p占쏙옙 占쏙옙트占쏙옙 占쏙옙占쏙옙      
        .cp_div_100(clk_usec)
    );             // clk_usec占쏙옙 cp_div_100占쏙옙 占쏙옙트占쏙옙 占쏙옙占쏙옙          
     
    clock_div_1000 msec_clk(
        .clk(clk_start),                         // clk占쏙옙 clk占쏙옙 占쏙옙트占쏙옙 占쏙옙占쏙옙                   
        .reset_p(reset_p),                 // reset_p占쏙옙 reset_p占쏙옙 占쏙옙트占쏙옙 占쏙옙占쏙옙           
        .clk_source(clk_usec),               
        .cp_div_1000_nedge(clk_msec)
    );       
      
    clock_div_1000 sec_clk(
        .clk(clk_start),
        .reset_p(reset_p),        
        .clk_source(clk_msec),      
        .cp_div_1000_nedge(clk_sec)
    );    
      
    clock_div_60 min_clk(
        .clk(clk_start),
        .reset_p(reset_p),  
        .clk_source(clk_sec),
        .cp_div_60_nedge(clk_min)
    );
    
    wire [3:0] sec1, sec10, min1, min10;
    counter_bcd_60 counter_sec(
        .clk(clk), .reset_p(reset_p),
        .clk_time(clk_sec),
        .bcd1(sec1), .bcd10(sec10)
    );

    counter_bcd_60 counter_min(
        .clk(clk), .reset_p(reset_p),
        .clk_time(clk_min),
        .bcd1(min1), .bcd10(min10)
    );
    
    wire [15:0] cur_time;
    assign cur_time = {min10, min1, sec10, sec1};
    reg [15:0] lap_time;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)lap_time = 0;
        else if(lap_pedge)lap_time = cur_time;
    end
        
    wire [15:0] value;

    assign value = lap ? lap_time : cur_time;
    fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
    
endmodule

