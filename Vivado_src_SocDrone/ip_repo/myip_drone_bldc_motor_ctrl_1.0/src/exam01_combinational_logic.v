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


module and_gate(        // �Ѵ� 1�϶��� 1, ������ 0 
    input a, b,
    output reg q);
    
    always @* begin
        case({a, b})
            2'b00: q = 1'b0;   // a=0, b=0: q�� 0�Դϴ�.
            2'b01: q = 1'b0;   // a=0, b=1: q�� 0�Դϴ�.
            2'b10: q = 1'b0;   // a=1, b=0: q�� 0�Դϴ�.
            2'b11: q = 1'b1;   // a=1, b=1: q�� 1�Դϴ�.
        endcase
    end

endmodule


 // �ݰ����  
module half_adder_behavioral(    
    input a, b,
    output reg s, c);
    
    always @* begin
        case({a, b})
            2'b00   :    begin      s = 1'b0;      c = 1'b0; end    // a=0, b=0: �ջ� ��� 0, ĳ�� ����
            2'b01   :    begin      s = 1'b1;      c = 1'b0; end    // a=0, b=1: �ջ� ��� 1, ĳ�� ����
            2'b10   :    begin      s = 1'b1;      c = 1'b0; end    // a=1, b=0: �ջ� ��� 1, ĳ�� ����
            2'b11   :    begin      s = 1'b0;      c = 1'b1; end    // a=1, b=1: �ջ� ��� 0, ĳ�� ����
        endcase
    end

endmodule      


// �ݰ���� ���� :  AND ����Ʈ��  XOR ����Ʈ ��� 
module half_adder_structural(
    input a, b,
    output s, c);

    // AND ����Ʈ�� ����Ͽ� ĳ�� ��� ���
    and(c, a, b);
    
    // XOR ����Ʈ�� ����Ͽ� �ջ� ��� ���
    xor(s, a, b);
    
endmodule      


// �ݰ���� ������ �帧
module half_adder_dataflow(
    input a, b,
    output s, c);

    // ���� ����� ������ ���̾� ����
    wire [1:0] sum_value;
    
    // ���� ��� ���
    assign sum_value = a + b;
    
    // �ջ� ����� ĳ�� ���
    assign s = sum_value[0]; // �ջ� ���
    assign c = sum_value[1]; // ĳ�� ���
    
endmodule



// ������� ���� - �ݰ���� ( AND ����Ʈ�� XOR ����Ʈ ) 2�� ��� �� OR ����Ʈ(ĳ�����) 
module full_adder_structural(
    input a, b, cin,
    output sum, carry);

    wire sum_0, carry_0, carry_1;
    
    // ù ��° half adder ����ü �ν��Ͻ�ȭ
    half_adder_structural ha0(.a(a), .b(b), .s(sum_0), .c(carry_0));
    
    // �� ��° half adder ����ü �ν��Ͻ�ȭ
    half_adder_structural ha1(.a(sum_0), .b(cin), .s(sum), .c(carry_1));
    
    // ĳ�� ��� ����� ���� OR ����Ʈ
    assign carry = carry_0 | carry_1;
    
endmodule


// �������
module full_adder_behavioral(   
    input a, b, cin,     // �Է� ��ȣ a, b, carry-in(cin)
    output reg sum,      // ��� ��ȣ sum
    output reg carry     // ��� ��ȣ carry
);
    
    // �ջ� �� ĳ�� ����� �����ϴ� always ���
    always @(a, b, cin) begin
        // case ���� ����Ͽ� �Է� ���տ� ���� �ٸ� ������ ����
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


//������� ������ �帧
module full_adder_dataflow(
    input a, b, cin,     // �Է� ��ȣ a, b, carry-in(cin)
    output sum, carry    // ��� ��ȣ sum, carry
);
    
    wire [1:0] sum_value;    // 2-bit wire ��ȣ sum_value
    
    // �������÷ο� �Ҵ�: ��ü ����� ���� ����
    assign sum_value = a + b + cin;  // sum_value�� a, b �� carry-in(cin)�� ���� ��
    
    // sum_value���� ������ ��� ��ȣ �Ҵ�
    assign sum = sum_value[0];      // sum�� sum_value�� 0��° ��Ʈ, �� ���� ��Ÿ��
    assign carry = sum_value[1];    // carry�� sum_value�� 1��° ��Ʈ, �� carry�� ��Ÿ��
    
