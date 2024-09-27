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

// 10 ���ֱ� 
module clock_div_10(
    input clk,                       // �Է� Ŭ�� ��ȣ
    input reset_p,               // �񵿱� ���� ��ȣ (active high)
    input clk_source,         // ������ ���� Ŭ�� ��ȣ
    
    output cp_div_10_nedge  // ���ֵ� Ŭ�� ��ȣ�� �װ�Ƽ�� ���� ���
);
    
    wire nedge_source, cp_div_10;

    // ���� Ŭ�� ��ȣ(clk_source)�� �װ�Ƽ�� ������ ����
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_source), 
        .n_edge(nedge_source)
    ); 
                    
    reg [3:0] cnt_clk_source;  // 4��Ʈ ī���� �������� (0���� 9���� ��)

    // Ŭ���� �װ�Ƽ�� ���� �Ǵ� ���� ��ȣ���� �����ϴ� always ���
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_clk_source <= 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ī���͸� 0���� �ʱ�ȭ
        else if(nedge_source) begin
            if (cnt_clk_source >= 9) 
                cnt_clk_source <= 0; // ī���� ���� 9 �̻��̸� 0���� ����
            else 
                cnt_clk_source <= cnt_clk_source + 1; // �׷��� ������ ī���͸� 1�� ����
        end
    end

    // cnt_clk_source ���� ������� cp_div_10 ��ȣ ����
    // cnt_clk_source�� 9�� �� cp_div_10�� 1, �׷��� ������ 0
    assign cp_div_10 = (cnt_clk_source < 9) ? 0 : 1;

    // cp_div_10 ��ȣ�� �װ�Ƽ�� ������ �����Ͽ� cp_div_10_nedge ��ȣ ����
    // �̴� 1���� 0������ ��ȯ�� �����Ͽ� ������ �ּ�ȭ��
    edge_detector_n ed10(
        .clk(clk), .reset_p(reset_p), .cp(cp_div_10), 
        .n_edge(cp_div_10_nedge)
    ); 
 
endmodule



//100���ֱ� 
module clock_div_100(
    input clk,           // �Է� Ŭ�� ��ȣ
    input reset_p,       // �񵿱� ���� ��ȣ (active high)
    output clk_div_100,  // �ٸ� ���ֱ�� �ٸ��� wire ������ ���� ���ؼ� ����
    output cp_div_100    // 100���ֵ� Ŭ�� ��ȣ
);
    
    reg [6:0] cnt_sysclk;  // 7��Ʈ ī���� �������� (0���� 99���� ��)
    
    // Ŭ���� �װ�Ƽ�� ���� �Ǵ� ���� ��ȣ���� �����ϴ� always ���
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_sysclk = 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ī���͸� 0���� �ʱ�ȭ
        else begin
            if (cnt_sysclk >= 99) 
                cnt_sysclk = 0; // ī���� ���� 99 �̻��̸� 0���� ���� (== ���� >= �� �� ������)
            else 
                cnt_sysclk = cnt_sysclk + 1; // �׷��� ������ ī���͸� 1�� ����
        end
    end
   
    // cnt_sysclk ���� ������� cp_div_100 ��ȣ ����
    // cnt_sysclk�� 0���� 99 ������ �� cp_div_100�� 0, 99���� 0(�ʱ�ȭ)  ������ �� cp_div_100�� 1
    assign cp_div_100 = (cnt_sysclk < 99) ? 0 : 1;
     
    // cp_div_100 ��ȣ�� �װ�Ƽ�� ������ �����Ͽ� clk_div_100 ��ȣ ����
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(cp_div_100), 
        .n_edge(clk_div_100)
    ); 
    
endmodule



