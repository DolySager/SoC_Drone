`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/20 10:37:01
// Design Name: 
// Module Name: exam02_sequantial_logic
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

// D_플립플롭_n (하강엣지)
module D_flip_flop_n(
    input d,               // 입력: 데이터 입력
    input clk,             // 입력: 클럭
    input reset_p,         // 입력: 비동기 리셋
    inout enable,          // 입출력: 활성화 신호 (inout으로 선언)
    output reg q           // 출력: D 플립플롭 출력
);
    
    always @(negedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            q = 0;  // 플립플롭을 0으로 초기화
        end
        // enable 신호가 활성화되고 클럭의  하강에지에서 데이터 입력을 q에 저장
        else if (enable) begin
            q = d;  // 데이터 d를 q에 저장
        end
    end
    
endmodule


// D_플립플롭_p (상승엣지)
module D_flip_flop_p(
    input d,               // 입력: 데이터 입력
    input clk,             // 입력: 클럭
    input reset_p,         // 입력: 비동기 리셋
    inout enable,          // 입출력: 활성화 신호 (inout으로 선언)
    output reg q           // 출력: D 플립플롭 출력
);
    
    always @(posedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            q = 0;  // 플립플롭을 0으로 초기화
        end
        // enable 신호가 활성화되고 클럭 상승에지에서 데이터 입력을 q에 저장
        else if (enable) begin
            q = d;  // 데이터 d를 q에 저장
        end
    end
    
endmodule



// T_플립플롭_n (하강엣지)
module T_flip_flop_n(
    input clk, reset_p,     // 입력: 클럭, 리셋
    input t,                // 입력: T 트리거
    output reg q            // 출력: T 플립플롭 출력
);
    
    always @(negedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            q = 0;  // 플립플롭을 0으로 초기화
        end
        else begin
            // T 트리거 신호가 활성화되면 플립플롭 상태 반전
            if (t) begin
                q = ~q;  // q를 반전시킴
            end
            // T 트리거 신호가 비활성화되면 플립플롭 상태 유지
            else begin
                q = q;  // q를 유지함
            end
        end
    end

endmodule


// T_플립플롭_p(상승엣지)
module T_flip_flop_p(
    input clk, reset_p,     // 입력: 클럭, 리셋
    input t,                // 입력: T 트리거
    output reg q            // 출력: T 플립플롭 출력
);
    
    always @(posedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            q = 0;  // 플립플롭을 0으로 초기화
        end
        else begin
            // T 트리거 신호가 활성화되면 플립플롭 상태 반전
            if (t) begin
                q = ~q;  // q를 반전시킴
            end
            // T 트리거 신호가 비활성화되면 플립플롭 상태 유지
            else begin
                q = q;  // q를 유지함
            end
        end
    end

endmodule


//module demux_1_4_b(
//    input d,
//    input [1:0] s,
//    output reg [3:0] f);

//    always @(s)begin
//        f = 0;
//        f[s] = d;
//    end
    
    
//endmodule



// 비동기식 업 카운터
module up_counter_asyc(
    input clk, reset_p,      // 입력: 클럭, 비동기 리셋
    output [3:0] count      // 출력: 4비트 업 카운터
);
    
    // T 플립플롭 모듈 인스턴스화
    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule


// 비동기식 다운 카운터
module down_counter_asyc(
    input clk, reset_p,      // 입력: 클럭, 비동기 리셋
    output [3:0] count      // 출력: 4비트 다운 카운터
);
    
    // T 플립플롭 모듈 인스턴스화
    T_flip_flop_p T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule

/*
module up_counter_p(
    input clk, reset_p, enable,
    output reg [3:0] count);
    
    wire [3:0] inc;
    assign inc = count + 1;
     
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)count = 0;
        else if(enable) count = inc;    
    end
    

endmodule
*/


// 업카운터_상승엣지
module up_counter_p(
    input clk, reset_p, enable,       // 입력: 클럭, 리셋, 카운트 활성화 신호
    output reg [3:0] count           // 출력: 4비트 업 카운터
);

    always @(posedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            count = 0;  // 카운터를 0으로 초기화
        end
        // enable 신호가 활성화되면 카운터 증가
        else if (enable) begin 
            count = count + 1;    // 카운터를 1 증가
        end
    end

endmodule


// 다운카운터_상승엣지
module down_counter_p(
    input clk, reset_p, enable,       // 입력: 클럭, 리셋, 카운트 활성화 신호
    output reg [3:0] count           // 출력: 4비트 다운 카운터
);

    always @(posedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            count = 0;  // 카운터를 0으로 초기화
        end
        // enable 신호가 활성화되면 카운터 감소
        else if (enable) begin 
            count = count - 1;    // 카운터를 1 감소
        end
    end

endmodule


// bcd 업 카운터_상승엣지
module bcd_up_counter_p(
    input clk, reset_p, enable,      // 입력: 클럭, 리셋, 카운트 활성화 신호
    output reg [3:0] count          // 출력: 4비트 카운터
);
     
    always @(posedge clk or posedge reset_p) begin
        // 리셋 신호가 활성화되면 항상 실행
        if (reset_p) begin
            count = 0;  // 카운터를 0으로 초기화
        end
        // enable 신호가 활성화되면 카운터 증가
        else if (enable) begin 
            count = count + 1;    // 카운터를 1 증가
            
            // BCD 제약 조건: count가 9를 초과하지 않도록 제한
            if (count >= 10) begin
                count = 0;  // count가 10 이상이면 0으로 반복
            end
        end
    end

endmodule


// bcd 다운 카운터_상승엣지
module bcd_down_counter_p(
    input clk,         // 클럭 입력
    input reset_p,     // 리셋 입력 (비동기적으로 활성화되는 active-high 신호)
    input enable,      // 카운팅을 활성화하는 입력
    output reg [3:0] count  // 4비트 카운터 출력
);
     
    always @(posedge clk or posedge reset_p) begin
        // 클럭 신호나 리셋 신호가 긍정적인 에지일 때 항상 실행
        if (reset_p) begin
            count = 0;  // 리셋 신호가 활성화되면 count를 0으로 초기화
        end
        else if (enable) begin
            // enable 신호가 활성화된 경우 카운터 감소
            count = count - 1;
            
            // BCD 제약 조건: count가 9를 초과하지 않도록 제한
            if (count >= 10) begin
                count = 9;  // count가 10 이상이면 9로 고정
            end
        end
    end

endmodule


// 업 다운 카운터
module up_down_counter(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    input enable,     // 카운터 활성화 신호 입력
    input up_down,    // 카운터 방향 신호 입력 (1이면 업 카운트, 0이면 다운 카운트)
    output reg [3:0] count // 4비트 카운터 출력
);

    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            count = 0; // 리셋 신호가 활성화되면 count를 0으로 설정
        else if (enable) begin // 카운터가 활성화된 경우
            if (up_down) begin // 업 카운트 모드
                count = count + 1; // count를 1 증가
            end else begin // 다운 카운트 모드
                count = count - 1; // count를 1 감소
            end
        end
    end

endmodule


// 업 다운 bcd 카운터
module up_down_bcd_counter(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    input enable,     // 카운터 활성화 신호 입력
    input up_down,    // 카운터 방향 신호 입력 (1이면 업 카운트, 0이면 다운 카운트)
    output reg [3:0] count // 4비트 BCD 카운터 출력
);

    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            count = 0; // 리셋 신호가 활성화되면 count를 0으로 설정
        else if (enable) begin // 카운터가 활성화된 경우
            if (up_down) begin // 업 카운트 모드
                if (count >= 9)
                    count = 0; // count가 9 이상이면 0으로 설정 (BCD 순환)
                else
                    count = count + 1; // 그렇지 않으면 count를 1 증가
            end else begin // 다운 카운트 모드
                if (count == 0)
                    count = 9; // count가 0이면 9로 설정 (BCD 순환)
                else
                    count = count - 1; // 그렇지 않으면 count를 1 감소
            end
        end
    end

endmodule

// 링 카운터 
module ring_counter(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    output reg [3:0] q // 4비트 출력, 링 카운터의 상태
);

    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) 
            q = 4'b0001; // 리셋 신호가 활성화되면 q를 초기값 (0001)으로 설정
        else begin
            if (q == 4'b1000)
                q = 4'b0001; // q가 1000이면 초기값으로 돌아감
            else 
                q = {q[2:0], 1'b0}; // q를 왼쪽으로 시프트하고 가장 오른쪽 비트에 0을 추가
        end
    end

endmodule
    
    
    
// 링 카운터 
module ring_counter_watch(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    output reg [2:0] q // 3비트 출력, 링 카운터의 상태
);

    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) 
            q = 3'b001; // 리셋 신호가 활성화되면 q를 초기값 (0001)으로 설정
        else begin
            if (q == 3'b100)
                q = 3'b001; // q가 1000이면 초기값으로 돌아감
            else 
                q = {q[2:0], 1'b0}; // q를 왼쪽으로 시프트하고 가장 오른쪽 비트에 0을 추가
        end
    end

endmodule    
    
   
//    always @(posedge clk or posedge reset_p)begin
//         if(reset_p) q = 4'b0001;
//         else begin
         
//         case(q)
         
//          4'b0001 : q = 4'b0010;
//          4'b0010 : q = 4'b0100;
//          4'b0100 : q = 4'b1000;
//          4'b1000 : q = 4'b0001; 
//          default : q = 4'b0001;      
          
//          endcase 
     


//   always @(posedge clk or posedge reset_p)begin
//        if(reset_p)q = 4'b0001;
//        else begin
//            if(q == 4'b0001)q = 4'b0010;
//            else if(q == 4'b0010)q = 4'b0100;
//            else if(q == 4'b0100)q = 4'b1000;
//            else q = 4'b0001;
//         end





// 엣지 검출기 _ n(하강엣지)
//  cur 과 old 가 한클럭 속도 차이가 나는데 그 상승엣지와 하강엣지 사이인 10ns만을 검출하는방식
module edge_detector_n(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    input cp,         // 에지 검출을 위한 클럭 신호
    output p_edge,    // 상승 에지 검출 출력
    output n_edge     // 하강 에지 검출 출력
);

    reg ff_cur, ff_old; // 현재와 이전 상태를 저장하는 플립플롭 레지스터

    // 항상 블록: 클럭의 하강 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            ff_cur <= 0; // 리셋 신호가 활성화되면 ff_cur을 0으로 설정
            ff_old <= 0; // 리셋 신호가 활성화되면 ff_old를 0으로 설정
        end else begin
            ff_old <= ff_cur; // 현재 상태를 이전 상태로 업데이트
            ff_cur <= cp;     // 입력 cp를 현재 상태로 업데이트
        end
    end
    
    // 양의 에지 검출: ff_cur가 1이고 ff_old가 0일 때
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    
    // 음의 에지 검출: ff_cur가 0이고 ff_old가 1일 때
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;

endmodule


// 링카운터_fnd 
module ring_counter_fnd(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    output reg [3:0] q // 4비트 출력, 링 카운터의 상태
);

    reg [16:0] clk_div; // 클럭 분주기 레지스터, 클럭을 분주하여 카운터 속도를 조절
    // 항상 블록: 클럭의 상승 에지에서 실행, 클럭 분주기 증가
    always @(posedge clk) clk_div = clk_div + 1;
    
    wire clk_div_16_p; // 분주된 클럭의 상승 에지 검출 신호
    
    // 에지 검출기 모듈 인스턴스화
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), // 17번째 비트의 클럭 분주 신호를 입력으로 사용
        .p_edge(clk_div_16_p) // 상승 에지 검출 출력
    );
    
    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin 
        if (reset_p) 
            q = 4'b1110; // 리셋 신호가 활성화되면 q를 초기값으로 설정
        else if (clk_div_16_p) begin // 분주된 클럭의 상승 에지에서 실행
            if (q == 4'b0111)
                q = 4'b1110; // 카운터가 순환하여 초기값으로 돌아감
            else 
                q = {q[2:0], 1'b1}; // q를 왼쪽으로 시프트하고 가장 오른쪽 비트에 1을 추가
        end
    end

endmodule


// 링카운터 16bit 
module ring_counter_16bit(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    output reg [15:0] q // 16비트 출력, 링 카운터의 상태
);

    reg [21:0] clk_div; // 클럭 분주기 레지스터, 클럭을 분주하여 카운터 속도를 조절
    // 항상 블록: 클럭의 상승 에지에서 실행, 클럭 분주기 증가
    always @(posedge clk) clk_div = clk_div + 1;
    
    wire clk_div_20_p; // 분주된 클럭의 상승 에지 검출 신호
    
    // 에지 검출기 모듈 인스턴스화
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[21]), // 22번째 비트의 클럭 분주 신호를 입력으로 사용
        .p_edge(clk_div_20_p) // 상승 에지 검출 출력
    );
    
    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin 
        if (reset_p) 
            q = 16'b1111_1111_1111_1110; // 리셋 신호가 활성화되면 q를 초기값으로 설정
        else if (clk_div_20_p) begin // 분주된 클럭의 상승 에지에서 실행
            if (q == 16'b0111_1111_1111_1111)
                q = 16'b1111_1111_1111_1110; // 카운터가 순환하여 초기값으로 돌아감
            else 
                q = {q[14:0], 1'b1}; // q를 왼쪽으로 시프트하고 가장 오른쪽 비트에 1을 추가
        end
    end

endmodule



// 링카운터 led
module ring_counter_le(
    input clk,        // 클럭 신호 입력
    input reset_p,    // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    output reg [15:0] q // 16비트 출력, LED를 제어하는 카운터
);

    reg [20:0] clk_div; // 클럭 분주기 레지스터, 클럭을 분주하여 카운터 속도를 조절
    
    // 항상 블록: 클럭의 상승 에지에서 실행, 클럭 분주기 증가
    always @(posedge clk) clk_div = clk_div + 1;
    
    wire clk_div_20_p; // 분주된 클럭의 상승 에지 검출 신호
    
    // 에지 검출기 모듈 인스턴스화
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[20]), // 21번째 비트의 클럭 분주 신호를 입력으로 사용
        .p_edge(clk_div_20_p) // 상승 에지 검출 출력
    );
    
    // 항상 블록: 클럭의 상승 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(posedge clk or posedge reset_p) begin 
        if (reset_p) 
            q = 16'b0000_0000_0000_0001; // 리셋 신호가 활성화되면 q를 초기값으로 설정
        else if (clk_div_20_p) begin // 분주된 클럭의 상승 에지에서 실행
            if (q == 16'b1000_0000_0000_0000)
                q = 16'b0000_0000_0000_0001; // 카운터가 순환하여 초기값으로 돌아감
            else 
                q = {q[14:0], 1'b0}; // q를 왼쪽으로 시프트하고 가장 오른쪽 비트에 0을 추가
        end
    end

endmodule


// 엣지 검출기_상승엣지 
module edge_detector_p(
    input clk,         // 클럭 신호 입력
    input reset_p,     // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    input cp,          // 감지할 신호 입력
    output p_edge,     // 상승 에지 검출 출력
    output n_edge      // 하강 에지 검출 출력
);
    
    // 현재 및 이전 신호 상태를 저장할 플립플롭
    reg ff_cur, ff_old;
    
    // 항상 블록: 클럭의 하강 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            ff_cur <= 0;   // 리셋 신호가 활성화되면 현재 상태를 0으로 초기화
            ff_old <= 0;   // 리셋 신호가 활성화되면 이전 상태를 0으로 초기화
        end else begin   
            ff_old <= ff_cur;  // 현재 상태를 이전 상태로 저장
            ff_cur <= cp;      // 입력 신호 cp를 현재 상태로 저장
        end
    end
    
    // 상승 에지 검출: 현재 상태가 1이고 이전 상태가 0일 때 (10) 1을 출력, 그렇지 않으면 0을 출력
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    // 하강 에지 검출: 현재 상태가 0이고 이전 상태가 1일 때 (01) 1을 출력, 그렇지 않으면 0을 출력
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
     
endmodule


// 시프트 레지스터 SISO
module shift_register_SISO_n(
    input clk,         // 클럭 신호 입력
    input reset_p,     // 비동기식 리셋 신호 입력 (양의 에지에서 활성화)
    input d,           // 직렬 데이터 입력
    output q           // 직렬 데이터 출력
);

    // 4비트 시프트 레지스터 선언
    reg [3:0] siso_reg;
    
    // 항상 블록: 클럭의 하강 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            siso_reg <= 0;                   // 리셋 신호가 활성화되면 레지스터 초기화
        else begin
            siso_reg[3] <= d;                // 직렬 입력 d를 siso_reg의 가장 상위 비트에 저장
            siso_reg[2] <= siso_reg[3];      // 이전 비트를 오른쪽으로 시프트
            siso_reg[1] <= siso_reg[2];      // 이전 비트를 오른쪽으로 시프트
            siso_reg[0] <= siso_reg[1];      // 이전 비트를 오른쪽으로 시프트
        end
    end
    
    // 직렬 출력 q: siso_reg의 가장 하위 비트를 출력
    assign q = siso_reg[0];

endmodule
   
            
// 시프트 레지스터 SIPO           
module shift_register_SIPO_n(
    input clk,          // 클럭 신호 입력
    input reset_p,      // 비동기식 리셋 신호 입력 (상승 에지에서 활성화)
    input d,            // 직렬 데이터 입력
    input rd_en,        // 읽기 활성화 신호 입력
    output [3:0] q      // 병렬 데이터 출력
);

    // 4비트 레지스터 선언, Shift Register를 저장하는 역할
    reg [3:0] sipo_reg;
    
    // 항상 블록: 클럭의 하강 에지 또는 리셋 신호의 상승 에지에서 실행
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            sipo_reg = 0;                       // 리셋 신호가 활성화되면 레지스터 초기화
        else 
            sipo_reg = {d, sipo_reg[3:1]};      // 직렬 입력 d를 왼쪽으로 시프트하고 sipo_reg에 저장
    end
    
    // 병렬 출력 q: 읽기 활성화 신호가 1이면 고임피던스 상태 ('z'), 그렇지 않으면 sipo_reg 값 출력
    assign q = rd_en ? 4'bz : sipo_reg;
    
    // bufif0: 읽기 활성화 신호에 따라 삼상 버퍼를 사용하여 병렬 출력 제어
    // (먹스로 처리해서 안씀 )bufif0 (q[0], sipo_reg[0], rd_en);  // q[0]: 출력, sipo_reg[0]: 입력, rd_en: 인에이블 신호
    

    
endmodule
    
// 시프트 레지스터 PISO            
module shift_register_PISO(
    input clk,       // 클럭 입력
    input reset_p,   // 리셋 입력
    input [3:0] d,   // 병렬 데이터 입력
    input shift_load, // 시프트 로드 신호 입력
    output q         // 시리얼 출력 비트
);

    reg [3:0] piso_reg; // PISO 레지스터 선언

    // 클럭과 리셋 신호에 대한 동작을 정의하는 always 블록
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) // 리셋 신호가 활성화되면
            piso_reg = 4'b0000; // 레지스터를 0으로 초기화
        else begin
            if (shift_load) // shift_load 신호가 활성화되면
                piso_reg = {1'b0, piso_reg[3:1]}; // PISO 레지스터를 왼쪽으로 시프트
            else
                piso_reg = d; // 그렇지 않으면 입력 d 값을 PISO 레지스터에 로드
        end
    end

    assign q = piso_reg[0]; // 출력 q는 PISO 레지스터의 최하위 비트

endmodule           



// N bit 레지스터
module register_Nbit_n #(parameter N = 8) (
    input [N-1:0] d,         // 데이터 입력 (N비트)
    input clk,               // 클럭 입력
    input reset_p,           // 비동기 리셋 입력 (액티브 하이)
    inout wr_en, rd_en,      // 레지스터의 쓰기/읽기 가능 여부 (입력)
    output [N-1: 0] q        // 레지스터 출력 (N비트)
);
    
    reg [N-1 : 0] register;  // N비트 레지스터 선언
    
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            register = 0;     // 리셋 신호가 활성화되면 레지스터를 0으로 초기화
        else if (wr_en) 
            register = d;     // 쓰기 가능 신호가 활성화되면 데이터를 레지스터에 저장
    end
    
    assign q = rd_en ? register : 'bz;  // 읽기 가능 신호가 활성화되면 레지스터 값을 출력(q), 그렇지 않으면 'bz 출력

endmodule


// s램_8bit 
module sram_8bit_1024(
    input clk,            // 클럭 입력
    input wr_en, rd_en,   // 쓰기/읽기 가능 여부 입력
    input [9:0] addr,     // 메모리 주소 입력 (10비트)
    inout [7:0] data      // 데이터 입출력 (8비트)
);

    reg [7:0] mem [0:1023];  // 8비트 메모리 배열 선언 (1024개의 요소)

    always @(posedge clk) begin
        if (wr_en)              // 쓰기 가능 신호가 활성화되면
            mem[addr] = data;   // 주어진 주소에 데이터를 메모리에 씁니다.
    end
    
    assign data = rd_en ? mem[addr] : 'bz;  // 읽기 가능 신호가 활성화되면 주어진 주소의 메모리 값을 데이터로 출력(data), 그렇지 않으면 'bz 출력

endmodule