endmodule


// �������  4��Ʈ ����
module fadder_4bit_structural(
    input [3:0] a,         // 4-bit �Է� a
    input [3:0] b,         // 4-bit �Է� b
    input cin,             // carry-in �Է�
    output [3:0] sum,      // 4-bit ��� sum
    output carry           // carry ���
);

    wire [2:0] carry_w;    // 3-bit wire ��ȣ carry_w
    
    //  ������ ��ü ����� ����� �ν��Ͻ�ȭ�Ͽ� ����
    //  fa0 ���� ���� carry ��� ���� ���� cin���� ���� �ݺ� �� ���������� sum�� �� carry�� ���   
    full_adder_structural fa0(.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1(.a(a[1]), .b(b[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2(.a(a[2]), .b(b[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3(.a(a[3]), .b(b[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry));
    
endmodule


// ������� 4��Ʈ ������ �帧
module fadder_4bit_dataflow(
    input [3:0] a,         // 4-bit �Է� a
    input [3:0] b,         // 4-bit �Է� b
    input cin,             // carry-in �Է�
    output [3:0] sum,      // 4-bit ��� sum
    output carry           // carry ���
);

    wire [4:0] sum_value;  // 5-bit wire ��ȣ sum_value
    
    // �������÷ο� �Ҵ�: sum �� carry ���
    assign sum_value = a + b + cin;  // sum_value�� carry-in�� ������ ���� ����� ����մϴ�.
    
    // sum_value���� 4-bit sum ����
    assign sum = sum_value[3:0];     // ���� 4��Ʈ�� sum���� �����մϴ�.
    
    // sum_value���� carry ����
    assign carry = sum_value[4];     // carry-out�� �����մϴ�.

endmodule



module fadd_sub_4bit_structural(
    input [3:0] a,         // 4��Ʈ �Է� a
    input [3:0] b,         // 4��Ʈ �Է� b
    input s,               // �Է�: 0(����), 1(����) ���� ��ȣ s
    output [3:0] sum,      // ���: ���� �Ǵ� ������ �����
    output carry           // ���: ���� �Ǵ� ������ ĳ�� ���
);

    wire [2:0] carry_w;    // 3��Ʈ wire ��ȣ carry_w ����
    wire [3:0] b_w;        // 4��Ʈ wire ��ȣ b_w ����
    
    // b_w�� b�� s�� XOR ������ ����� ����
    xor (b_w[0], b[0], s); // b_w[0] = b[0] XOR s
    xor (b_w[1], b[1], s); // b_w[1] = b[1] XOR s
    xor (b_w[2], b[2], s); // b_w[2] = b[2] XOR s
    xor (b_w[3], b[3], s); // b_w[3] = b[3] XOR s
    
    // ������ full_adder_structural ����� �ν��Ͻ�ȭ�Ͽ� ����
    full_adder_structural fa0(.a(a[0]), .b(b_w[0]), .cin(s), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1(.a(a[1]), .b(b_w[1]), .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2(.a(a[2]), .b(b_w[2]), .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3(.a(a[3]), .b(b_w[3]), .cin(carry_w[2]), .sum(sum[3]), .carry(carry));

endmodule



module fadd_sub_4bit_dataflow(
    input [3:0] a, b,       // 4��Ʈ �Է� a, b
    input s,                // �Է�: 0(����), 1(����) ���� ��ȣ s
    output [3:0] sum,       // ���: ���� �Ǵ� ������ �����
    output carry            // ���: ���� �Ǵ� ������ ĳ�� ���
);

    wire [4:0] sum_value;   // 5��Ʈ wire ��ȣ sum_value ����

    // ������ �÷ο� ������� ���� �Ǵ� ���� ����
    assign sum_value = s ? a - b : a + b;   // s�� 1�̸� ����, 0�̸� ����

    // sum�� sum_value�� ���� 4��Ʈ
    assign sum = sum_value[3:0];            // sum_value�� ���� 4��Ʈ�� sum�� �Ҵ�

    // carry�� sum_value�� 5��° ��Ʈ
    assign carry = s ? ~sum_value[4] : sum_value[4];   // s�� 1�̸� sum_value[4]�� ����, 0�̸� �״��

endmodule



// �񱳱�
module comparator_2bit(
    input [1:0] a,          // 2��Ʈ �Է� a
    input [1:0] b,          // 2��Ʈ �Է� b
    output equal,           // ���: ����
    output greater,         // ���: a�� b���� ŭ
    output less             // ���: a�� b���� ����
);
    
    assign equal   = (a == b) ? 1'b1 : 1'b0;   // a�� b�� ������ equal�� 1, �ƴϸ� 0
    assign greater = (a > b)  ? 1'b1 : 1'b0;   // a�� b���� ũ�� greater�� 1, �ƴϸ� 0
    assign less    = (a < b)  ? 1'b1 : 1'b0;   // a�� b���� ������ less�� 1, �ƴϸ� 0

endmodule

// �񱳱�  N bit
module comparator_Nbit #(parameter N = 8)(
    input [N-1:0] a, b,     // N ��Ʈ �Է� a, b
    output equal,           // ���: ����
    output greater,         // ���: a�� b���� ŭ
    output less             // ���: a�� b���� ����
);

    assign equal   = (a == b) ? 1'b1 : 1'b0;   // a�� b�� ������ equal�� 1, �ƴϸ� 0
    assign greater = (a > b)  ? 1'b1 : 1'b0;   // a�� b���� ũ�� greater�� 1, �ƴϸ� 0
    assign less    = (a < b)  ? 1'b1 : 1'b0;   // a�� b���� ������ less�� 1, �ƴϸ� 0

endmodule


module comparator_test_top(
    input [3:0] a,           // 4��Ʈ �Է� a
    input [3:0] b,           // 4��Ʈ �Է� b
    output equal,            // ���: ����
    output greater,          // ���: a�� b���� ŭ
    output less              // ���: a�� b���� ����
);
    
    comparator_Nbit #(4) c_4(  // 4��Ʈ �񱳱� ��� �ν��Ͻ�ȭ
        .a(a),                 // �Է� a�� ����� a�� ����
        .b(b),                 // �Է� b�� ����� b�� ����
        .equal(equal),         // ����� equal ����� ��� ��Ʈ�� ����
        .greater(greater),     // ����� greater ����� ��� ��Ʈ�� ����
        .less(less)            // ����� less ����� ��� ��Ʈ�� ����
    );
    
endmodule



module comparator_Nbit_b #(parameter N = 8)(
    input [N-1:0] a, b,     // N ��Ʈ �Է� a, b
    output reg equal,       // ���: ����
    output reg greater,     // ���: a�� b���� ŭ
    output reg less         // ���: a�� b���� ����
);

    always @* begin
        equal = 0;          // �ʱ�ȭ: ���� ��ȣ ��Ȱ��ȭ
        greater = 0;        // �ʱ�ȭ: ũ�� ��ȣ ��Ȱ��ȭ
        less = 0;           // �ʱ�ȭ: ���� ��ȣ ��Ȱ��ȭ
        
        if (a == b) begin   // a�� b�� ���� ���
            equal = 1;      // ���� ��ȣ Ȱ��ȭ
        end
        else if (a > b) begin   // a�� b���� ū ���
            greater = 1;    // ũ�� ��ȣ Ȱ��ȭ
        end
        else begin           // a�� b���� ���� ���
            less = 1;       // ���� ��ȣ Ȱ��ȭ
        end 
    end

endmodule
     
//    assign equal   =  (a == b) ? 1'b1 : 1'b0;
//    assign greater =  (a > b)  ? 1'b1 : 1'b0;
//    assign less    =  (a < b)  ? 1'b1 : 1'b0;



// ���ڴ� �Է� 2 x ��� 4
module decoderr_2x4_b( 
    input [1:0] code,       // �Է�: 2��Ʈ �ڵ� �Է�
    output reg [3:0] signal // ���: 4��Ʈ ��ȣ ��� (�������ͷ� ����)
);

    always @(code) begin
        // case ���� ����Ͽ� �ڵ忡 ���� ��ȣ�� �����մϴ�.
        case(code)
            2'b00 : signal = 4'b0001;  // �ڵ尡 00�� �� ��ȣ�� 0001�Դϴ�.
            2'b01 : signal = 4'b0010;  // �ڵ尡 01�� �� ��ȣ�� 0010�Դϴ�.
            2'b10 : signal = 4'b0100;  // �ڵ尡 10�� �� ��ȣ�� 0100�Դϴ�.
            2'b11 : signal = 4'b1000;  // �ڵ尡 11�� �� ��ȣ�� 1000�Դϴ�.
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
    input [1:0] code,     // �Է�: 2��Ʈ �ڵ� �Է�
    output [3:0] signal   // ���: 4��Ʈ ��ȣ ���
);
    
    // �ڵ忡 ���� ��ȣ�� �����ϴ� assign ����
    assign signal = (code == 2'b00) ? 4'b0001 :        // �ڵ尡 00�̸� ��ȣ�� 0001�Դϴ�.
                    ((code == 2'b01) ? 4'b0010 :       // �ڵ尡 01�̸� ��ȣ�� 0010�Դϴ�.
                    ((code == 2'b10) ? 4'b0100 :       // �ڵ尡 10�̸� ��ȣ�� 0100�Դϴ�.
                    4'b1000));                          // �� ���� ��� ��ȣ�� 1000�Դϴ�.

endmodule

// ���ڴ� ���׸�Ʈ
module decoder_7seg(
    input [3:0] hex_value,   // �Է�: 4��Ʈ ��簪
    output reg [7:0] seg_7   // ���: 7���׸�Ʈ ǥ�ð�
);
    
    // ��簪�� ���� 7���׸�Ʈ ����� �����ϴ� always ���
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
            default: seg_7 = 8'b1111_1111;   // �⺻��: ��� ���׸�Ʈ ����
        endcase
    end

endmodule


// ���ڴ� - ��� 4 x �Է� 2 (���ڴ��� ����� ���ڴ��� �޾Ƽ� �Է����� ��ȯ) 
module encoderr_4x2_b( 
    output reg [1:0] code,  // ���: 2��Ʈ �ڵ� ���
    input [3:0] signal      // �Է�: 4��Ʈ ��ȣ �Է�
);

    always @* begin
        // �Է� ��ȣ�� ���� �ڵ带 �����ϴ� ���ǹ�
        if (signal == 4'b0001)     // �Է��� 0001�� ��
            code = 2'b00;          // �ڵ�� 00�Դϴ�.
        else if (signal == 4'b0010) // �Է��� 0010�� ��
            code = 2'b01;          // �ڵ�� 01�Դϴ�.
        else if (signal == 4'b0100) // �Է��� 0100�� ��
            code = 2'b10;          // �ڵ�� 10�Դϴ�.
        else                        // �� ���� ���
            code = 2'b11;          // �ڵ�� 11�Դϴ�.
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
    output [1:0] code,  // ���: 2��Ʈ �ڵ� ���
    input [3:0] signal  // �Է�: 4��Ʈ ��ȣ �Է�
);
    
    // 4:2 ���ڴ��� ����� �����ϴ� assign ����
    assign code = (signal == 4'b0001) ? 2'b00 :        // �Է��� 0001�� ��, �ڵ�� 00�Դϴ�.
                  ((signal == 4'b0010) ? 2'b01 :       // �Է��� 0010�� ��, �ڵ�� 01�Դϴ�.
                  ((signal == 4'b0100) ? 2'b10 :       // �Է��� 0100�� ��, �ڵ�� 10�Դϴ�.
                  ((signal == 4'b1000) ? 2'b11 : 2'b00)));  // �Է��� 1000�� ��, �ڵ�� 11�Դϴ�. ������ ��쿡�� �ڵ�� 00�Դϴ�.

endmodule
        
                   
// mux 2bit                   
module mux_2_1(
    input [1:0] d,  // �Է�: 2��Ʈ ������ �Է�
    input s,        // �Է�: ���� ��ȣ (1��Ʈ)
    output f    // ���: 1��Ʈ ���
);
    
    // 2:1 MUX�� ����� �����ϴ� assign ����
    assign f = s ? d[1] : d[0];  // s�� 1�� �� d[1], s�� 0�� �� d[0]�� �����Ͽ� f�� �Ҵ��մϴ�.
    
endmodule         


// mux 4bit      
module mux_4_1(
    input [3:0] d,    // �Է�: 4��Ʈ ������ �Է�
    input [1:0] s,    // �Է�: 2��Ʈ ���� ��ȣ
    output f      // ���: 1��Ʈ ���
);

    // 4:1 MUX�� ����� �����ϴ� assign ����
    assign f = d[s];  // �Է� d �߿��� s�� �ش��ϴ� ��Ʈ�� �����Ͽ� f�� �Ҵ��մϴ�.

endmodule   


// mux 8bit      
module mux_8_1(
    input [7:0] d,    // �Է�: 8��Ʈ ������ �Է�
    input [2:0] s,    // �Է�: 3��Ʈ ���� ��ȣ
    output f      // ���: 1��Ʈ ���
);

    // 8:1 MUX�� ����� �����ϴ� assign ����
    assign f = d[s];  // �Է� d �߿��� s�� �ش��ϴ� ��Ʈ�� �����Ͽ� f�� �Ҵ��մϴ�.

endmodule
                             



module demux_1_4_d(
    input d,            // �Է�: ������ �Է�
    input [1:0] s,      // �Է�: ���� ��ȣ
    output [3:0] f      // ���: 4��Ʈ ���
);

    // ���� ������ ����Ͽ� ��� ��ȣ�� �����ϴ� assign ����
    assign f = (s == 2'b00) ? {3'b000, d} :        // s�� 00�� ��, f�� d�� �տ� 3��Ʈ 0�� ���Դϴ�.
               (s == 2'b01) ? {2'b00, d, 1'b0} :   // s�� 01�� ��, f�� d�� �տ� 2��Ʈ 0, �ڿ� 1��Ʈ 0�� ���Դϴ�.
               (s == 2'b10) ? {1'b0, d, 2'b00} :   // s�� 10�� ��, f�� d�� �տ� 1��Ʈ 0, �ڿ� 2��Ʈ 0�� ���Դϴ�.
                              {d, 3'b000};         // s�� 11�� ��, f�� d�� �ڿ� 3��Ʈ 0�� ���Դϴ�.

endmodule

module mux_demux_test(
    input [3:0] d,       // �Է�: 4��Ʈ ������ �Է�
    input [1:0] mux_s,   // �Է�: 2��Ʈ MUX ���� ��ȣ
    input [1:0] demux_s, // �Է�: 2��Ʈ DEMUX ���� ��ȣ
    output [3:0] f       // ���: 4��Ʈ ��� ��ȣ
);

    wire mux_f;  // MUX ��� ��ȣ�� ���� ���̾� ����

    // 4:1 MUX ��� �ν��Ͻ�ȭ
    mux_4_1 mux4(
        .d(d),        // �Է� ������
        .s(mux_s),    // MUX ���� ��ȣ
        .f(mux_f)     // MUX ��� ��ȣ
    );

    // 1:4 DEMUX ��� �ν��Ͻ�ȭ
    demux_1_4_d demux4(
        .d(mux_f),    // MUX ��� ��ȣ�� DEMUX �Է����� ����
        .s(demux_s),  // DEMUX ���� ��ȣ
        .f(f)         // DEMUX ���
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