// 1000���� �ٲ��� �ð��� ĸ�� 
module clock_div_1000(
    input clk,          // �Է� Ŭ�� ��ȣ
    input reset_p,      // �񵿱� ���� ��ȣ (active high)
    input clk_source,   // ������ ���� Ŭ�� ��ȣ
    
    output cp_div_1000_nedge      // ���ֵ� Ŭ�� ��ȣ ���
);
    
    wire nedge_source, cp_div_1000;
    
    // ���� Ŭ�� ��ȣ�� �װ�Ƽ�� ������ �����Ͽ� nedge_source ��ȣ ����
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_source), 
        .n_edge(nedge_source)
    ); 
    
    reg [9:0] cnt_clk_source;  // 10��Ʈ ī���� �������� (0���� 999���� ��)

    // Ŭ���� �װ�Ƽ�� ���� �Ǵ� ���� ��ȣ���� �����ϴ� always ���
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_clk_source = 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ī���͸� 0���� �ʱ�ȭ
        else if (nedge_source) begin
            if (cnt_clk_source >= 999) 
                cnt_clk_source = 0; // ī���� ���� 999 �̻��̸� 0���� ����
            else 
                cnt_clk_source = cnt_clk_source + 1; // �׷��� ������ ī���͸� 1�� ����
        end
    end

    // cnt_clk_source ���� ������� cp_div_1000 ��ȣ ����
    assign cp_div_1000 = (cnt_clk_source < 999) ? 0 : 1;
    // cnt_clk_source 0���� 999 ������ �� cp_div_1000�� 0, 999���� 0(�ʱ�ȭ) ������ �� cp_div_1000�� 1
    
    // cp_div_1000 ��ȣ�� �װ�Ƽ�� ������ �����Ͽ� cp_div_1000_nedge ��ȣ ����
    edge_detector_n ed1000(
        .clk(clk), .reset_p(reset_p), .cp(cp_div_1000), 
        .n_edge(cp_div_1000_nedge)
    ); 
    
endmodule


// Ÿ�̸� ���� 60���ֱ� (sec,min)
module clock_div_60(
    input clk,          // �Է� Ŭ�� ��ȣ
    input reset_p,      // �񵿱� ���� ��ȣ (active high)
    input clk_source, 
    
    output cp_div_60_nedge      // ���ֵ� Ŭ�� ��ȣ ���
);
    
    wire nedge_source, cp_div_60;
     edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(clk_source), 
                    .n_edge(nedge_source)); 
                    
    integer cnt_clk_source;  //  integer - 32bit (but ����ȭ  �Ǽ� 6��Ʈ��(0~64) ����) 

    // Ŭ�� ��� ���� �Ǵ� ���� ��ȣ���� �����ϴ� always ���
    always @(negedge clk or posedge reset_p) begin
        if (reset_p) 
            cnt_clk_source = 0; // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ī���͸� 0���� �ʱ�ȭ
        else if(nedge_source) begin
            if (cnt_clk_source >= 59) 
                cnt_clk_source = 0; // ī���� ���� 999 �̻��̸� 0���� ����
            else 
                cnt_clk_source = cnt_clk_source + 1; // �׷��� ������ ī���͸� 1�� ����
        end
    end

    // cnt_clk_source ���� ������� cp_usec ��ȣ ����
    assign cp_div_60 = (cnt_clk_source < 59) ? 0 : 1;
    // cnt_clk_source 0���� 59 ������ �� cp_usec�� 59���� 00 ������ �� cp_usec�� 1
    
     edge_detector_n ed60(
                    .clk(clk), .reset_p(reset_p), .cp(cp_div_60), 
                    .n_edge(cp_div_60_nedge)); 

endmodule




// 60�� ī���� �ð� �����  (segment ǥ�ÿ� )
module counter_bcd_60(
        input clk, reset_p,
        input clk_time,
        output reg [3:0] bcd1, bcd10);  // 4��Ʈ ��  bcd1,bcd10 

         wire nedge_source;
         
         edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(clk_time), 
                    .n_edge(nedge_source)); 

         always @(posedge clk or posedge reset_p)begin          // ��¿���  Ȥ�� ���½�ȣ�϶� 
                if(reset_p)begin                // bcd1,bcd10 - 0���� �ʱ�ȭ 
                        bcd1 = 0;
                        bcd10 = 0; 
                end
                else if (nedge_source) begin  
                       if(bcd1 >= 9) begin                  // bcd1 ��, 1���ڸ��� 9 �̻� �϶� 0���� �ʱ�ȭ 
                            bcd1 = 0;
                            if(bcd10 >= 5)bcd10 = 0;    // bcd10 ��, 10�ڸ��� 5 �̻��϶� 0���� �ʱ�ȭ  
                            else bcd10 = bcd10 + 1;     // 10���ڸ� 1�߰� 
                end 
                else  bcd1 <= bcd1 + 1;                   // 1���ڸ� 1�߰�
          end
    end

endmodule


// 100�� ī���� �ð� �����  ( sec : msec Ÿ�̸� ���鶧 msec ��)
module counter_bcd_100(
        input clk, reset_p,
        input clk_time,
        output reg [6:0] bcd1, bcd10);

         wire nedge_source;
         
         edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(clk_time), 
                    .n_edge(nedge_source)); 

         always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin            //  ���� ��ȣ �� 0���� �ʱ�ȭ 
                        bcd1 = 0;
                        bcd10 = 0; 
                end
                else if (nedge_source) begin
                       if(bcd1 >= 9) begin          // bcd 1���ڸ� 9�̻��Ͻ� 0���� �ʱ�ȭ
                            bcd1 = 0;
                            if(bcd10 >= 9)bcd10 = 0;        // bcd 10���ڸ� 9�̻��Ͻ� 0���� �ʱ�ȭ
                            else bcd10 = bcd10 + 1;         // bcd 10���ڸ� 1�� ī��Ʈ
                end
                else bcd1 <= bcd1 + 1;                       // bcd 1���ڸ� 1�� ī��Ʈ
          end
    end

