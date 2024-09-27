`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/26 15:08:53
// Design Name: 
// Module Name: clock_library
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

// 10 분주기 
module clock_div_10(
    input clk,                       // 입력 클럭 신호
    input reset_p,               // 비동기 리셋 신호 (active high)
    input clk_source,         // 분주할 원본 클럭 신호
    
    output cp_div_10_nedge  // 분주된 클럭 신호의 네거티브 엣지 출력
);
    
    wire nedge_source, cp_div_10;

    // 원본 클럭 신호(clk_source)의 네거티브 엣지를 감지
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_source), 
        .n_edge(nedge_source)
    ); 
                    
    reg [3:0] cnt_clk_source;  // 4비트 카운터 레지스터 (0부터 9까지 셈)

    // 클럭의 네거티브 엣지 또는 리셋 신호에서 동작하는 always 블록
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_clk_source <= 0; // 리셋 신호가 활성화되면 카운터를 0으로 초기화
        else if(nedge_source) begin
            if (cnt_clk_source >= 9) 
                cnt_clk_source <= 0; // 카운터 값이 9 이상이면 0으로 리셋
            else 
                cnt_clk_source <= cnt_clk_source + 1; // 그렇지 않으면 카운터를 1씩 증가
        end
    end

    // cnt_clk_source 값을 기반으로 cp_div_10 신호 생성
    // cnt_clk_source가 9일 때 cp_div_10은 1, 그렇지 않으면 0
    assign cp_div_10 = (cnt_clk_source < 9) ? 0 : 1;

    // cp_div_10 신호의 네거티브 엣지를 감지하여 cp_div_10_nedge 신호 생성
    // 이는 1에서 0으로의 전환을 감지하여 오류를 최소화함
    edge_detector_n ed10(
        .clk(clk), .reset_p(reset_p), .cp(cp_div_10), 
        .n_edge(cp_div_10_nedge)
    ); 
 
endmodule



//100분주기 
module clock_div_100(
    input clk,           // 입력 클럭 신호
    input reset_p,       // 비동기 리셋 신호 (active high)
    output clk_div_100,  // 다른 분주기와 다르게 wire 선언을 따로 안해서 선언
    output cp_div_100    // 100분주된 클럭 신호
);
    
    reg [6:0] cnt_sysclk;  // 7비트 카운터 레지스터 (0부터 99까지 셈)
    
    // 클럭의 네거티브 엣지 또는 리셋 신호에서 동작하는 always 블록
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_sysclk = 0; // 리셋 신호가 활성화되면 카운터를 0으로 초기화
        else begin
            if (cnt_sysclk >= 99) 
                cnt_sysclk = 0; // 카운터 값이 99 이상이면 0으로 리셋 (== 보다 >= 가 더 안전함)
            else 
                cnt_sysclk = cnt_sysclk + 1; // 그렇지 않으면 카운터를 1씩 증가
        end
    end
   
    // cnt_sysclk 값을 기반으로 cp_div_100 신호 생성
    // cnt_sysclk가 0에서 99 사이일 때 cp_div_100은 0, 99에서 0(초기화)  사이일 때 cp_div_100은 1
    assign cp_div_100 = (cnt_sysclk < 99) ? 0 : 1;
     
    // cp_div_100 신호의 네거티브 엣지를 감지하여 clk_div_100 신호 생성
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(cp_div_100), 
        .n_edge(clk_div_100)
    ); 
    
endmodule



// 1000분주 바꾼후 시간차 캡쳐 
module clock_div_1000(
    input clk,          // 입력 클럭 신호
    input reset_p,      // 비동기 리셋 신호 (active high)
    input clk_source,   // 분주할 원본 클럭 신호
    
    output cp_div_1000_nedge      // 분주된 클럭 신호 출력
);
    
    wire nedge_source, cp_div_1000;
    
    // 원본 클럭 신호의 네거티브 엣지를 감지하여 nedge_source 신호 생성
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_source), 
        .n_edge(nedge_source)
    ); 
    
    reg [9:0] cnt_clk_source;  // 10비트 카운터 레지스터 (0부터 999까지 셈)

    // 클럭의 네거티브 엣지 또는 리셋 신호에서 동작하는 always 블록
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_clk_source = 0; // 리셋 신호가 활성화되면 카운터를 0으로 초기화
        else if (nedge_source) begin
            if (cnt_clk_source >= 999) 
                cnt_clk_source = 0; // 카운터 값이 999 이상이면 0으로 리셋
            else 
                cnt_clk_source = cnt_clk_source + 1; // 그렇지 않으면 카운터를 1씩 증가
        end
    end

    // cnt_clk_source 값을 기반으로 cp_div_1000 신호 생성
    assign cp_div_1000 = (cnt_clk_source < 999) ? 0 : 1;
    // cnt_clk_source 0에서 999 사이일 때 cp_div_1000은 0, 999에서 0(초기화) 사이일 때 cp_div_1000은 1
    
    // cp_div_1000 신호의 네거티브 엣지를 감지하여 cp_div_1000_nedge 신호 생성
    edge_detector_n ed1000(
        .clk(clk), .reset_p(reset_p), .cp(cp_div_1000), 
        .n_edge(cp_div_1000_nedge)
    ); 
    
endmodule


// 타이머 전용 60분주기 (sec,min)
module clock_div_60(
    input clk,          // 입력 클럭 신호
    input reset_p,      // 비동기 리셋 신호 (active high)
    input clk_source, 
    
    output cp_div_60_nedge      // 분주된 클럭 신호 출력
);
    
    wire nedge_source, cp_div_60;
     edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(clk_source), 
                    .n_edge(nedge_source)); 
                    
    integer cnt_clk_source;  //  integer - 32bit (but 최적화  되서 6비트만(0~64) 적용) 

    // 클럭 상승 에지 또는 리셋 신호에서 동작하는 always 블록
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_clk_source = 0; // 리셋 신호가 활성화되면 카운터를 0으로 초기화
        else if(nedge_source) begin
            if (cnt_clk_source >= 59) 
                cnt_clk_source = 0; // 카운터 값이 999 이상이면 0으로 리셋
            else 
                cnt_clk_source = cnt_clk_source + 1; // 그렇지 않으면 카운터를 1씩 증가
        end
    end

    // cnt_clk_source 값을 기반으로 cp_usec 신호 생성
    assign cp_div_60 = (cnt_clk_source < 59) ? 0 : 1;
    // cnt_clk_source 0에서 59 사이일 때 cp_usec는 59에서 00 사이일 때 cp_usec는 1
    
     edge_detector_n ed60(
                    .clk(clk), .reset_p(reset_p), .cp(cp_div_60), 
                    .n_edge(cp_div_60_nedge)); 

endmodule




// 60진 카운터 시계 만들기  (segment 표시용 )
module counter_bcd_60(
        input clk, reset_p,
        input clk_time,
        output reg [3:0] bcd1, bcd10);  // 4비트 씩  bcd1,bcd10 

         wire nedge_source;
         
         edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(clk_time), 
                    .n_edge(nedge_source)); 

         always @(posedge clk or posedge reset_p)begin          // 상승엣지  혹은 리셋신호일때 
                if(reset_p)begin                // bcd1,bcd10 - 0으로 초기화 
                        bcd1 = 0;
                        bcd10 = 0; 
                end
                else if (nedge_source) begin  
                       if(bcd1 >= 9) begin                  // bcd1 즉, 1의자리가 9 이상 일때 0으로 초기화 
                            bcd1 = 0;
                            if(bcd10 >= 5)bcd10 = 0;    // bcd10 즉, 10자리가 5 이상일때 0으로 초기화  
                            else bcd10 = bcd10 + 1;     // 10의자리 1추가 
                end 
                else  bcd1 <= bcd1 + 1;                   // 1의자리 1추가
          end
    end

endmodule


// 100진 카운터 시계 만들기  ( sec : msec 타이머 만들때 msec 용)
module counter_bcd_100(
        input clk, reset_p,
        input clk_time,
        output reg [6:0] bcd1, bcd10);

         wire nedge_source;
         
         edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(clk_time), 
                    .n_edge(nedge_source)); 

         always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin            //  리셋 신호 시 0으로 초기화 
                        bcd1 = 0;
                        bcd10 = 0; 
                end
                else if (nedge_source) begin
                       if(bcd1 >= 9) begin          // bcd 1의자리 9이상일시 0으로 초기화
                            bcd1 = 0;
                            if(bcd10 >= 9)bcd10 = 0;        // bcd 10의자리 9이상일시 0으로 초기화
                            else bcd10 = bcd10 + 1;         // bcd 10의자리 1씩 카운트
                end
                else bcd1 <= bcd1 + 1;                       // bcd 1의자리 1씩 카운트
          end
    end

endmodule



module loadable_counter_bcd_60(
    input clk, reset_p,           // 클럭 및 비동기 리셋 신호
    input clk_time,               // 카운터 클럭 신호
    input load_enable,            // 로드 이퀀블 신호
    input [3:0] load_bcd1, load_bcd10,  // 로드할 BCD 숫자 (1의 자리 및 10의 자리)
    output reg [3:0] bcd1, bcd10       // BCD 출력 (1의 자리 및 10의 자리)
);

    wire nedge_source;
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_time), 
        .n_edge(nedge_source)
    ); 

    // 비동기 리셋 신호 또는 클럭의 상승 에지에서 동작하는 always 블록
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            // 리셋 신호가 활성화되면 BCD 카운터를 0으로 초기화
            bcd1 <= 0;
            bcd10 <= 0; 
        end
        else begin
            if (load_enable) begin
                // 로드 이퀀블 신호가 활성화되면 입력된 BCD 값을 로드
                bcd1 <= load_bcd1;
                bcd10 <= load_bcd10;
            end
            else if (nedge_source) begin
                // 클럭의 네거티브 엣지에서 카운터를 증가시킴
                if (bcd1 >= 9) begin
                    bcd1 <= 0;
                    if (bcd10 >= 5)
                        bcd10 <= 0;
                    else
                        bcd10 <= bcd10 + 1;
                end
                else
                    bcd1 <= bcd1 + 1;
            end
        end
    end

endmodule






module loadable_down_counter_bcd_60(
    input clk, reset_p,           // 클럭 및 비동기 리셋 신호
    input clk_time,               // 카운터 클럭 신호
    input load_enable,            // 로드 이퀀블 신호
    input [3:0] load_bcd1, load_bcd10,  // 로드할 BCD 숫자 (1의 자리 및 10의 자리)
    output reg [3:0] bcd1, bcd10,       // BCD 출력 (1의 자리 및 10의 자리)
    output reg dec_clk
);



        // 비동기 리셋 신호 또는 클럭의 상승 에지에서 동작하는 always 블록
       always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            // 리셋 신호가 활성화되면 BCD 카운터를 0으로 초기화
            bcd1 = 0;        // 1의 자리를 0으로 초기화
            bcd10 = 0;       // 10의 자리를 0으로 초기화
            dec_clk = 0;     // 감소 클럭 신호를 0으로 초기화
        end
        else begin
            if (load_enable) begin
                // 로드 이네이블 신호가 활성화되면 입력된 BCD 값을 로드
                bcd1 = load_bcd1;     // 입력된 1의 자리 값을 로드
                bcd10 = load_bcd10;   // 입력된 10의 자리 값을 로드
            end
            else if (clk_time) begin
                // clk_time 신호가 활성화될 때 (1초마다)
                
                if (bcd1 == 0) begin
                    // 1의 자리가 0이면 9로 변경
                    bcd1 = 9;
                    
                    if (bcd10 == 0) begin
                        // 10의 자리도 0이면 59초에서 58초로 변경하는 로직
                        // 분의 자리 감소 신호를 1로 설정
                        dec_clk = 1;
                        // 10의 자리를 5로 설정 (ex: 01:00 -> 00:59)
                        bcd10 = 5;
                    end
                    else begin
                        // 10의 자리가 0이 아니면 1 감소
                        bcd10 = bcd10 - 1;
                    end
                end
                else begin
                    // 1의 자리가 0이 아니면 1 감소
                    bcd1 = bcd1 - 1;
                end
            end
            else begin
                // clk_time 신호가 비활성화되면 dec_clk를 0으로 설정
                dec_clk = 0;
            end
        end
    end
    
endmodule
    



// 58 분주기 
module sr_04_div_58(
    input clk, reset_p,
    input clk_usec,  cnt_e,
    output reg [11:0] cm);
    
    integer cnt;
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            cnt = 0;
            cm = 0;
        end
        else if(cnt_e)begin
            if(clk_usec) begin
                if(cnt >= 58)begin cnt = 0; cm = cm + 1; end
                else cnt = cnt + 1;
            end
        end
        else begin
            cnt = 0;
            cm = 0;
        end
    end
endmodule





