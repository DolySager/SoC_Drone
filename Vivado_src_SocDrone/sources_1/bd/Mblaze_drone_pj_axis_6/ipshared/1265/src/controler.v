`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/21 09:35:38
// Design Name: 
// Module Name: controler
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


module fnd_4digit_cntr(
    input clk,              // 입력: 클럭
    input reset_p,          // 입력: 비동기 리셋
    input [15:0] value,     // 입력: 16비트 값
    output [7:0] seg_7, // 출력: 7세그먼트 신호
    output [3:0] com    // 출력: 커먼 신호
);
    
    // ring_counter_fnd 모듈 인스턴스화
    ring_counter_fnd rc(
        .clk(clk),
        .reset_p(reset_p),
        .q(com)
    );
    
    reg [3:0] hex_value;     // 4비트 헥스값 저장용 레지스터 선언
    
    // decoder_7seg 모듈 인스턴스화
    decoder_7seg dec(
        .hex_value(hex_value),
        .seg_7(seg_7)
    );
    
    // 클럭의 양성 에지에 대한 always 블록
    always @(posedge clk) begin
        // 커먼 신호에 따라 value 값을 4비트 헥스값에 할당
        case(com)
            4'b1110 : hex_value = value[3:0];
            4'b1101 : hex_value = value[7:4];
            4'b1011 : hex_value = value[11:8];
            4'b0111 : hex_value = value[15:12];
        endcase
    end

endmodule



module button_cntr(
    input clk, reset_p,        // 입력 클럭 및 비동기 리셋 신호
    input btn,                 // 입력 버튼 신호
    output btn_pedge, btn_nedge // 출력 버튼의 양극성 엣지 신호
);

    reg [16:0] clk_div;        // 17비트 클럭 분주기 레지스터
    always @(posedge clk) clk_div = clk_div + 1;  // 클럭 분주기 카운터 업데이트

    wire clk_div_16_pedge;     // 클럭 분주기 16번째 비트의 양극성 엣지 신호
    edge_detector_n ed_div(    // 클럭 분주기의 양극성 엣지 감지기 인스턴스
        .clk(clk), .reset_p(reset_p), 
        .cp(clk_div[16]), .p_edge(clk_div_16_pedge)
    );    

    reg debounced_btn;         // 디바운스된 버튼 신호 레지스터
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            debounced_btn = 0;  // 리셋 신호가 활성화되면 디바운스된 버튼 신호 초기화
        else if (clk_div_16_pedge)
            debounced_btn = btn;  // 클럭 분주기의 16번째 비트의 양극성 엣지에서 버튼 값을 갱신
    end

    edge_detector_n ed(        // 버튼의 양극성 엣지 감지기 인스턴스
        .clk(clk), .reset_p(reset_p), .cp(debounced_btn), 
        .p_edge(btn_pedge), .n_edge(btn_nedge)
    );            

endmodule




module led_test_top(
    input clk,              // 입력: 클럭
    input reset_p,          // 입력: 비동기 리셋
    output [15:0] q         // 출력: 16비트 출력 q
);

    ring_counter_led rc(clk, reset_p, q);  // ring_counter_led 모듈 인스턴스화

endmodule



module keypad_cntr_FSM(
        input clk, reset_p,
        input [3:0] row,
        output reg [3:0] col,
        output reg [3:0] key_value,
        output reg key_valid );     // 키입력시 key_valid = 1, 아닐시 0
        
        // 키패드의 각 열(col)을 스캔하는 상태      *row는 행 
       parameter SCAN_0             = 5'b00001;
       parameter SCAN_1             = 5'b00010;
       parameter SCAN_2             = 5'b00100;
       parameter SCAN_3             = 5'b01000;
       parameter KEY_PROCESS  = 5'b10000;
       
       reg [4:0] state, next_state;
       
       // 상태 전이 조건 : row값이 0이면 다음 스캔으로 넘어감 , 1이면 key_process로 전이
       // 예시 (col,row) - 8'b0100 0010 일시 scan_1까진 row가 0 이어서 패스
       // scan_2 일때  8'b0100 0010 row 값이 1이 있으므로 key_process로 이동
       
       always @* begin      
                case(state)
                        SCAN_0 : begin
                                    if(row == 0) next_state = SCAN_1;
                                    else next_state = KEY_PROCESS;
                        end
                        SCAN_1 : begin
                                    if(row == 0) next_state = SCAN_2;
                                    else next_state = KEY_PROCESS;
                        end
                        SCAN_2 : begin
                                    if(row == 0) next_state = SCAN_3;
                                    else next_state = KEY_PROCESS;
                        end
                        SCAN_3 : begin
                                    if(row == 0) next_state = SCAN_0;
                                    else next_state = KEY_PROCESS;
                        end
                        KEY_PROCESS : begin
                                    if(row == 0) next_state = SCAN_0;
                                    else next_state = KEY_PROCESS;         
                        end
                endcase
       end 
       
        wire clk_8msec_n, clk_8msec_p;
        
       // 현재 상태 업데이트  
       always @(posedge clk or posedge reset_p)begin
                 if(reset_p)state = SCAN_0;
                 else if(clk_8msec_p)state = next_state;
       end
        
        // 클럭 분주(분주하여 8밀리초 주기 생성 ) 및 엣지 검출(클럭신호의 양극성 감지)
        reg [19:0] clk_div;
        always @(posedge clk)clk_div = clk_div + 1;
        
       
        edge_detector_n ed(        // 버튼의 양극성 엣지 감지기 인스턴스
                .clk(clk), .reset_p(reset_p), .cp(clk_div[19]), 
                .n_edge(clk_8msec_n), .p_edge(clk_8msec_p));

        // 링카운터 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) begin           // 리셋시 초기화
                        col = 4'b0001;
                        key_value = 0;
                        key_valid  = 0;
                end        
                else if(clk_8msec_n)begin   // 8밀리초 주기의 클럭신호 하강엣지에서 시작 
                      case(state) //  상태에 따라 열(col)을 변경
                                SCAN_0 : begin col = 4'b0001; key_valid = 0; end
                                SCAN_1 : begin col = 4'b0010; key_valid = 0; end
                                SCAN_2 : begin col = 4'b0100; key_valid = 0; end
                                SCAN_3 : begin col = 4'b1000; key_valid = 0; end
                                KEY_PROCESS : begin     // row = 1 일시 그열의 key process로 이동하여  key_value 값 출력
                                      key_valid = 1;            // 키 입력시 1
                                      case({col, row})
                                            8'b0001_0001 : key_value = 4'h7;
                                            8'b0001_0010 : key_value = 4'h4;
                                            8'b0001_0100 : key_value = 4'h1;
                                            8'b0001_1000 : key_value = 4'hC;
                                            
                                            8'b0010_0001 : key_value = 4'h8;
                                            8'b0010_0010 : key_value = 4'h5;
                                            8'b0010_0100 : key_value = 4'h2;
                                            8'b0010_1000 : key_value = 4'h0;
                                            
                                            8'b0100_0001 : key_value = 4'h9;
                                            8'b0100_0010 : key_value = 4'h6;
                                            8'b0100_0100 : key_value = 4'h3;
                                            8'b0100_1000 : key_value = 4'hF;
                                            
                                            8'b1000_0001 : key_value = 4'hA;
                                            8'b1000_0010 : key_value = 4'hb;
                                            8'b1000_0100 : key_value = 4'hE;
                                            8'b1000_1000 : key_value = 4'hd;
                                      endcase                      
                                  end  
                           endcase
                     end
               end

endmodule


module dht11_cntr(
           input clk, reset_p,
           inout dht11_data,     // input ,output 둘다 사용가능  ,온습도 센서 데이터
           output reg [7:0] humidity, temperature,          // 온도,습도 8비트씩 
           output [15:0] led );    
           
           parameter S_IDLE                = 6'b00_0001;        // 대기 상태 (초기상태에서 3초 기다린 후 다음상태 전환)
           parameter S_LOW_18MS    = 6'b00_0010;        // 18ms 동안 low상태 유지 후 다음 상태로 전환
           parameter S_HIGH_20US    = 6'b00_0100;        // 20us 동안 high상태 유지하고 dht_nedge 신호 대기 , 감지되면 20us이후 전환
           parameter S_LOW_80US     = 6'b00_1000;       // 80us 동안 low상태 유지하고 dht_pedge 신호 대기 , 감지되면 다음 상태로  전환
           parameter S_HIGH_80US     = 6'b01_0000;      // 80us 동안 high상태 유지하고 dht_nedge 신호 대기 , 감지되면 다음상태로 전환
           
           // 데이터 비트를 수신하고, 수신된 데이터를 처리
           // 하위 상태: S_WAIT_PEDGE와 S_WAIT_NEDGE로 분기
           //데이터 수신이 완료되면 data_count가 40이 되어 humidity와 temperature 데이터를 추출하고 S_IDLE 상태로 전환
           parameter S_READ_DATA    = 6'b10_0000;      
           
           parameter S_WAIT_PEDGE  = 2'b01;     // dht_pedge가 감지되면 S_WAIT_NEDGE 상태로 전환
           parameter S_WAIT_NEDGE  = 2'b10;   // dht_nedge가 감지되면 다음 데이터 비트를 처리하거나 데이터 수신이 완료될 때 S_READ_DATA 상태로 전환
        
            reg [21:0] count_usec;                   // 3초  - 3,000,000 us - 22비트  
            wire clk_usec;
            reg count_usec_e;                           // 클럭주기 측정 활성화 여부 신호  (MCU 신호 감지 중 여부)
            
            // 10ns 기본클럭을 100분주로 1us 출력 
            clock_div_100 us_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
            
            
            // 활성화시 마이크로세크 1씩 카운트 
            always @(negedge clk or posedge reset_p)begin
                    if(reset_p)count_usec = 0;                  // 리셋시 count_usec 0 초기화
                    else if(clk_usec && count_usec_e)count_usec = count_usec + 1;       // clk_usec과 count_usec_e 이 활성화 상태일때 카운트 측정 
                    else if(count_usec_e == 0)count_usec = 0;       // 만약 count_usec_e 비활성화 상태이면 0으로 재설정
            end  
            
            
            wire dht_nedge, dht_pedge;
            
             // 클럭 상승 에지 및 하락 에지 감지 모듈
            edge_detector_p ed(       
            .clk(clk), .reset_p(reset_p), .cp(dht11_data),
            .n_edge(dht_nedge), .p_edge(dht_pedge));         
           
            // FSM 상태 레지스터
            reg [5:0] state, next_state;
            reg [1:0] read_state;
            
            
               // 리셋시 상태 초기화 및 다음단계
                always @(negedge clk or posedge reset_p) begin
                    if (reset_p)
                        state = S_IDLE;  // 리셋 상태일 경우, 상태를 S_IDLE로 초기화
                    else
                        state = next_state;  // 그 외의 경우, 다음 상태를 현재 상태로 업데이트
                end
                
                assign led[5:0] = state;
                
                // DHT11 센서에서 수신된 데이터를 저장하는 레지스터
                reg [39:0] temp_data;  // 40비트 크기의 레지스터로, 온도와 상대습도 정보 저장
                reg [5:0] data_count;  // 데이터 수신 카운터, 몇 번째 데이터인지 카운트
                reg dht11_buffer;     // DHT11 센서 데이터를 임시로 저장하는 버퍼
                
                // dht11_data 신호에 dht11_buffer의 값을 연결하여 센서와 데이터 통신을 가능하게 함
                assign dht11_data = dht11_buffer;
            
            
                        // 리셋 시 초기화 
                        always @(negedge clk or posedge reset_p) begin
                                    if (reset_p) begin          // 리셋 상태
                                             count_usec_e = 0;             // 클럭 주기 측정 활성화 여부 신호를 0으로 비활성화(초기화)
                                             next_state = S_IDLE;          // 다음 상태를 IDLE(대기)상태로 설정
                                             read_state = S_WAIT_PEDGE;    // 데이터 읽기 상태 초기화 (리드 상태를 PEDGE 감지 신호를 기다리는 상태로 설정)
                                             data_count = 0;               // 데이터 비트 카운터 초기화
                                             dht11_buffer = 'bz;           // DHT11 버퍼 초기화 (하이 임피던스 - 다른 회로에 의해 버퍼의 출력이 변형되거나 간섭을 받지 않도록 하기 위한 보호 조치) 
                                     end
                                    else begin
                       
                       
                       //if (count_usec < 클럭 주기) - 클럭주기 미만일시 mcu 신호를 감지하는것을  뜻함 (기존 상태 유지중 )
                            case(state)    
                                S_IDLE : begin  // IDLE 상태: MCU는 DHT11과의 통신을 시작하기 전 대기 상태
                                    if(count_usec < 22'd3_000_000) begin // 원래는 3초   // 클럭주기가 3초 미만일시  (대기상태)
                                        count_usec_e = 1;                  // 클럭 주기 측정 활성화 (활성화시 MCu신호 감지중)
                                        dht11_buffer = 'bz;                // 버퍼를 하이 임피던스로 유지
                                    end
                                    else begin                                      // 3초 초과일시 (신호 감지함)
                                        next_state = S_LOW_18MS;           // 다음 상태인 LOW 상태로 전환
                                        count_usec_e = 0;                  // 카운터 비활성화 (MCU신호 감지 해서)
                                    end
                                end
                                
                                S_LOW_18MS : begin  // MCU가 DHT11에 시작 신호를 보냄 (버스를 낮은 전압으로 18ms 유지)
                                    if(count_usec < 22'd18_000) begin   // 18ms 미만일시 = mcu 신호 감지 중 (MCU 신호를 최소 18ms 보장 하며, )
                                        dht11_buffer = 0;                  // 버퍼를 낮은 전압으로 설정
                                        count_usec_e = 1;                  // 마이크로초 카운터 활성화 (활성화시 MCU 신호 감지중)
                                    end
                                    else begin
                                        next_state = S_HIGH_20US;          // 18ms 후(감지 후) HIGH 상태로 전환
                                        count_usec_e = 0;                  // 카운터 비활성화
                                        dht11_buffer = 'bz;                // 버스를 하이 임피던스로 설정
                                    end
                                end
                                S_HIGH_20US : begin
                                        count_usec_e = 1;
                                        if(count_usec > 22'd100_000)begin
                                            next_state = S_IDLE;       // LOW 80us 상태로 전환
                                            count_usec_e = 0;              // 카운터 비활성화
                                        end
                                        if(dht_nedge)begin
                                            next_state = S_LOW_80US;       // LOW 80us 상태로 전환
                                            count_usec_e = 0;      
                                         end
                                  end       
                                S_LOW_80US : begin
                                    // DHT11의 응답 신호 (LOW 80us)
                                    if(dht_pedge) begin
                                        next_state = S_HIGH_80US;          // HIGH 80us 상태로 전환
                                    end
                                end
                                S_HIGH_80US : begin
                                    // DHT11의 데이터 전송 준비 신호 (HIGH 80us)
                                    if(dht_nedge) begin
                                        next_state = S_READ_DATA;          // 데이터 읽기 상태로 전환
                                    end
                                end
                                S_READ_DATA : begin
                                    // DHT11로부터 데이터 읽기
                                    case(read_state)
                                        S_WAIT_PEDGE : begin
                                            if(dht_pedge) read_state = S_WAIT_NEDGE;  // 상승 에지 감지 후 다음 상태로 전환
                                            count_usec_e = 0;                         // 카운터 비활성화
                                        end
                                        S_WAIT_NEDGE : begin
                                            if(dht_nedge) begin                      // 하강 에지 감지
                                                if(count_usec < 45) begin            // LOW 신호가 45us 미만이면
                                                    temp_data = {temp_data[38:0], 1'b0};  // 비트 '0' 저장
                                                end 
                                                else begin
                                                    temp_data = {temp_data[38:0], 1'b1};  // 비트 '1' 저장
                                                end
                                                data_count = data_count + 1;          // 데이터 비트 카운터 증가
                                                read_state = S_WAIT_PEDGE;            // 다음 비트를 위해 상태 전환
                                            end
                                            else count_usec_e = 1;                    // 카운터 활성화
                                            if(count_usec > 22'd700_000)begin
                                                   next_state = S_IDLE;
                                                   count_usec_e = 0;
                                                   data_count=0;
                                                   read_state = S_WAIT_PEDGE; 
                                            end
                                        end         
                                    endcase                                   
                                if(data_count >= 40) begin
                                    // 40비트 데이터를 모두 읽었으면
                                    data_count = 0;                           // 데이터 비트 카운터 초기화
                                    next_state = S_IDLE;                      // IDLE 상태로 전환
                                    if((temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8]) == temp_data[7:0])begin
                                            humidity = temp_data[39:32];              // 습도 데이터 저장
                                            temperature = temp_data[23:16];           // 온도 데이터 저장
                                end
                        end     
                    end
                    default : next_state = S_IDLE;                    // 기본 상태는 IDLE
                endcase                                 
            end                        
        end
                       
endmodule

/* dht11 데이터시트 내용

5.1 전체 통신 프로세스

MCU가 시작 신호를 보냄.
DHT11은 저전력 모드에서 작동 모드로 전환.
DHT11이 40비트 데이터 응답 신호를 MCU에 전송.
데이터 수집 후 DHT11은 저전력 모드로 전환.

5.2 MCU가 DHT에 시작 신호를 보냅니다

데이터 라인은 고전압 상태.
MCU는 데이터 라인을 낮은 전압으로 최소 18ms 설정.
MCU는 전압을 높이고 20-40us 동안 대기.

5.3 DHT의 MCU에 대한 응답

DHT가 시작 신호를 감지하면, 80us 동안 낮은 신호 전송.
DHT는 데이터 전송 준비를 위해 80us 동안 높은 신호 유지.
모든 데이터 비트는 50us 동안 낮은 신호로 시작하고, 높은 신호의 길이로 0 또는 1을 결정.

*/

        // 조합회로의 입력 -> 출력 나오는 시간 pdt의 총합 
                // pdt가 10ns보다 적어야함
                // 10ns pdt가 끝나고 제대로된 출력값이 끝나야함
                //  -값일시 pdt 가 더길음 * 여유가없음 
                // 이를방지하기위해 클럭주기를 늘리는데 대신 속도가 저하됨  
                // wns - worst 네거티브 슬랙 
                


// 초음파 센서 컨트롤러
module ultrasound_cntr(
            input clk, reset_p,
            input echo,                                 // 에코 입력 (에코핀의 상승,하강엣지를 입력으로 받아 상태 제어)
            output reg trig,                          // 트리거 출력 (트리거의 출력값을 에코핀이 받아 동작)
            output reg [15:0] distance,      // 거리 비트
            output [7:0] led
);


/*      0. 대기 상태 idle 
        1. HC-SR04 Trig Pin에 최소한 10 us의 트리거 펄스를 전송해야 합니다.
        2. 그런 다음 HC-SR04는 자동으로 40 kHz의 음파 8개를 보내고 Echo 핀에서 상승 에지 출력을 기다립니다.
        3. 에코 핀에서 상승 에지 캡처가 발생하면 타이머를 시작하고 에코 핀에서 하강 에지를 기다립니다.
        4. Echo 핀에서 하강 에지가 캡처되면 즉시 타이머의 카운트를 읽습니다.*/
        
            parameter S_IDLE        =5'b00001;
            parameter S_10US       =5'b00010;
            parameter S_40KHZ    = 5'b00100;
            parameter S_TIMER     = 5'b01000;
            parameter S_READ      = 5'b10000;


            wire clk_usec;                              // 마이크로sec 클럭 
            wire uls_nedge, uls_pedge;      // 하강, 상승엣지
            
            reg count_usec_e;                           // 마이크로 sec 카운트 활성화 여부
            reg [19:0] count_usec;                   // 마이크로 sec 카운트 
            reg [4:0] state, next_state;            // 현재상태 ,다음상태

            assign led[5:0] = state;                // 각 상태마다 led 점등 
            
            
            // 기본클럭 10ns 를 100분주기를 통해서 1us 만듬
            clock_div_100 us_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
   
      
/* 58 분주기를 사용하여  worst negative slack 없앰 
            reg cnt_e;
            wire [11:0] cm;
      
            sr_04_div_58 clk_cm(
            .clk(clk), .reset_p(reset_p), .clk_usec(clk_usec),
            .cnt_e(cnt_e), .cm(cm));
*/

            
            // 마이크로 sec = 1 && 마이크로 카운터 (e - enable) 활성화 시 = 카운트 증가 
            // (즉, 활성화 되있는 동안 클럭 1값 횟수 셈  -> 초음파 거리구하는공식, 10 us이상 카운트 때  필요 )  
             always @(negedge clk or posedge reset_p)begin
                    if(reset_p)count_usec = 0;                  // 리셋시 count_usec 0 초기화
                    
                    else if(clk_usec && count_usec_e)count_usec = count_usec + 1;       // clk_usec과 count_usec_e 이 활성화 상태일때 카운트 측정 
                    
                    else if(count_usec_e == 0)count_usec = 0;       // 만약 count_usec_e 비활성화 상태이면 0으로 재설정
            end  


             // 에코의 상승과 하강엣지를 검출(pedge와 nedge 신호로 단계 실행)
            edge_detector_p ed(                                     // 엣지디텍터_n에서 p로 변경 , worst negative slack 최소화        
            .clk(clk), .reset_p(reset_p), .cp(echo),
            .n_edge(uls_nedge), .p_edge(uls_pedge));     


            
               // 리셋시 idle 대기 상태 및 그외엔 다음 단계
                always @(negedge clk or posedge reset_p) begin
                    if (reset_p)
                        state = S_IDLE;  // 리셋 상태일 경우, 상태를 S_IDLE로 초기화
                    else
                        state = next_state;  // 그 외의 경우, 다음 상태를 현재 상태로 업데이트
                end
            
                // 리셋시 값 및 상태 초기화
                always @(negedge clk or posedge reset_p) begin
                                    if (reset_p) begin          // 리셋 상태
                                             trig = 0;
                                             distance = 0;
                                             next_state = S_IDLE;          // 다음 상태를 IDLE(대기)상태로 설정
                                             count_usec_e = 0;             // 클럭 주기 측정 활성화 여부 신호를 0으로 비활성화(초기화)
                                     end
                            else begin
                 
                 case(state)    
                                S_IDLE : begin      // 대기상태 시작
                                        if(count_usec > 20'd1_000_000) begin            // 마이크로세크 카운트가 활성화 되어  카운트 됨  10us 이상 카운트시 시작  
                                                count_usec_e = 0;                                       // 비활성화하고  
                                                next_state = S_10US;                                // 다음단계 넘어감 
                                        end
                                        else    
                                               count_usec_e=1;                                      // else문 먼저 시작 :  마이크로세크 카운트 활성화 = 1
                                        end    

                                S_10US : begin // 40k HZ 음파 8개 기본 시스템 동작이므로 생략      
                                        if(count_usec > 16'd12) begin     // 활성화 되어 12us이상 시 시작
                                                    count_usec_e = 0;           //  비활성화
                                                    trig = 0;                           // trig = 0 (low)
                                                    next_state = S_TIMER;       // 다음단계 넘어감
                                        end
                                      else begin                            // else begin 먼저 시작
                                            trig = 1;                           // trig = 1 (high)
                                            count_usec_e = 1;           // 똑같이 활성화 
                                         end
                                end       
   
                                S_TIMER : begin
                                    if(uls_pedge)begin                  // 에코핀에서 상승엣지시 시작
                                        count_usec_e = 1;               // 활성화 
                                        next_state = S_READ;            // 다음단계
                                   end             
                                end
                                S_READ : begin
                                      if(uls_nedge) begin                           //에코핀 하강엣지 시 시작 
                                            //distance = cm ;    //58 분주기 로 바꿔야함
                                            distance = count_usec  / 58  ;      // 거리 공식 : 센티미터(cm) 단위: 거리(cm) = (시간(?s) / 58)
                                            next_state = S_IDLE;                    // 다시 처음단계인 대기상태로 넘어감 
                                            count_usec_e = 0;                       // 비활성화 
                                end
                           end     
                   endcase
                end
        end
endmodule



module pwm_128step_led(
    input clk,           // 입력 클럭 신호
    input reset_p,       // 비동기 리셋 신호 (active high)
    input [6:0] duty,
    output reg pwm
);
    
    parameter sys_clk_freq = 100_000_000;
    parameter pwm_freq = 10000;
    parameter duty_step = 128;
    parameter temp = sys_clk_freq / pwm_freq / duty_step;       
    parameter temp_half = temp /2 ;                                            
    
    integer cnt;
    reg pwm_freqX128;
    
    // 이 과정은 pwm_freqX128 신호를 생성하여, PWM 주파수를 128배 빠르게 만듬
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77까지  
                    else cnt = cnt + 1;                         // 카운트 증가
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 이하 0
                    else pwm_freqX128 = 1;                          // 39 이상 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    
    reg [6:0] cnt_duty;  // 7비트 카운터 레지스터 (0부터 99까지 셈)
    
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
            
             // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
            else if(pwm_freqX128_nedge)begin   
            cnt_duty = cnt_duty + 1;
                    if (cnt_duty < duty)pwm = 1;
                    else pwm = 0;
            end
     end
    

    
endmodule




module pwm_128step_motor(
    input clk,           // 입력 클럭 신호
    input reset_p,       // 비동기 리셋 신호 (active high)
    input [6:0] duty,
    output reg pwm
);
    
    parameter sys_clk_freq = 100_000_000;
    parameter pwm_freq = 100;
    parameter duty_step = 128;
    parameter temp = sys_clk_freq / pwm_freq / duty_step;       
    parameter temp_half = temp /2 ;                                            
    
    integer cnt;
    reg pwm_freqX128;
    
    // 이 과정은 pwm_freqX128 신호를 생성하여, PWM 주파수를 128배 빠르게 만듬
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77까지  
                    else cnt = cnt + 1;                         // 카운트 증가
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 이하 0
                    else pwm_freqX128 = 1;                          // 39 이상 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    
    reg [6:0] cnt_duty;  // 7비트 카운터 레지스터 (0부터 99까지 셈)
    
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
            
             // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
            else if(pwm_freqX128_nedge)begin   
            cnt_duty = cnt_duty + 1;
                    if (cnt_duty < duty)pwm = 1;
                    else pwm = 0;
            end
     end
    

    
endmodule




module pwm_128step_servo(
    input clk,           // 입력 클럭 신호
    input reset_p,       // 비동기 리셋 신호 (active high)
    input [6:0] duty,
    output reg pwm
);
    
    parameter sys_clk_freq = 100_000_000;           // 시스템 클럭 주파수
    parameter pwm_freq = 50;                                // pwm 주파수 50hz (servo모터 data sheet)
    parameter duty_step = 128;                              //128분주기
    parameter temp = sys_clk_freq / pwm_freq / duty_step;       
    parameter temp_half = temp /2 ;                                            
    
    integer cnt;                            // 카운트
    reg pwm_freqX128;
    
    // 이 과정은 pwm_freqX128 신호를 생성하여, PWM 주파수를 128배 빠르게 만듬
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77까지  
                    else cnt = cnt + 1;                         // 카운트 증가
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 이하 0
                    else pwm_freqX128 = 1;                          // 39 이상 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    
    reg [6:0] cnt_duty;  // 7비트 카운터 레지스터 (0부터 99까지 셈)
   
   
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
            
             // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
            else if(pwm_freqX128_nedge)begin      
            cnt_duty = cnt_duty + 1;                           
                    if (cnt_duty < duty)pwm = 1;        // 만약 duty이하일때 pwm값  1 아니면 0
                    else pwm = 0;
            end
     end
    

    
endmodule




module drone_bldc_motor_pwm
  #(     parameter regbitdepth = 16,     
          localparam  sys_clk_freq = 100_000_000,           // 시스템 클럭 주파수  
          localparam pwm_freq = 50,                                // pwm 주파수 50hz (servo모터 data sheet)
          localparam duty_step = 20*(2**regbitdepth) ,                              //128분주기
          localparam temp = sys_clk_freq / pwm_freq / duty_step,       
          localparam temp_half = temp /2 )                                            
 (
    input clk,           // 입력 클럭 신호
    input reset_p,       // 비동기 리셋 신호 (active high)
    input [regbitdepth-1:0] motor_ouput,      //  이 duty는 1~2ms 사이 입니다!!
    output reg pwm
);
    wire [regbitdepth+4:0] duty;    
    assign duty = { {(regbitdepth*18){1'b0}}, motor_ouput, {regbitdepth{1'b0}} };
    integer cnt;                            // 카운트
    reg pwm_freqX128;
    
    // 이 과정은 pwm_freqX128 신호를 생성하여, PWM 주파수를 128배 빠르게 만듬
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77까지  
                    else cnt = cnt + 1;                         // 카운트 증가
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 이하 0
                    else pwm_freqX128 = 1;                          // 39 이상 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    

   
   integer cnt_duty;
   
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
             // pwm_freqX128 신호의 하강에지를 감지해서 cnt_duty 가 1씩 증가
            else if(pwm_freqX128_nedge)begin      
                    if(cnt_duty >= (duty_step - 1))cnt_duty = 0;
                    else cnt_duty = cnt_duty + 1;                           
                    
                    if (cnt_duty < duty)pwm = 1;        // 만약 duty이하일때 pwm값  1 아니면 0
                    else pwm = 0;
            end
     end
    
endmodule


module I2C_master(
    input clk, reset_p,      // 클럭 신호, 리셋 신호 (활성화는 High)
    input [6:0] addr,        // I2C 장치 주소 (7비트)
    input [7:0] data,        // 전송할 데이터 (8비트)
    input rd_wr, comm_go,    // 읽기/쓰기 제어, 통신 시작 신호
    output reg sda, scl,      // I2C 데이터, 클럭 신호
    output reg [6:0] led
);

    // I2C 상태를 나타내는 파라미터 정의
    parameter IDLE                       = 7'b000_0001;  // 대기 상태
    parameter COMM_START      = 7'b000_0010;  // 통신 시작 상태
    parameter SEND_ADDR          = 7'b000_0100;  // 주소 전송 상태
    parameter RD_ACK                 = 7'b000_1000;  // ACK 신호 수신 상태
    parameter SEND_DATA          = 7'b001_0000;  // 데이터 전송 상태
    parameter SCL_STOP             = 7'b010_0000;  // SCL 신호 정지 상태
    parameter COMM_STOP        = 7'b100_0000;  // 통신 정지 상태

    // 주소와 읽기/쓰기 비트를 결합하여 8비트로 생성
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};     // 상위 7비트는 주소, 하위 1비트는 읽기/쓰기

    // 100us 클럭을 생성하는 모듈 인스턴스
    wire clk_usec;
    
    clock_div_100 usec_clk(
        .clk(clk),                          // 입력 클럭
        .reset_p(reset_p),          // 리셋 신호
        .clk_div_100(clk_usec)  // 100us 단위 클럭 출력
    );

    reg [2:0] count_usec5;  // 100us 카운트를 위한 3비트 레지스터
    reg scl_e;                        // SCL 신호의 활성화를 제어하는 플래그

    // 클럭 및 리셋 신호에 대한 SCL 제어 로직
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            count_usec5 = 0;     // 리셋 시 카운터 초기화
            scl = 0;                     // SCL 신호 초기화
        end 
        else if (scl_e) begin
            if (clk_usec) begin
                if (count_usec5 >= 4) begin  // 4 이상일 때 SCL 토글
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;  // 카운터 증가
            end
        end
        else if (!scl_e) begin 
            count_usec5 = 0;    // SCL 비활성화 시 카운터 초기화
            scl = 1;                     // SCL 신호 설정
        end
    end


    // comm_go 신호의 상승 에지 검출기
    wire comm_go_pedge;
    
    edge_detector_n ed_go(
        .clk(clk), .reset_p(reset_p), .cp(comm_go), 
        .p_edge(comm_go_pedge)
    );


    // SCL 신호의 상승/하강 에지 검출기
    wire scl_pedge, scl_nedge;
    
    edge_detector_n ed_scl(
        .clk(clk), .reset_p(reset_p), .cp(scl), 
        .p_edge(scl_pedge), .n_edge(scl_nedge)
    );
    
    reg [6:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
            if(reset_p)state = IDLE;
            else state = next_state;
      end
    
    
      reg [2:0] cnt_bit;
      reg stop_flag;
      
      always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    next_state = IDLE;
                    scl_e = 0;
                    sda = 1;
                    cnt_bit = 7;
                    stop_flag = 0;
                     led = 0;
            end
            else begin
                    case(state)
                         IDLE:begin
                                led[0] = 1;
                                scl_e = 0;
                                sda = 1;
                                if(comm_go_pedge)next_state = COMM_START;
                         end
                         
                         COMM_START:begin
                                led[1] = 1;
                                sda = 0;
                                scl_e = 1;
                                next_state = SEND_ADDR;
                         end
                          
                         SEND_ADDR:begin
                                 led[2] = 1;
                                if(scl_nedge)sda = addr_rw[cnt_bit];
                                if(scl_pedge)begin
                                      if(cnt_bit == 0)begin      
                                            cnt_bit = 7;
                                            next_state = RD_ACK;
                                      end
                                      else cnt_bit = cnt_bit - 1; 
                                end  
                         end
                         
                         RD_ACK:begin
                               led[3] = 1;
                               if(scl_nedge) sda = 'bz;
                               else if(scl_pedge) begin
                                     if(stop_flag)begin
                                            stop_flag = 0;
                                            next_state = SCL_STOP;
                                     end
                                     else begin
                                            stop_flag = 1;
                                            next_state = SEND_DATA;
                                     end
                              end
                        end
                         
                        SEND_DATA:begin
                           led[4] = 1;
                           if(scl_nedge)sda = data[cnt_bit];
                                if(scl_pedge)begin
                                      if(cnt_bit == 0)begin      
                                            cnt_bit = 7;
                                            next_state = RD_ACK;
                                      end
                                      else cnt_bit = cnt_bit - 1; 
                                end  
                         end
                         
                         SCL_STOP:begin
                                led[5] = 1;
                                if(scl_nedge)sda = 0;
                                else if(scl_pedge) next_state = COMM_STOP;
                                
                         end
                         
                         COMM_STOP:begin
                                led[6] = 1;
                                if(count_usec5 >= 3)begin
                                        scl_e = 0;
                                        sda = 1;
                                        next_state = IDLE;
                                end
                          end
                 endcase
           end
     end           
endmodule






module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] send_buffer,
    input send, rs,
    output scl, sda,
    output reg busy  // busy 플래그
);

    // 상태 매개변수 정의
    parameter IDLE                                             = 6'b00_0001;
    parameter SEND_HIGH_NIBBLE_DISABLE    = 6'b00_0010;
    parameter SEND_HIGH_NIBBLE_ENABLE     = 6'b00_0100;
    parameter SEND_LOW_NIBBLE_DISABLE     = 6'b00_1000;
    parameter SEND_LOW_NIBBLE_ENABLE      = 6'b01_0000;
    parameter SEND_DISABLE                            = 6'b10_0000;

    reg [7:0] data;      // 전송할 데이터
    reg comm_go;         // I2C 마스터로 전송을 시작하는 신호

    wire send_pedge;     // 전송 신호의 양쪽 에지 검출

    // 전송 신호의 에지 검출기
    edge_detector_n ed_go(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(send), 
        .p_edge(send_pedge)
    );
   
    wire clk_usec;   // 100us 단위의 클럭 신호

    // 100us 단위 클럭 생성기
    clock_div_100 usec_clk(
        .clk(clk),           // 입력 클럭
        .reset_p(reset_p),   // 리셋 신호
        .clk_div_100(clk_usec) // 100us 단위 클럭 출력
    );

    reg [21:0] count_usec;  // 100us 단위로 카운트하는 레지스터
    reg count_usec_e;       // 카운터 활성화 신호

    // 카운터 로직
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            count_usec = 0;  // 리셋 시 카운터 초기화
        end else begin
            if(clk_usec && count_usec_e) 
                count_usec = count_usec + 1;  // 카운터 증가
            else if(!count_usec_e) 
                count_usec = 0;  // 카운터 초기화
        end
    end

    reg [5:0] state, next_state;  // 현재 상태와 다음 상태를 나타내는 레지스터

    // 상태 전환 로직
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) 
            state = IDLE;  // 리셋 시 IDLE 상태로 초기화
        else 
            state = next_state;  // 상태 전환
    end

    // FSM 로직
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            next_state = IDLE;  // 리셋 시 다음 상태를 IDLE로 설정
            busy = 0;  // 바쁜 상태 해제
        end else begin
            case(state)
                IDLE: begin
                    if(send_pedge) begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;  // 전송 시작
                        busy = 1;  // 바쁜 상태 설정
                    end        
                end
                SEND_HIGH_NIBBLE_DISABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[7:4], 3'b100, rs};  // 상위 니블 전송 준비  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C 전송 시작
                        count_usec_e = 1;  // 카운터 활성화
                    end else begin
                        next_state = SEND_HIGH_NIBBLE_ENABLE;  // 다음 상태로 전환
                        count_usec_e = 0;  // 카운터 비활성화
                        comm_go = 0;  // 전송 종료
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[7:4], 3'b110, rs};  // 상위 니블 전송 중  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C 전송 시작
                        count_usec_e = 1;  // 카운터 활성화
                    end else begin
                        next_state = SEND_LOW_NIBBLE_DISABLE;  // 다음 상태로 전환
                        count_usec_e = 0;  // 카운터 비활성화
                        comm_go = 0;  // 전송 종료
                    end
                end
                SEND_LOW_NIBBLE_DISABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[3:0], 3'b100, rs};  // 하위 니블 전송 준비  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C 전송 시작
                        count_usec_e = 1;  // 카운터 활성화
                    end else begin
                        next_state = SEND_LOW_NIBBLE_ENABLE;  // 다음 상태로 전환
                        count_usec_e = 0;  // 카운터 비활성화
                        comm_go = 0;  // 전송 종료
                    end
                end
                SEND_LOW_NIBBLE_ENABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[3:0], 3'b110, rs};  // 하위 니블 전송 중  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C 전송 시작
                        count_usec_e = 1;  // 카운터 활성화
                    end else begin
                        next_state = SEND_DISABLE;  // 다음 상태로 전환
                        count_usec_e = 0;  // 카운터 비활성화
                        comm_go = 0;  // 전송 종료
                    end                                
                end
                SEND_DISABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[3:0], 3'b100, rs};  // 전송 완료 후 상태  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C 전송 시작
                        count_usec_e = 1;  // 카운터 활성화
                    end else begin
                        next_state = IDLE;  // 전송 종료 후 IDLE 상태로 복귀
                        count_usec_e = 0;  // 카운터 비활성화
                        comm_go = 0;  // 전송 종료
                        busy = 0;
                    end                                
                end
            endcase
        end
    end

    // I2C 마스터 모듈 인스턴스화
    I2C_master master( 
        .clk(clk),  
        .reset_p(reset_p),
        .addr(addr), 
        .data(data), 
        .rd_wr(0), 
        .comm_go(comm_go), 
        .sda(sda), 
        .scl(scl), 
        .led(led)
    );
    
endmodule



module bcd_fnd_cntr(
        input clk, reset_p,
        input [11:0] hex_value,
        input hex_bcd,
        output [7:0] seg_7,
        output [3:0] com);

    wire [15:0] bcd;
    bin_to_dec btd(.bin(hex_value), .bcd(bcd));

    wire [15:0]value;
    assign value = hex_bcd ? {4'b0, hex_value} : bcd;
    fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);        
        
        
endmodule