endmodule



module loadable_counter_bcd_60(
    input clk, reset_p,           // Ŭ�� �� �񵿱� ���� ��ȣ
    input clk_time,               // ī���� Ŭ�� ��ȣ
    input load_enable,            // �ε� ������ ��ȣ
    input [3:0] load_bcd1, load_bcd10,  // �ε��� BCD ���� (1�� �ڸ� �� 10�� �ڸ�)
    output reg [3:0] bcd1, bcd10       // BCD ��� (1�� �ڸ� �� 10�� �ڸ�)
);

    wire nedge_source;
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(clk_time), 
        .n_edge(nedge_source)
    ); 

    // �񵿱� ���� ��ȣ �Ǵ� Ŭ���� ��� �������� �����ϴ� always ���
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            // ���� ��ȣ�� Ȱ��ȭ�Ǹ� BCD ī���͸� 0���� �ʱ�ȭ
            bcd1 <= 0;
            bcd10 <= 0; 
        end
        else begin
            if (load_enable) begin
                // �ε� ������ ��ȣ�� Ȱ��ȭ�Ǹ� �Էµ� BCD ���� �ε�
                bcd1 <= load_bcd1;
                bcd10 <= load_bcd10;
            end
            else if (nedge_source) begin
                // Ŭ���� �װ�Ƽ�� �������� ī���͸� ������Ŵ
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
    input clk, reset_p,           // Ŭ�� �� �񵿱� ���� ��ȣ
    input clk_time,               // ī���� Ŭ�� ��ȣ
    input load_enable,            // �ε� ������ ��ȣ
    input [3:0] load_bcd1, load_bcd10,  // �ε��� BCD ���� (1�� �ڸ� �� 10�� �ڸ�)
    output reg [3:0] bcd1, bcd10,       // BCD ��� (1�� �ڸ� �� 10�� �ڸ�)
    output reg dec_clk
);



        // �񵿱� ���� ��ȣ �Ǵ� Ŭ���� ��� �������� �����ϴ� always ���
       always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            // ���� ��ȣ�� Ȱ��ȭ�Ǹ� BCD ī���͸� 0���� �ʱ�ȭ
            bcd1 = 0;        // 1�� �ڸ��� 0���� �ʱ�ȭ
            bcd10 = 0;       // 10�� �ڸ��� 0���� �ʱ�ȭ
            dec_clk = 0;     // ���� Ŭ�� ��ȣ�� 0���� �ʱ�ȭ
        end
        else begin
            if (load_enable) begin
                // �ε� �̳��̺� ��ȣ�� Ȱ��ȭ�Ǹ� �Էµ� BCD ���� �ε�
                bcd1 = load_bcd1;     // �Էµ� 1�� �ڸ� ���� �ε�
                bcd10 = load_bcd10;   // �Էµ� 10�� �ڸ� ���� �ε�
            end
            else if (clk_time) begin
                // clk_time ��ȣ�� Ȱ��ȭ�� �� (1�ʸ���)
                
                if (bcd1 == 0) begin
                    // 1�� �ڸ��� 0�̸� 9�� ����
                    bcd1 = 9;
                    
                    if (bcd10 == 0) begin
                        // 10�� �ڸ��� 0�̸� 59�ʿ��� 58�ʷ� �����ϴ� ����
                        // ���� �ڸ� ���� ��ȣ�� 1�� ����
                        dec_clk = 1;
                        // 10�� �ڸ��� 5�� ���� (ex: 01:00 -> 00:59)
                        bcd10 = 5;
                    end
                    else begin
                        // 10�� �ڸ��� 0�� �ƴϸ� 1 ����
                        bcd10 = bcd10 - 1;
                    end
                end
                else begin
                    // 1�� �ڸ��� 0�� �ƴϸ� 1 ����
                    bcd1 = bcd1 - 1;
                end
            end
            else begin
                // clk_time ��ȣ�� ��Ȱ��ȭ�Ǹ� dec_clk�� 0���� ����
                dec_clk = 0;
            end
        end
    end
    
endmodule
    



// 58 ���ֱ� 
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





