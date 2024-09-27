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

// D_�ø��÷�_n (�ϰ�����)
module D_flip_flop_n(
    input d,               // �Է�: ������ �Է�
    input clk,             // �Է�: Ŭ��
    input reset_p,         // �Է�: �񵿱� ����
    inout enable,          // �����: Ȱ��ȭ ��ȣ (inout���� ����)
    output reg q           // ���: D �ø��÷� ���
);
    
    always @(negedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            q = 0;  // �ø��÷��� 0���� �ʱ�ȭ
        end
        // enable ��ȣ�� Ȱ��ȭ�ǰ� Ŭ����  �ϰ��������� ������ �Է��� q�� ����
        else if (enable) begin
            q = d;  // ������ d�� q�� ����
        end
    end
    
endmodule


// D_�ø��÷�_p (��¿���)
module D_flip_flop_p(
    input d,               // �Է�: ������ �Է�
    input clk,             // �Է�: Ŭ��
    input reset_p,         // �Է�: �񵿱� ����
    inout enable,          // �����: Ȱ��ȭ ��ȣ (inout���� ����)
    output reg q           // ���: D �ø��÷� ���
);
    
    always @(posedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            q = 0;  // �ø��÷��� 0���� �ʱ�ȭ
        end
        // enable ��ȣ�� Ȱ��ȭ�ǰ� Ŭ�� ��¿������� ������ �Է��� q�� ����
        else if (enable) begin
            q = d;  // ������ d�� q�� ����
        end
    end
    
endmodule



// T_�ø��÷�_n (�ϰ�����)
module T_flip_flop_n(
    input clk, reset_p,     // �Է�: Ŭ��, ����
    input t,                // �Է�: T Ʈ����
    output reg q            // ���: T �ø��÷� ���
);
    
    always @(negedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            q = 0;  // �ø��÷��� 0���� �ʱ�ȭ
        end
        else begin
            // T Ʈ���� ��ȣ�� Ȱ��ȭ�Ǹ� �ø��÷� ���� ����
            if (t) begin
                q = ~q;  // q�� ������Ŵ
            end
            // T Ʈ���� ��ȣ�� ��Ȱ��ȭ�Ǹ� �ø��÷� ���� ����
            else begin
                q = q;  // q�� ������
            end
        end
    end

endmodule


// T_�ø��÷�_p(��¿���)
module T_flip_flop_p(
    input clk, reset_p,     // �Է�: Ŭ��, ����
    input t,                // �Է�: T Ʈ����
    output reg q            // ���: T �ø��÷� ���
);
    
    always @(posedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            q = 0;  // �ø��÷��� 0���� �ʱ�ȭ
        end
        else begin
            // T Ʈ���� ��ȣ�� Ȱ��ȭ�Ǹ� �ø��÷� ���� ����
            if (t) begin
                q = ~q;  // q�� ������Ŵ
            end
            // T Ʈ���� ��ȣ�� ��Ȱ��ȭ�Ǹ� �ø��÷� ���� ����
            else begin
                q = q;  // q�� ������
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



// �񵿱�� �� ī����
module up_counter_asyc(
    input clk, reset_p,      // �Է�: Ŭ��, �񵿱� ����
    output [3:0] count      // ���: 4��Ʈ �� ī����
);
    
    // T �ø��÷� ��� �ν��Ͻ�ȭ
    T_flip_flop_n T0(.clk(clk), .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));

endmodule


// �񵿱�� �ٿ� ī����
module down_counter_asyc(
    input clk, reset_p,      // �Է�: Ŭ��, �񵿱� ����
    output [3:0] count      // ���: 4��Ʈ �ٿ� ī����
);
    
    // T �ø��÷� ��� �ν��Ͻ�ȭ
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


// ��ī����_��¿���
module up_counter_p(
    input clk, reset_p, enable,       // �Է�: Ŭ��, ����, ī��Ʈ Ȱ��ȭ ��ȣ
    output reg [3:0] count           // ���: 4��Ʈ �� ī����
);

    always @(posedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            count = 0;  // ī���͸� 0���� �ʱ�ȭ
        end
        // enable ��ȣ�� Ȱ��ȭ�Ǹ� ī���� ����
        else if (enable) begin 
            count = count + 1;    // ī���͸� 1 ����
        end
    end

endmodule


// �ٿ�ī����_��¿���
module down_counter_p(
    input clk, reset_p, enable,       // �Է�: Ŭ��, ����, ī��Ʈ Ȱ��ȭ ��ȣ
    output reg [3:0] count           // ���: 4��Ʈ �ٿ� ī����
);

    always @(posedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            count = 0;  // ī���͸� 0���� �ʱ�ȭ
        end
        // enable ��ȣ�� Ȱ��ȭ�Ǹ� ī���� ����
        else if (enable) begin 
            count = count - 1;    // ī���͸� 1 ����
        end
    end

endmodule


// bcd �� ī����_��¿���
module bcd_up_counter_p(
    input clk, reset_p, enable,      // �Է�: Ŭ��, ����, ī��Ʈ Ȱ��ȭ ��ȣ
    output reg [3:0] count          // ���: 4��Ʈ ī����
);
     
    always @(posedge clk or posedge reset_p) begin
        // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �׻� ����
        if (reset_p) begin
            count = 0;  // ī���͸� 0���� �ʱ�ȭ
        end
        // enable ��ȣ�� Ȱ��ȭ�Ǹ� ī���� ����
        else if (enable) begin 
            count = count + 1;    // ī���͸� 1 ����
            
            // BCD ���� ����: count�� 9�� �ʰ����� �ʵ��� ����
            if (count >= 10) begin
                count = 0;  // count�� 10 �̻��̸� 0���� �ݺ�
            end
        end
    end

endmodule


// bcd �ٿ� ī����_��¿���
module bcd_down_counter_p(
    input clk,         // Ŭ�� �Է�
    input reset_p,     // ���� �Է� (�񵿱������� Ȱ��ȭ�Ǵ� active-high ��ȣ)
    input enable,      // ī������ Ȱ��ȭ�ϴ� �Է�
    output reg [3:0] count  // 4��Ʈ ī���� ���
);
     
    always @(posedge clk or posedge reset_p) begin
        // Ŭ�� ��ȣ�� ���� ��ȣ�� �������� ������ �� �׻� ����
        if (reset_p) begin
            count = 0;  // ���� ��ȣ�� Ȱ��ȭ�Ǹ� count�� 0���� �ʱ�ȭ
        end
        else if (enable) begin
            // enable ��ȣ�� Ȱ��ȭ�� ��� ī���� ����
            count = count - 1;
            
            // BCD ���� ����: count�� 9�� �ʰ����� �ʵ��� ����
            if (count >= 10) begin
                count = 9;  // count�� 10 �̻��̸� 9�� ����
            end
        end
    end

endmodule


// �� �ٿ� ī����
module up_down_counter(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    input enable,     // ī���� Ȱ��ȭ ��ȣ �Է�
    input up_down,    // ī���� ���� ��ȣ �Է� (1�̸� �� ī��Ʈ, 0�̸� �ٿ� ī��Ʈ)
    output reg [3:0] count // 4��Ʈ ī���� ���
);

    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            count = 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� count�� 0���� ����
        else if (enable) begin // ī���Ͱ� Ȱ��ȭ�� ���
            if (up_down) begin // �� ī��Ʈ ���
                count = count + 1; // count�� 1 ����
            end else begin // �ٿ� ī��Ʈ ���
                count = count - 1; // count�� 1 ����
            end
        end
    end

endmodule


// �� �ٿ� bcd ī����
module up_down_bcd_counter(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    input enable,     // ī���� Ȱ��ȭ ��ȣ �Է�
    input up_down,    // ī���� ���� ��ȣ �Է� (1�̸� �� ī��Ʈ, 0�̸� �ٿ� ī��Ʈ)
    output reg [3:0] count // 4��Ʈ BCD ī���� ���
);

    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            count = 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� count�� 0���� ����
        else if (enable) begin // ī���Ͱ� Ȱ��ȭ�� ���
            if (up_down) begin // �� ī��Ʈ ���
                if (count >= 9)
                    count = 0; // count�� 9 �̻��̸� 0���� ���� (BCD ��ȯ)
                else
                    count = count + 1; // �׷��� ������ count�� 1 ����
            end else begin // �ٿ� ī��Ʈ ���
                if (count == 0)
                    count = 9; // count�� 0�̸� 9�� ���� (BCD ��ȯ)
                else
                    count = count - 1; // �׷��� ������ count�� 1 ����
            end
        end
    end

endmodule

// �� ī���� 
module ring_counter(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    output reg [3:0] q // 4��Ʈ ���, �� ī������ ����
);

    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) 
            q = 4'b0001; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� q�� �ʱⰪ (0001)���� ����
        else begin
            if (q == 4'b1000)
                q = 4'b0001; // q�� 1000�̸� �ʱⰪ���� ���ư�
            else 
                q = {q[2:0], 1'b0}; // q�� �������� ����Ʈ�ϰ� ���� ������ ��Ʈ�� 0�� �߰�
        end
    end

endmodule
    
    
    
// �� ī���� 
module ring_counter_watch(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    output reg [2:0] q // 3��Ʈ ���, �� ī������ ����
);

    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) 
            q = 3'b001; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� q�� �ʱⰪ (0001)���� ����
        else begin
            if (q == 3'b100)
                q = 3'b001; // q�� 1000�̸� �ʱⰪ���� ���ư�
            else 
                q = {q[2:0], 1'b0}; // q�� �������� ����Ʈ�ϰ� ���� ������ ��Ʈ�� 0�� �߰�
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





// ���� ����� _ n(�ϰ�����)
//  cur �� old �� ��Ŭ�� �ӵ� ���̰� ���µ� �� ��¿����� �ϰ����� ������ 10ns���� �����ϴ¹��
module edge_detector_n(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    input cp,         // ���� ������ ���� Ŭ�� ��ȣ
    output p_edge,    // ��� ���� ���� ���
    output n_edge     // �ϰ� ���� ���� ���
);

    reg ff_cur, ff_old; // ����� ���� ���¸� �����ϴ� �ø��÷� ��������

    // �׻� ���: Ŭ���� �ϰ� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            ff_cur <= 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ff_cur�� 0���� ����
            ff_old <= 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ff_old�� 0���� ����
        end else begin
            ff_old <= ff_cur; // ���� ���¸� ���� ���·� ������Ʈ
            ff_cur <= cp;     // �Է� cp�� ���� ���·� ������Ʈ
        end
    end
    
    // ���� ���� ����: ff_cur�� 1�̰� ff_old�� 0�� ��
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    
    // ���� ���� ����: ff_cur�� 0�̰� ff_old�� 1�� ��
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;

endmodule


// ��ī����_fnd 
module ring_counter_fnd(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    output reg [3:0] q // 4��Ʈ ���, �� ī������ ����
);

    reg [16:0] clk_div; // Ŭ�� ���ֱ� ��������, Ŭ���� �����Ͽ� ī���� �ӵ��� ����
    // �׻� ���: Ŭ���� ��� �������� ����, Ŭ�� ���ֱ� ����
    always @(posedge clk) clk_div = clk_div + 1;
    
    wire clk_div_16_p; // ���ֵ� Ŭ���� ��� ���� ���� ��ȣ
    
    // ���� ����� ��� �ν��Ͻ�ȭ
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), // 17��° ��Ʈ�� Ŭ�� ���� ��ȣ�� �Է����� ���
        .p_edge(clk_div_16_p) // ��� ���� ���� ���
    );
    
    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin 
        if (reset_p) 
            q = 4'b1110; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� q�� �ʱⰪ���� ����
        else if (clk_div_16_p) begin // ���ֵ� Ŭ���� ��� �������� ����
            if (q == 4'b0111)
                q = 4'b1110; // ī���Ͱ� ��ȯ�Ͽ� �ʱⰪ���� ���ư�
            else 
                q = {q[2:0], 1'b1}; // q�� �������� ����Ʈ�ϰ� ���� ������ ��Ʈ�� 1�� �߰�
        end
    end

endmodule


// ��ī���� 16bit 
module ring_counter_16bit(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    output reg [15:0] q // 16��Ʈ ���, �� ī������ ����
);

    reg [21:0] clk_div; // Ŭ�� ���ֱ� ��������, Ŭ���� �����Ͽ� ī���� �ӵ��� ����
    // �׻� ���: Ŭ���� ��� �������� ����, Ŭ�� ���ֱ� ����
    always @(posedge clk) clk_div = clk_div + 1;
    
    wire clk_div_20_p; // ���ֵ� Ŭ���� ��� ���� ���� ��ȣ
    
    // ���� ����� ��� �ν��Ͻ�ȭ
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[21]), // 22��° ��Ʈ�� Ŭ�� ���� ��ȣ�� �Է����� ���
        .p_edge(clk_div_20_p) // ��� ���� ���� ���
    );
    
    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin 
        if (reset_p) 
            q = 16'b1111_1111_1111_1110; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� q�� �ʱⰪ���� ����
        else if (clk_div_20_p) begin // ���ֵ� Ŭ���� ��� �������� ����
            if (q == 16'b0111_1111_1111_1111)
                q = 16'b1111_1111_1111_1110; // ī���Ͱ� ��ȯ�Ͽ� �ʱⰪ���� ���ư�
            else 
                q = {q[14:0], 1'b1}; // q�� �������� ����Ʈ�ϰ� ���� ������ ��Ʈ�� 1�� �߰�
        end
    end

endmodule



// ��ī���� led
module ring_counter_le(
    input clk,        // Ŭ�� ��ȣ �Է�
    input reset_p,    // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    output reg [15:0] q // 16��Ʈ ���, LED�� �����ϴ� ī����
);

    reg [20:0] clk_div; // Ŭ�� ���ֱ� ��������, Ŭ���� �����Ͽ� ī���� �ӵ��� ����
    
    // �׻� ���: Ŭ���� ��� �������� ����, Ŭ�� ���ֱ� ����
    always @(posedge clk) clk_div = clk_div + 1;
    
    wire clk_div_20_p; // ���ֵ� Ŭ���� ��� ���� ���� ��ȣ
    
    // ���� ����� ��� �ν��Ͻ�ȭ
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_div[20]), // 21��° ��Ʈ�� Ŭ�� ���� ��ȣ�� �Է����� ���
        .p_edge(clk_div_20_p) // ��� ���� ���� ���
    );
    
    // �׻� ���: Ŭ���� ��� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(posedge clk or posedge reset_p) begin 
        if (reset_p) 
            q = 16'b0000_0000_0000_0001; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� q�� �ʱⰪ���� ����
        else if (clk_div_20_p) begin // ���ֵ� Ŭ���� ��� �������� ����
            if (q == 16'b1000_0000_0000_0000)
                q = 16'b0000_0000_0000_0001; // ī���Ͱ� ��ȯ�Ͽ� �ʱⰪ���� ���ư�
            else 
                q = {q[14:0], 1'b0}; // q�� �������� ����Ʈ�ϰ� ���� ������ ��Ʈ�� 0�� �߰�
        end
    end

endmodule


// ���� �����_��¿��� 
module edge_detector_p(
    input clk,         // Ŭ�� ��ȣ �Է�
    input reset_p,     // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    input cp,          // ������ ��ȣ �Է�
    output p_edge,     // ��� ���� ���� ���
    output n_edge      // �ϰ� ���� ���� ���
);
    
    // ���� �� ���� ��ȣ ���¸� ������ �ø��÷�
    reg ff_cur, ff_old;
    
    // �׻� ���: Ŭ���� �ϰ� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) begin
            ff_cur <= 0;   // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ���� ���¸� 0���� �ʱ�ȭ
            ff_old <= 0;   // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ���� ���¸� 0���� �ʱ�ȭ
        end else begin   
            ff_old <= ff_cur;  // ���� ���¸� ���� ���·� ����
            ff_cur <= cp;      // �Է� ��ȣ cp�� ���� ���·� ����
        end
    end
    
    // ��� ���� ����: ���� ���°� 1�̰� ���� ���°� 0�� �� (10) 1�� ���, �׷��� ������ 0�� ���
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    // �ϰ� ���� ����: ���� ���°� 0�̰� ���� ���°� 1�� �� (01) 1�� ���, �׷��� ������ 0�� ���
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
     
endmodule


// ����Ʈ �������� SISO
module shift_register_SISO_n(
    input clk,         // Ŭ�� ��ȣ �Է�
    input reset_p,     // �񵿱�� ���� ��ȣ �Է� (���� �������� Ȱ��ȭ)
    input d,           // ���� ������ �Է�
    output q           // ���� ������ ���
);

    // 4��Ʈ ����Ʈ �������� ����
    reg [3:0] siso_reg;
    
    // �׻� ���: Ŭ���� �ϰ� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            siso_reg <= 0;                   // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �������� �ʱ�ȭ
        else begin
            siso_reg[3] <= d;                // ���� �Է� d�� siso_reg�� ���� ���� ��Ʈ�� ����
            siso_reg[2] <= siso_reg[3];      // ���� ��Ʈ�� ���������� ����Ʈ
            siso_reg[1] <= siso_reg[2];      // ���� ��Ʈ�� ���������� ����Ʈ
            siso_reg[0] <= siso_reg[1];      // ���� ��Ʈ�� ���������� ����Ʈ
        end
    end
    
    // ���� ��� q: siso_reg�� ���� ���� ��Ʈ�� ���
    assign q = siso_reg[0];

endmodule
   
            
// ����Ʈ �������� SIPO           
module shift_register_SIPO_n(
    input clk,          // Ŭ�� ��ȣ �Է�
    input reset_p,      // �񵿱�� ���� ��ȣ �Է� (��� �������� Ȱ��ȭ)
    input d,            // ���� ������ �Է�
    input rd_en,        // �б� Ȱ��ȭ ��ȣ �Է�
    output [3:0] q      // ���� ������ ���
);

    // 4��Ʈ �������� ����, Shift Register�� �����ϴ� ����
    reg [3:0] sipo_reg;
    
    // �׻� ���: Ŭ���� �ϰ� ���� �Ǵ� ���� ��ȣ�� ��� �������� ����
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            sipo_reg = 0;                       // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �������� �ʱ�ȭ
        else 
            sipo_reg = {d, sipo_reg[3:1]};      // ���� �Է� d�� �������� ����Ʈ�ϰ� sipo_reg�� ����
    end
    
    // ���� ��� q: �б� Ȱ��ȭ ��ȣ�� 1�̸� �����Ǵ��� ���� ('z'), �׷��� ������ sipo_reg �� ���
    assign q = rd_en ? 4'bz : sipo_reg;
    
    // bufif0: �б� Ȱ��ȭ ��ȣ�� ���� ��� ���۸� ����Ͽ� ���� ��� ����
    // (�Խ��� ó���ؼ� �Ⱦ� )bufif0 (q[0], sipo_reg[0], rd_en);  // q[0]: ���, sipo_reg[0]: �Է�, rd_en: �ο��̺� ��ȣ
    

    
endmodule
    
// ����Ʈ �������� PISO            
module shift_register_PISO(
    input clk,       // Ŭ�� �Է�
    input reset_p,   // ���� �Է�
    input [3:0] d,   // ���� ������ �Է�
    input shift_load, // ����Ʈ �ε� ��ȣ �Է�
    output q         // �ø��� ��� ��Ʈ
);

    reg [3:0] piso_reg; // PISO �������� ����

    // Ŭ���� ���� ��ȣ�� ���� ������ �����ϴ� always ���
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) // ���� ��ȣ�� Ȱ��ȭ�Ǹ�
            piso_reg = 4'b0000; // �������͸� 0���� �ʱ�ȭ
        else begin
            if (shift_load) // shift_load ��ȣ�� Ȱ��ȭ�Ǹ�
                piso_reg = {1'b0, piso_reg[3:1]}; // PISO �������͸� �������� ����Ʈ
            else
                piso_reg = d; // �׷��� ������ �Է� d ���� PISO �������Ϳ� �ε�
        end
    end

    assign q = piso_reg[0]; // ��� q�� PISO ���������� ������ ��Ʈ

endmodule           



// N bit ��������
module register_Nbit_n #(parameter N = 8) (
    input [N-1:0] d,         // ������ �Է� (N��Ʈ)
    input clk,               // Ŭ�� �Է�
    input reset_p,           // �񵿱� ���� �Է� (��Ƽ�� ����)
    inout wr_en, rd_en,      // ���������� ����/�б� ���� ���� (�Է�)
    output [N-1: 0] q        // �������� ��� (N��Ʈ)
);
    
    reg [N-1 : 0] register;  // N��Ʈ �������� ����
    
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            register = 0;     // ���� ��ȣ�� Ȱ��ȭ�Ǹ� �������͸� 0���� �ʱ�ȭ
        else if (wr_en) 
            register = d;     // ���� ���� ��ȣ�� Ȱ��ȭ�Ǹ� �����͸� �������Ϳ� ����
    end
    
    assign q = rd_en ? register : 'bz;  // �б� ���� ��ȣ�� Ȱ��ȭ�Ǹ� �������� ���� ���(q), �׷��� ������ 'bz ���

endmodule


// s��_8bit 
module sram_8bit_1024(
    input clk,            // Ŭ�� �Է�
    input wr_en, rd_en,   // ����/�б� ���� ���� �Է�
    input [9:0] addr,     // �޸� �ּ� �Է� (10��Ʈ)
    inout [7:0] data      // ������ ����� (8��Ʈ)
);

    reg [7:0] mem [0:1023];  // 8��Ʈ �޸� �迭 ���� (1024���� ���)

    always @(posedge clk) begin
        if (wr_en)              // ���� ���� ��ȣ�� Ȱ��ȭ�Ǹ�
            mem[addr] = data;   // �־��� �ּҿ� �����͸� �޸𸮿� ���ϴ�.
    end
    
    assign data = rd_en ? mem[addr] : 'bz;  // �б� ���� ��ȣ�� Ȱ��ȭ�Ǹ� �־��� �ּ��� �޸� ���� �����ͷ� ���(data), �׷��� ������ 'bz ���

endmodule




