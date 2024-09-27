`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/05 09:31:05
// Design Name: 
// Module Name: exam3
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
    wire set_watch;                                              // set 모드
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






module cook_timer(
        input clk, reset_p,             // clk: 메인 클럭 신호, reset_p: 리셋 신호 (높은 활성)
        input [3:0] btn,                // 4개의 버튼 입력
        output [3:0] com,               // 4자리 7세그먼트 디스플레이의 공통 제어 신호
        output [7:0] seg_7,             // 7세그먼트 디스플레이의 세그먼트 제어 신호
        output reg timeout_led,         // 타이머가 0이 되었을 때 켜지는 LED
        output buzz,                    // 타이머가 0이 되었을 때 활성화되는 부저 신호
        output buzz_clk);               // 부저용 클럭 신호
        
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







/*
module watch_top_2(
    input clk, reset_p,       // 클럭 신호, 리셋 신호 (기본 10ns, active high)
    input [3:0] btn,          // 3비트 버튼 입력 (모드, 초 증가, 분 증가)
    output [7:0] seg_7,       // 7세그먼트 디스플레이 출력
    output [3:0] com,         // 공통 신호 출력(7세그먼트 4개)
    output led           // 모드 LED 출력
);

    parameter watch            = 3'b001; 
    parameter stop_watch    = 3'b010;
    parameter cook_watch   = 3'b100;
    
    reg [2:0] state, next_state;
    
 


    // wire 선언 및 인스턴스 연결 
    wire mode, set_watch,next;
    wire sec_btn,min_btn;                                                  // set 모드
    wire inc_sec, inc_min;                                       // increase (초 증가, 분 증가)    
    wire clk_usec, clk_msec, clk_sec, clk_min;      // 클럭 분주기  인스턴스
    wire [3:0] sec1, sec10, min1, min10;            //  bcd 인스턴스 (각 4비트씩 4개)
    wire [15:0] value; 
    
     wire [3:0] btn;
     
     edge_detector_p ed(       
          .clk(clk), .reset_p(reset_p), .cp(btn[0]),
          .p_edge(btn[0]));  
          
    assign value = {min10, min1, sec10, sec1};             // sec1, sec10, min1, min10 = value 값으로 묶어(4bit * 4 = 16bit) 값 할당
    assign inc_sec = set_watch ? sec_btn : clk_sec;       // set_watch 모드에서 sec_btn (1:참) 입력 시 increase_sec(초 증가), clk_sec (0:거짓) 입력 시 현상 유지   
    assign inc_min = set_watch ? min_btn : clk_min;     // set_watch 모드에서 min_btn (1:참) 입력 시 increase_min(분 증가), clk_min (0:거짓) 입력 시 현상 유지   
    assign mode_led = set_watch;    
              
   /////////////////////////////////////       
       wire start_stop, lap,clk_start;   
       wire [15:0] cur_time ;   
       reg [15:0] lap_time;   // 랩 타임 저장 로직
       
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;
               else if(sec_btn)lap_time = cur_time;  // 1번 버튼 상승엣지(눌렸을때 high-상승엣지)
        end                                                                     //랩 버튼이 눌렸을 때, 현재 시간을 lap_time에 저장
    
            // 표시할 값은 랩 상태에 따라 현재 시간 또는 랩 타임으로 설정
        assign value = lap ? lap_time : cur_time;
        
        // 시작/정지 상태에 따라 클럭 신호 설정
        assign clk_start = start_stop ? clk : 0; 
        
       // 현재 시간 값을 BCD 출력으로 결합
        assign cur_time = {min10, min1, sec10, sec1};
   /////////////////////////////////////////////////////////////////////////////////////////
   
    // 모드 변경 버튼 카운터 (0번 버튼 할당)
    button_cntr btn_mode( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[0]), .btn_pedge(next)
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
    
        // set 버튼  (3번 버튼 할당)
    button_cntr btn_set( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[3]), .btn_pedge(mode)
    );
    
//////////////////////////////////////////////////////////////////////////////////////////
   
    // watch - 모드 설정 T 플립플롭 (T 플립 플롭을 사용하여 모드 전환시 값 저장)
    T_flip_flop_p t_mode(
        .clk(clk), .reset_p(reset_p), 
        .t(mode), .q(set_watch)
    );
    
    // stop_watch
     T_flip_flop_p t_start(
         .clk(clk), .reset_p(reset_p), 
         .t(mode), .q(start_stop)
     );
     
    // stop_watch
    T_flip_flop_p t_lap(
       .clk(clk), .reset_p(reset_p), 
       .t(sec_btn), .q(lap)
    );    
///////////////////////////////////////////////////////////////////////////////////////////


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

/////////////////////////////////////////////////////////////////////////////////

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
    
////////////////////////////////////////////////////////////////////////////////   

     // 리셋시 상태 초기화 및 다음단계
     always @(negedge clk or posedge reset_p) begin
            if (reset_p)begin
                     state = watch;  // 리셋 상태일 경우, 상태를 S_IDLE로 초기화
            end
            else begin
                     state = next_state;  // 그 외의 경우, 다음 상태를 현재 상태로 업데이트
            end                
     end

    // 상태 전환
    always @(*) begin
        next_state = state; 
        
       case(state)    
               watch : begin  // IDLE 상태: MCU는 DHT11과의 통신을 시작하기 전 대기 상태
                        if(btn[0]) begin // 원래는 3초   // 클럭주기가 3초 미만일시  (대기상태)
                              next_state = stop_watch;         
                        end
                        else if(mode)begin
                                       if(btn[1])begin
                            
                                       end
                                       else if(btn[2])begin       
                                 
                                       end
                               end
                       end
                  
                 stop_watch : begin
                            if(btn[0]) begin // 원래는 3초   // 클럭주기가 3초 미만일시  (대기상태)
                                  next_state = cook_watch;         
                            end
                            else begin
                                if(btn[1])begin
                          
                                end
                                else if(btn[2])begin       
    
                                end
                          end
                  end      
                    cook_watch :begin
                            if(btn[0]) begin // 원래는 3초   // 클럭주기가 3초 미만일시  (대기상태)
                                  next_state = watch;         
                            end
                            else begin                                      // 3초 초과일시 (신호 감지함)
                                       if(btn[1])begin
                                                
                                       end
                                       else if(btn[2])begin       
                                                   
                                       end
                                       else if (btn[3])begin       
                                                   
                                      end
                             end
                     end
                     
                      default : next_state = watch;   
            endcase
      end     
                  
endmodule
*/