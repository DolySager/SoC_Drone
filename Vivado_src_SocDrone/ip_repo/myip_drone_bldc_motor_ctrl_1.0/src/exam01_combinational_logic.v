`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/14 11:13:33
// Design Name: 
// Module Name: exam01_combinational_logic
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


module and_gate(        // 둘다 1일때만 1, 나머진 0 
    input a, b,
    output reg q);
    
    always @* begin
        case({a, b})
            2'b00: q = 1'b0;   // a=0, b=0: q는 0입니다.
            2'b01: q = 1'b0;   // a=0, b=1: q는 0입니다.
            2'b10: q = 1'b0;   // a=1, b=0: q는 0입니다.
            2'b11: q = 1'b1;   // a=1, b=1: q는 1입니다.
        endcase
    end

endmodule


 // 반가산기  
module half_adder_behavioral(    
    input a, b,
    output reg s, c);
    
    always @* begin
        case({a, b})
            2'b00   :    begin      s = 1'b0;      c = 1'b0; end    // a=0, b=0: 합산 결과 0, 캐리 없음
            2'b01   :    begin      s = 1'b1;      c = 1'b0; end    // a=0, b=1: 합산 결과 1, 캐리 없음
            2'b10   :    begin      s = 1'b1;      c = 1'b0; end    // a=1, b=0: 합산 결과 1, 캐리 없음
            2'b11   :    begin      s = 1'b0;      c = 1'b1; end    // a=1, b=1: 합산 결과 0, 캐리 있음
        endcase
    end

endmodule      


// 반가산기 구조 :  AND 게이트와  XOR 게이트 사용 
module half_adder_structural(
    input a, b,
    output s, c);

    // AND 게이트를 사용하여 캐리 출력 계산
    and(c, a, b);
    
    // XOR 게이트를 사용하여 합산 결과 계산
    xor(s, a, b);
    
endmodule      


// 반가산기 데이터 흐름
module half_adder_dataflow(
    input a, b,
    output s, c);

    // 덧셈 결과를 저장할 와이어 선언
    wire [1:0] sum_value;
    
    // 덧셈 결과 계산
    assign sum_value = a + b;
    
    // 합산 결과와 캐리 출력
    assign s = sum_value[0]; // 합산 결과
    assign c = sum_value[1]; // 캐리 출력
    
endmodule



// 전가산기 구조 - 반가산기 ( AND 게이트와 XOR 게이트 ) 2번 사용 및 OR 게이트(캐리출력) 
module full_adder_structural(
    input a, b, cin,
    output sum, carry);

    wire sum_0, carry_0, carry_1;
    
    // 첫 번째 half adder 구조체 인스턴스화
    half_adder_structural ha0(.a(a), .b(b), .s(sum_0), .c(carry_0));
    
    // 두 번째 half adder 구조체 인스턴스화
    half_adder_structural ha1(.a(sum_0), .b(cin), .s(sum), .c(carry_1));
    
    // 캐리 출력 계산을 위한 OR 게이트
    assign carry = carry_0 | carry_1;
    
endmodule


// 전가산기
module full_adder_behavioral(   
    input a, b, cin,     // 입력 신호 a, b, carry-in(cin)
    output reg sum,      // 출력 신호 sum
    output reg carry     // 출력 신호 carry
);
    
    // 합산 및 캐리 계산을 수행하는 always 블록
    always @(a, b, cin) begin
        // case 문을 사용하여 입력 조합에 따라 다른 동작을 수행
        case({a, b, cin})
            3'b000 : begin sum = 0; carry = 0; end // a=0, b=0, cin=0
            3'b001 : begin sum = 1; carry = 0; end // a=0, b=0, cin=1
            3'b010 : begin sum = 1; carry = 0; end // a=0, b=1, cin=0
            3'b011 : begin sum = 0; carry = 1; end // a=0, b=1, cin=1
            
            3'b100 : begin sum = 1; carry = 0; end // a=1, b=0, cin=0
            3'b101 : begin sum = 0; carry = 1; end // a=1, b=0, cin=1
            3'b110 : begin sum = 0; carry = 1; end // a=1, b=1, cin=0
            3'b111 : begin sum = 1; carry = 1; end // a=1, b=1, cin=1
        endcase
    end
    
endmodule


//전가산기 데이터 흐름
module full_adder_dataflow(
    input a, b, cin,     // 입력 신호 a, b, carry-in(cin)
    output sum, carry    // 출력 신호 sum, carry
);
    
    wire [1:0] sum_value;    // 2-bit wire 신호 sum_value
    
    // 데이터플로우 할당: 전체 가산기 동작 정의
    assign sum_value = a + b + cin;  // sum_value는 a, b 및 carry-in(cin)을 더한 값
    
    // sum_value에서 각각의 출력 신호 할당
    assign sum = sum_value[0];      // sum은 sum_value의 0번째 비트, 즉 합을 나타냄
    assign carry = sum_value[1];    // carry는 sum_value의 1번째 비트, 즉 carry를 나타냄
    
endmodule


// 전가산기  4비트 구조
module fadder_4bit_structural(
    input [3:0] a,         // 4-bit 입력 a
    input [3:0] b,         // 4-bit 입력 b
    input cin,             // carry-in 입력
    output [3:0] sum,      // 4-bit 출력 sum
    output carry           // carry 출력
);

    wire [2:0] carry_w;    // 3-bit wire 신호 carry_w
    
    //  각각의 전체 가산기 모듈을 인스턴스화하여 연결
    //  fa0 에서 받은 carry 출력 값을 다음 cin값에 대입 반복 후 최종적으로 sum값 과 carry값 출력   
    full_adder_structural fa0(.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1(.a(a[1]), .b(b[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2(.a(a[2]), .b(b[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3(.a(a[3]), .b(b[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry));
    
endmodule


// 전가산기 4비트 데이터 흐름
module fadder_4bit_dataflow(
    input [3:0] a,         // 4-bit 입력 a
    input [3:0] b,         // 4-bit 입력 b
    input cin,             // carry-in 입력
    output [3:0] sum,      // 4-bit 출력 sum
    output carry           // carry 출력
);

    wire [4:0] sum_value;  // 5-bit wire 신호 sum_value
    
    // 데이터플로우 할당: sum 및 carry 계산
    assign sum_value = a + b + cin;  // sum_value는 carry-in을 포함한 덧셈 결과를 계산합니다.
    
    // sum_value에서 4-bit sum 추출
    assign sum = sum_value[3:0];     // 하위 4비트를 sum으로 추출합니다.
    
    // sum_value에서 carry 추출
    assign carry = sum_value[4];     // carry-out을 추출합니다.

endmodule



module fadd_sub_4bit_structural(
    input [3:0] a,         // 4비트 입력 a
    input [3:0] b,         // 4비트 입력 b
    input s,               // 입력: 0(덧셈), 1(뺄셈) 선택 신호 s
    output [3:0] sum,      // 출력: 덧셈 또는 뺄셈의 결과값
    output carry           // 출력: 덧셈 또는 뺄셈의 캐리 출력
);

    wire [2:0] carry_w;    // 3비트 wire 신호 carry_w 정의
    wire [3:0] b_w;        // 4비트 wire 신호 b_w 정의
    
    // b_w는 b와 s를 XOR 연산한 결과를 저장
    xor (b_w[0], b[0], s); // b_w[0] = b[0] XOR s
    xor (b_w[1], b[1], s); // b_w[1] = b[1] XOR s
    xor (b_w[2], b[2], s); // b_w[2] = b[2] XOR s
    xor (b_w[3], b[3], s); // b_w[3] = b[3] XOR s
    
    // 각각의 full_adder_structural 모듈을 인스턴스화하여 연결
    full_adder_structural fa0(.a(a[0]), .b(b_w[0]), .cin(s), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1(.a(a[1]), .b(b_w[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2(.a(a[2]), .b(b_w[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3(.a(a[3]), .b(b_w[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry));

endmodule



module fadd_sub_4bit_dataflow(
    input [3:0] a, b,       // 4비트 입력 a, b
    input s,                // 입력: 0(덧셈), 1(뺄셈) 선택 신호 s
    output [3:0] sum,       // 출력: 덧셈 또는 뺄셈의 결과값
    output carry            // 출력: 덧셈 또는 뺄셈의 캐리 출력
);

    wire [4:0] sum_value;   // 5비트 wire 신호 sum_value 정의

    // 데이터 플로우 방식으로 덧셈 또는 뺄셈 수행
    assign sum_value = s ? a - b : a + b;   // s가 1이면 뺄셈, 0이면 덧셈

    // sum은 sum_value의 하위 4비트
    assign sum = sum_value[3:0];            // sum_value의 하위 4비트를 sum에 할당

    // carry는 sum_value의 5번째 비트
    assign carry = s ? ~sum_value[4] : sum_value[4];   // s가 1이면 sum_value[4]의 반전, 0이면 그대로

endmodule



// 비교기
module comparator_2bit(
    input [1:0] a,          // 2비트 입력 a
    input [1:0] b,          // 2비트 입력 b
    output equal,           // 출력: 같음
    output greater,         // 출력: a가 b보다 큼
    output less             // 출력: a가 b보다 작음
);
    
    assign equal   = (a == b) ? 1'b1 : 1'b0;   // a와 b가 같으면 equal은 1, 아니면 0
    assign greater = (a > b)  ? 1'b1 : 1'b0;   // a가 b보다 크면 greater은 1, 아니면 0
    assign less    = (a < b)  ? 1'b1 : 1'b0;   // a가 b보다 작으면 less는 1, 아니면 0

endmodule

// 비교기  N bit
module comparator_Nbit #(parameter N = 8)(
    input [N-1:0] a, b,     // N 비트 입력 a, b
    output equal,           // 출력: 같음
    output greater,         // 출력: a가 b보다 큼
    output less             // 출력: a가 b보다 작음
);

    assign equal   = (a == b) ? 1'b1 : 1'b0;   // a와 b가 같으면 equal은 1, 아니면 0
    assign greater = (a > b)  ? 1'b1 : 1'b0;   // a가 b보다 크면 greater은 1, 아니면 0
    assign less    = (a < b)  ? 1'b1 : 1'b0;   // a가 b보다 작으면 less는 1, 아니면 0

endmodule


module comparator_test_top(
    input [3:0] a,           // 4비트 입력 a
    input [3:0] b,           // 4비트 입력 b
    output equal,            // 출력: 같음
    output greater,          // 출력: a가 b보다 큼
    output less              // 출력: a가 b보다 작음
);
    
    comparator_Nbit #(4) c_4(  // 4비트 비교기 모듈 인스턴스화
        .a(a),                 // 입력 a를 모듈의 a에 연결
        .b(b),                 // 입력 b를 모듈의 b에 연결
        .equal(equal),         // 모듈의 equal 출력을 출력 포트에 연결
        .greater(greater),     // 모듈의 greater 출력을 출력 포트에 연결
        .less(less)            // 모듈의 less 출력을 출력 포트에 연결
    );
    
endmodule



module comparator_Nbit_b #(parameter N = 8)(
    input [N-1:0] a, b,     // N 비트 입력 a, b
    output reg equal,       // 출력: 같음
    output reg greater,     // 출력: a가 b보다 큼
    output reg less         // 출력: a가 b보다 작음
);

    always @* begin
        equal = 0;          // 초기화: 같음 신호 비활성화
        greater = 0;        // 초기화: 크기 신호 비활성화
        less = 0;           // 초기화: 작음 신호 비활성화
        
        if (a == b) begin   // a와 b가 같은 경우
            equal = 1;      // 같음 신호 활성화
        end
        else if (a > b) begin   // a가 b보다 큰 경우
            greater = 1;    // 크기 신호 활성화
        end
        else begin           // a가 b보다 작은 경우
            less = 1;       // 작음 신호 활성화
        end 
    end

endmodule
     
//    assign equal   =  (a == b) ? 1'b1 : 1'b0;
//    assign greater =  (a > b)  ? 1'b1 : 1'b0;
//    assign less    =  (a < b)  ? 1'b1 : 1'b0;



// 디코더 입력 2 x 출력 4
module decoderr_2x4_b( 
    input [1:0] code,       // 입력: 2비트 코드 입력
    output reg [3:0] signal // 출력: 4비트 신호 출력 (레지스터로 선언)
);

    always @(code) begin
        // case 문을 사용하여 코드에 따라 신호를 설정합니다.
        case(code)
            2'b00 : signal = 4'b0001;  // 코드가 00일 때 신호는 0001입니다.
            2'b01 : signal = 4'b0010;  // 코드가 01일 때 신호는 0010입니다.
            2'b10 : signal = 4'b0100;  // 코드가 10일 때 신호는 0100입니다.
            2'b11 : signal = 4'b1000;  // 코드가 11일 때 신호는 1000입니다.
        endcase
    end

endmodule
    
    
//    always @(code)begin
//        if(code == 2'b00) signal = 4'b0001;
//        else if(code == 2'b01) signal = 4'b0001;
//        else if(code == 2'b10) signal = 4'b0001;
//        else signal = 4'b1000;
//    end

     
module decoderr_2x4_d(
    input [1:0] code,     // 입력: 2비트 코드 입력
    output [3:0] signal   // 출력: 4비트 신호 출력
);
    
    // 코드에 따라 신호를 설정하는 assign 문장
    assign signal = (code == 2'b00) ? 4'b0001 :        // 코드가 00이면 신호는 0001입니다.
                    ((code == 2'b01) ? 4'b0010 :       // 코드가 01이면 신호는 0010입니다.
                    ((code == 2'b10) ? 4'b0100 :       // 코드가 10이면 신호는 0100입니다.
                    4'b1000));                          // 그 외의 경우 신호는 1000입니다.

endmodule

// 디코더 세그먼트
module decoder_7seg(
    input [3:0] hex_value,   // 입력: 4비트 헥사값
    output reg [7:0] seg_7   // 출력: 7세그먼트 표시값
);
    
    // 헥사값에 따라 7세그먼트 출력을 결정하는 always 블록
    always @* begin
        case(hex_value)
            // abcd_efg (a: seg_7[7], b: seg_7[6], ..., g: seg_7[0])
            4'b0000 : seg_7 = 8'b0000_0011; // 0
            4'b0001 : seg_7 = 8'b1001_1111; // 1
            4'b0010 : seg_7 = 8'b0010_0101; // 2
            4'b0011 : seg_7 = 8'b0000_1101; // 3
            4'b0100 : seg_7 = 8'b1001_1001; // 4
            4'b0101 : seg_7 = 8'b0100_1001; // 5
            4'b0110 : seg_7 = 8'b0100_0001; // 6
            4'b0111 : seg_7 = 8'b0001_1111; // 7
            4'b1000 : seg_7 = 8'b0000_0001; // 8
            4'b1001 : seg_7 = 8'b0001_1001; // 9
            4'b1010 : seg_7 = 8'b0000_1001; // A
            4'b1011 : seg_7 = 8'b1100_0001; // b
            4'b1100 : seg_7 = 8'b0110_0011; // c
            4'b1101 : seg_7 = 8'b1000_0101; // d
            4'b1110 : seg_7 = 8'b0110_0001; // e
            4'b1111 : seg_7 = 8'b0111_0001; // f  
            default: seg_7 = 8'b1111_1111;   // 기본값: 모든 세그먼트 끄기
        endcase
    end

endmodule


// 인코더 - 출력 4 x 입력 2 (디코더의 출력을 인코더로 받아서 입력으로 변환) 
module encoderr_4x2_b( 
    output reg [1:0] code,  // 출력: 2비트 코드 출력
    input [3:0] signal      // 입력: 4비트 신호 입력
);

    always @* begin
        // 입력 신호에 따라 코드를 설정하는 조건문
        if (signal == 4'b0001)     // 입력이 0001일 때
            code = 2'b00;          // 코드는 00입니다.
        else if (signal == 4'b0010) // 입력이 0010일 때
            code = 2'b01;          // 코드는 01입니다.
        else if (signal == 4'b0100) // 입력이 0100일 때
            code = 2'b10;          // 코드는 10입니다.
        else                        // 그 외의 경우
            code = 2'b11;          // 코드는 11입니다.
    end

endmodule


//   always @(signal)begin
//        case(signal)
//            4'b0001 : code = 2'b00;           
//            4'b0010 : code = 2'b01;           
//            4'b0100 : code = 2'b10;           
//            4'b1000 : code = 2'b11;           
//            default : code = 2'b00;           
//        endcase                               
//    end                            
                                   



module encoderr_4x2_d(
    output [1:0] code,  // 출력: 2비트 코드 출력
    input [3:0] signal  // 입력: 4비트 신호 입력
);
    
    // 4:2 인코더의 출력을 결정하는 assign 문장
    assign code = (signal == 4'b0001) ? 2'b00 :        // 입력이 0001일 때, 코드는 00입니다.
                  ((signal == 4'b0010) ? 2'b01 :       // 입력이 0010일 때, 코드는 01입니다.
                  ((signal == 4'b0100) ? 2'b10 :       // 입력이 0100일 때, 코드는 10입니다.
                  ((signal == 4'b1000) ? 2'b11 : 2'b00)));  // 입력이 1000일 때, 코드는 11입니다. 나머지 경우에는 코드는 00입니다.

endmodule
        
                   
// mux 2bit                   
module mux_2_1(
    input [1:0] d,  // 입력: 2비트 데이터 입력
    input s,        // 입력: 선택 신호 (1비트)
    output f    // 출력: 1비트 출력
);
    
    // 2:1 MUX의 출력을 결정하는 assign 문장
    assign f = s ? d[1] : d[0];  // s가 1일 때 d[1], s가 0일 때 d[0]을 선택하여 f에 할당합니다.
    
endmodule         


// mux 4bit      
module mux_4_1(
    input [3:0] d,    // 입력: 4비트 데이터 입력
    input [1:0] s,    // 입력: 2비트 선택 신호
    output f      // 출력: 1비트 출력
);

    // 4:1 MUX의 출력을 결정하는 assign 문장
    assign f = d[s];  // 입력 d 중에서 s에 해당하는 비트를 선택하여 f에 할당합니다.

endmodule   


// mux 8bit      
module mux_8_1(
    input [7:0] d,    // 입력: 8비트 데이터 입력
    input [2:0] s,    // 입력: 3비트 선택 신호
    output f      // 출력: 1비트 출력
);

    // 8:1 MUX의 출력을 결정하는 assign 문장
    assign f = d[s];  // 입력 d 중에서 s에 해당하는 비트를 선택하여 f에 할당합니다.

endmodule
                             



module demux_1_4_d(
    input d,            // 입력: 데이터 입력
    input [1:0] s,      // 입력: 선택 신호
    output [3:0] f      // 출력: 4비트 출력
);

    // 다중 조건을 사용하여 출력 신호를 선택하는 assign 문장
    assign f = (s == 2'b00) ? {3'b000, d} :        // s가 00일 때, f는 d의 앞에 3비트 0을 붙입니다.
               (s == 2'b01) ? {2'b00, d, 1'b0} :   // s가 01일 때, f는 d의 앞에 2비트 0, 뒤에 1비트 0을 붙입니다.
               (s == 2'b10) ? {1'b0, d, 2'b00} :   // s가 10일 때, f는 d의 앞에 1비트 0, 뒤에 2비트 0을 붙입니다.
                              {d, 3'b000};         // s가 11일 때, f는 d의 뒤에 3비트 0을 붙입니다.

endmodule

module mux_demux_test(
    input [3:0] d,       // 입력: 4비트 데이터 입력
    input [1:0] mux_s,   // 입력: 2비트 MUX 선택 신호
    input [1:0] demux_s, // 입력: 2비트 DEMUX 선택 신호
    output [3:0] f       // 출력: 4비트 출력 신호
);

    wire mux_f;  // MUX 출력 신호를 위한 와이어 선언

    // 4:1 MUX 모듈 인스턴스화
    mux_4_1 mux4(
        .d(d),        // 입력 데이터
        .s(mux_s),    // MUX 선택 신호
        .f(mux_f)     // MUX 출력 신호
    );

    // 1:4 DEMUX 모듈 인스턴스화
    demux_1_4_d demux4(
        .d(mux_f),    // MUX 출력 신호를 DEMUX 입력으로 연결
        .s(demux_s),  // DEMUX 선택 신호
        .f(f)         // DEMUX 출력
    ); 

endmodule




module bin_to_dec(
        input [11:0] bin,
        output reg [15:0] bcd
    );

    reg [3:0] i;

    always @(bin) begin
        bcd = 0;
        for (i=0;i<12;i=i+1)begin
            bcd = {bcd[14:0], bin[11-i]};
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule







