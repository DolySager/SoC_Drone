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
    input clk,              // �Է�: Ŭ��
    input reset_p,          // �Է�: �񵿱� ����
    input [15:0] value,     // �Է�: 16��Ʈ ��
    output [7:0] seg_7, // ���: 7���׸�Ʈ ��ȣ
    output [3:0] com    // ���: Ŀ�� ��ȣ
);
    
    // ring_counter_fnd ��� �ν��Ͻ�ȭ
    ring_counter_fnd rc(
        .clk(clk),
        .reset_p(reset_p),
        .q(com)
    );
    
    reg [3:0] hex_value;     // 4��Ʈ ���� ����� �������� ����
    
    // decoder_7seg ��� �ν��Ͻ�ȭ
    decoder_7seg dec(
        .hex_value(hex_value),
        .seg_7(seg_7)
    );
    
    // Ŭ���� �缺 ������ ���� always ���
    always @(posedge clk) begin
        // Ŀ�� ��ȣ�� ���� value ���� 4��Ʈ ������ �Ҵ�
        case(com)
            4'b1110 : hex_value = value[3:0];
            4'b1101 : hex_value = value[7:4];
            4'b1011 : hex_value = value[11:8];
            4'b0111 : hex_value = value[15:12];
        endcase
    end

endmodule



module button_cntr(
    input clk, reset_p,        // �Է� Ŭ�� �� �񵿱� ���� ��ȣ
    input btn,                 // �Է� ��ư ��ȣ
    output btn_pedge, btn_nedge // ��� ��ư�� ��ؼ� ���� ��ȣ
);

    reg [16:0] clk_div;        // 17��Ʈ Ŭ�� ���ֱ� ��������
    always @(posedge clk) clk_div = clk_div + 1;  // Ŭ�� ���ֱ� ī���� ������Ʈ

    wire clk_div_16_pedge;     // Ŭ�� ���ֱ� 16��° ��Ʈ�� ��ؼ� ���� ��ȣ
    edge_detector_n ed_div(    // Ŭ�� ���ֱ��� ��ؼ� ���� ������ �ν��Ͻ�
        .clk(clk), .reset_p(reset_p), 
        .cp(clk_div[16]), .p_edge(clk_div_16_pedge)
    );    

    reg debounced_btn;         // ��ٿ�� ��ư ��ȣ ��������
    always @(posedge clk or posedge reset_p) begin
        if (reset_p)
            debounced_btn = 0;  // ���� ��ȣ�� Ȱ��ȭ�Ǹ� ��ٿ�� ��ư ��ȣ �ʱ�ȭ
        else if (clk_div_16_pedge)
            debounced_btn = btn;  // Ŭ�� ���ֱ��� 16��° ��Ʈ�� ��ؼ� �������� ��ư ���� ����
    end

    edge_detector_n ed(        // ��ư�� ��ؼ� ���� ������ �ν��Ͻ�
        .clk(clk), .reset_p(reset_p), .cp(debounced_btn), 
        .p_edge(btn_pedge), .n_edge(btn_nedge)
    );            

endmodule




module led_test_top(
    input clk,              // �Է�: Ŭ��
    input reset_p,          // �Է�: �񵿱� ����
    output [15:0] q         // ���: 16��Ʈ ��� q
);

    ring_counter_led rc(clk, reset_p, q);  // ring_counter_led ��� �ν��Ͻ�ȭ

endmodule



module keypad_cntr_FSM(
        input clk, reset_p,
        input [3:0] row,
        output reg [3:0] col,
        output reg [3:0] key_value,
        output reg key_valid );     // Ű�Է½� key_valid = 1, �ƴҽ� 0
        
        // Ű�е��� �� ��(col)�� ��ĵ�ϴ� ����      *row�� �� 
       parameter SCAN_0             = 5'b00001;
       parameter SCAN_1             = 5'b00010;
       parameter SCAN_2             = 5'b00100;
       parameter SCAN_3             = 5'b01000;
       parameter KEY_PROCESS  = 5'b10000;
       
       reg [4:0] state, next_state;
       
       // ���� ���� ���� : row���� 0�̸� ���� ��ĵ���� �Ѿ , 1�̸� key_process�� ����
       // ���� (col,row) - 8'b0100 0010 �Ͻ� scan_1���� row�� 0 �̾ �н�
       // scan_2 �϶�  8'b0100 0010 row ���� 1�� �����Ƿ� key_process�� �̵�
       
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
        
       // ���� ���� ������Ʈ  
       always @(posedge clk or posedge reset_p)begin
                 if(reset_p)state = SCAN_0;
                 else if(clk_8msec_p)state = next_state;
       end
        
        // Ŭ�� ����(�����Ͽ� 8�и��� �ֱ� ���� ) �� ���� ����(Ŭ����ȣ�� ��ؼ� ����)
        reg [19:0] clk_div;
        always @(posedge clk)clk_div = clk_div + 1;
        
       
        edge_detector_n ed(        // ��ư�� ��ؼ� ���� ������ �ν��Ͻ�
                .clk(clk), .reset_p(reset_p), .cp(clk_div[19]), 
                .n_edge(clk_8msec_n), .p_edge(clk_8msec_p));

        // ��ī���� 
        always @(posedge clk or posedge reset_p)begin
                if(reset_p) begin           // ���½� �ʱ�ȭ
                        col = 4'b0001;
                        key_value = 0;
                        key_valid  = 0;
                end        
                else if(clk_8msec_n)begin   // 8�и��� �ֱ��� Ŭ����ȣ �ϰ��������� ���� 
                      case(state) //  ���¿� ���� ��(col)�� ����
                                SCAN_0 : begin col = 4'b0001; key_valid = 0; end
                                SCAN_1 : begin col = 4'b0010; key_valid = 0; end
                                SCAN_2 : begin col = 4'b0100; key_valid = 0; end
                                SCAN_3 : begin col = 4'b1000; key_valid = 0; end
                                KEY_PROCESS : begin     // row = 1 �Ͻ� �׿��� key process�� �̵��Ͽ�  key_value �� ���
                                      key_valid = 1;            // Ű �Է½� 1
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
           inout dht11_data,     // input ,output �Ѵ� ��밡��  ,�½��� ���� ������
           output reg [7:0] humidity, temperature,          // �µ�,���� 8��Ʈ�� 
           output [15:0] led );    
           
           parameter S_IDLE                = 6'b00_0001;        // ��� ���� (�ʱ���¿��� 3�� ��ٸ� �� �������� ��ȯ)
           parameter S_LOW_18MS    = 6'b00_0010;        // 18ms ���� low���� ���� �� ���� ���·� ��ȯ
           parameter S_HIGH_20US    = 6'b00_0100;        // 20us ���� high���� �����ϰ� dht_nedge ��ȣ ��� , �����Ǹ� 20us���� ��ȯ
           parameter S_LOW_80US     = 6'b00_1000;       // 80us ���� low���� �����ϰ� dht_pedge ��ȣ ��� , �����Ǹ� ���� ���·�  ��ȯ
           parameter S_HIGH_80US     = 6'b01_0000;      // 80us ���� high���� �����ϰ� dht_nedge ��ȣ ��� , �����Ǹ� �������·� ��ȯ
           
           // ������ ��Ʈ�� �����ϰ�, ���ŵ� �����͸� ó��
           // ���� ����: S_WAIT_PEDGE�� S_WAIT_NEDGE�� �б�
           //������ ������ �Ϸ�Ǹ� data_count�� 40�� �Ǿ� humidity�� temperature �����͸� �����ϰ� S_IDLE ���·� ��ȯ
           parameter S_READ_DATA    = 6'b10_0000;      
           
           parameter S_WAIT_PEDGE  = 2'b01;     // dht_pedge�� �����Ǹ� S_WAIT_NEDGE ���·� ��ȯ
           parameter S_WAIT_NEDGE  = 2'b10;   // dht_nedge�� �����Ǹ� ���� ������ ��Ʈ�� ó���ϰų� ������ ������ �Ϸ�� �� S_READ_DATA ���·� ��ȯ
        
            reg [21:0] count_usec;                   // 3��  - 3,000,000 us - 22��Ʈ  
            wire clk_usec;
            reg count_usec_e;                           // Ŭ���ֱ� ���� Ȱ��ȭ ���� ��ȣ  (MCU ��ȣ ���� �� ����)
            
            // 10ns �⺻Ŭ���� 100���ַ� 1us ��� 
            clock_div_100 us_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
            
            
            // Ȱ��ȭ�� ����ũ�μ�ũ 1�� ī��Ʈ 
            always @(negedge clk or posedge reset_p)begin
                    if(reset_p)count_usec = 0;                  // ���½� count_usec 0 �ʱ�ȭ
                    else if(clk_usec && count_usec_e)count_usec = count_usec + 1;       // clk_usec�� count_usec_e �� Ȱ��ȭ �����϶� ī��Ʈ ���� 
                    else if(count_usec_e == 0)count_usec = 0;       // ���� count_usec_e ��Ȱ��ȭ �����̸� 0���� �缳��
            end  
            
            
            wire dht_nedge, dht_pedge;
            
             // Ŭ�� ��� ���� �� �϶� ���� ���� ���
            edge_detector_p ed(       
            .clk(clk), .reset_p(reset_p), .cp(dht11_data),
            .n_edge(dht_nedge), .p_edge(dht_pedge));         
           
            // FSM ���� ��������
            reg [5:0] state, next_state;
            reg [1:0] read_state;
            
            
               // ���½� ���� �ʱ�ȭ �� �����ܰ�
                always @(negedge clk or posedge reset_p) begin
                    if (reset_p)
                        state = S_IDLE;  // ���� ������ ���, ���¸� S_IDLE�� �ʱ�ȭ
                    else
                        state = next_state;  // �� ���� ���, ���� ���¸� ���� ���·� ������Ʈ
                end
                
                assign led[5:0] = state;
                
                // DHT11 �������� ���ŵ� �����͸� �����ϴ� ��������
                reg [39:0] temp_data;  // 40��Ʈ ũ���� �������ͷ�, �µ��� ������ ���� ����
                reg [5:0] data_count;  // ������ ���� ī����, �� ��° ���������� ī��Ʈ
                reg dht11_buffer;     // DHT11 ���� �����͸� �ӽ÷� �����ϴ� ����
                
                // dht11_data ��ȣ�� dht11_buffer�� ���� �����Ͽ� ������ ������ ����� �����ϰ� ��
                assign dht11_data = dht11_buffer;
            
            
                        // ���� �� �ʱ�ȭ 
                        always @(negedge clk or posedge reset_p) begin
                                    if (reset_p) begin          // ���� ����
                                             count_usec_e = 0;             // Ŭ�� �ֱ� ���� Ȱ��ȭ ���� ��ȣ�� 0���� ��Ȱ��ȭ(�ʱ�ȭ)
                                             next_state = S_IDLE;          // ���� ���¸� IDLE(���)���·� ����
                                             read_state = S_WAIT_PEDGE;    // ������ �б� ���� �ʱ�ȭ (���� ���¸� PEDGE ���� ��ȣ�� ��ٸ��� ���·� ����)
                                             data_count = 0;               // ������ ��Ʈ ī���� �ʱ�ȭ
                                             dht11_buffer = 'bz;           // DHT11 ���� �ʱ�ȭ (���� ���Ǵ��� - �ٸ� ȸ�ο� ���� ������ ����� �����ǰų� ������ ���� �ʵ��� �ϱ� ���� ��ȣ ��ġ) 
                                     end
                                    else begin
                       
                       
                       //if (count_usec < Ŭ�� �ֱ�) - Ŭ���ֱ� �̸��Ͻ� mcu ��ȣ�� �����ϴ°���  ���� (���� ���� ������ )
                            case(state)    
                                S_IDLE : begin  // IDLE ����: MCU�� DHT11���� ����� �����ϱ� �� ��� ����
                                    if(count_usec < 22'd3_000_000) begin // ������ 3��   // Ŭ���ֱⰡ 3�� �̸��Ͻ�  (������)
                                        count_usec_e = 1;                  // Ŭ�� �ֱ� ���� Ȱ��ȭ (Ȱ��ȭ�� MCu��ȣ ������)
                                        dht11_buffer = 'bz;                // ���۸� ���� ���Ǵ����� ����
                                    end
                                    else begin                                      // 3�� �ʰ��Ͻ� (��ȣ ������)
                                        next_state = S_LOW_18MS;           // ���� ������ LOW ���·� ��ȯ
                                        count_usec_e = 0;                  // ī���� ��Ȱ��ȭ (MCU��ȣ ���� �ؼ�)
                                    end
                                end
                                
                                S_LOW_18MS : begin  // MCU�� DHT11�� ���� ��ȣ�� ���� (������ ���� �������� 18ms ����)
                                    if(count_usec < 22'd18_000) begin   // 18ms �̸��Ͻ� = mcu ��ȣ ���� �� (MCU ��ȣ�� �ּ� 18ms ���� �ϸ�, )
                                        dht11_buffer = 0;                  // ���۸� ���� �������� ����
                                        count_usec_e = 1;                  // ����ũ���� ī���� Ȱ��ȭ (Ȱ��ȭ�� MCU ��ȣ ������)
                                    end
                                    else begin
                                        next_state = S_HIGH_20US;          // 18ms ��(���� ��) HIGH ���·� ��ȯ
                                        count_usec_e = 0;                  // ī���� ��Ȱ��ȭ
                                        dht11_buffer = 'bz;                // ������ ���� ���Ǵ����� ����
                                    end
                                end
                                S_HIGH_20US : begin
                                        count_usec_e = 1;
                                        if(count_usec > 22'd100_000)begin
                                            next_state = S_IDLE;       // LOW 80us ���·� ��ȯ
                                            count_usec_e = 0;              // ī���� ��Ȱ��ȭ
                                        end
                                        if(dht_nedge)begin
                                            next_state = S_LOW_80US;       // LOW 80us ���·� ��ȯ
                                            count_usec_e = 0;      
                                         end
                                  end       
                                S_LOW_80US : begin
                                    // DHT11�� ���� ��ȣ (LOW 80us)
                                    if(dht_pedge) begin
                                        next_state = S_HIGH_80US;          // HIGH 80us ���·� ��ȯ
                                    end
                                end
                                S_HIGH_80US : begin
                                    // DHT11�� ������ ���� �غ� ��ȣ (HIGH 80us)
                                    if(dht_nedge) begin
                                        next_state = S_READ_DATA;          // ������ �б� ���·� ��ȯ
                                    end
                                end
                                S_READ_DATA : begin
                                    // DHT11�κ��� ������ �б�
                                    case(read_state)
                                        S_WAIT_PEDGE : begin
                                            if(dht_pedge) read_state = S_WAIT_NEDGE;  // ��� ���� ���� �� ���� ���·� ��ȯ
                                            count_usec_e = 0;                         // ī���� ��Ȱ��ȭ
                                        end
                                        S_WAIT_NEDGE : begin
                                            if(dht_nedge) begin                      // �ϰ� ���� ����
                                                if(count_usec < 45) begin            // LOW ��ȣ�� 45us �̸��̸�
                                                    temp_data = {temp_data[38:0], 1'b0};  // ��Ʈ '0' ����
                                                end 
                                                else begin
                                                    temp_data = {temp_data[38:0], 1'b1};  // ��Ʈ '1' ����
                                                end
                                                data_count = data_count + 1;          // ������ ��Ʈ ī���� ����
                                                read_state = S_WAIT_PEDGE;            // ���� ��Ʈ�� ���� ���� ��ȯ
                                            end
                                            else count_usec_e = 1;                    // ī���� Ȱ��ȭ
                                            if(count_usec > 22'd700_000)begin
                                                   next_state = S_IDLE;
                                                   count_usec_e = 0;
                                                   data_count=0;
                                                   read_state = S_WAIT_PEDGE; 
                                            end
                                        end         
                                    endcase                                   
                                if(data_count >= 40) begin
                                    // 40��Ʈ �����͸� ��� �о�����
                                    data_count = 0;                           // ������ ��Ʈ ī���� �ʱ�ȭ
                                    next_state = S_IDLE;                      // IDLE ���·� ��ȯ
                                    if((temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8]) == temp_data[7:0])begin
                                            humidity = temp_data[39:32];              // ���� ������ ����
                                            temperature = temp_data[23:16];           // �µ� ������ ����
                                end
                        end     
                    end
                    default : next_state = S_IDLE;                    // �⺻ ���´� IDLE
                endcase                                 
            end                        
        end
                       
endmodule

/* dht11 �����ͽ�Ʈ ����

5.1 ��ü ��� ���μ���

MCU�� ���� ��ȣ�� ����.
DHT11�� ������ ��忡�� �۵� ���� ��ȯ.
DHT11�� 40��Ʈ ������ ���� ��ȣ�� MCU�� ����.
������ ���� �� DHT11�� ������ ���� ��ȯ.

5.2 MCU�� DHT�� ���� ��ȣ�� �����ϴ�

������ ������ ������ ����.
MCU�� ������ ������ ���� �������� �ּ� 18ms ����.
MCU�� ������ ���̰� 20-40us ���� ���.

5.3 DHT�� MCU�� ���� ����

DHT�� ���� ��ȣ�� �����ϸ�, 80us ���� ���� ��ȣ ����.
DHT�� ������ ���� �غ� ���� 80us ���� ���� ��ȣ ����.
��� ������ ��Ʈ�� 50us ���� ���� ��ȣ�� �����ϰ�, ���� ��ȣ�� ���̷� 0 �Ǵ� 1�� ����.

*/

        // ����ȸ���� �Է� -> ��� ������ �ð� pdt�� ���� 
                // pdt�� 10ns���� �������
                // 10ns pdt�� ������ ����ε� ��°��� ��������
                //  -���Ͻ� pdt �� ������ * ���������� 
                // �̸������ϱ����� Ŭ���ֱ⸦ �ø��µ� ��� �ӵ��� ���ϵ�  
                // wns - worst �װ�Ƽ�� ���� 
                


// ������ ���� ��Ʈ�ѷ�
module ultrasound_cntr(
            input clk, reset_p,
            input echo,                                 // ���� �Է� (�������� ���,�ϰ������� �Է����� �޾� ���� ����)
            output reg trig,                          // Ʈ���� ��� (Ʈ������ ��°��� �������� �޾� ����)
            output reg [15:0] distance,      // �Ÿ� ��Ʈ
            output [7:0] led
);


/*      0. ��� ���� idle 
        1. HC-SR04 Trig Pin�� �ּ��� 10 us�� Ʈ���� �޽��� �����ؾ� �մϴ�.
        2. �׷� ���� HC-SR04�� �ڵ����� 40 kHz�� ���� 8���� ������ Echo �ɿ��� ��� ���� ����� ��ٸ��ϴ�.
        3. ���� �ɿ��� ��� ���� ĸó�� �߻��ϸ� Ÿ�̸Ӹ� �����ϰ� ���� �ɿ��� �ϰ� ������ ��ٸ��ϴ�.
        4. Echo �ɿ��� �ϰ� ������ ĸó�Ǹ� ��� Ÿ�̸��� ī��Ʈ�� �н��ϴ�.*/
        
            parameter S_IDLE        =5'b00001;
            parameter S_10US       =5'b00010;
            parameter S_40KHZ    = 5'b00100;
            parameter S_TIMER     = 5'b01000;
            parameter S_READ      = 5'b10000;


            wire clk_usec;                              // ����ũ��sec Ŭ�� 
            wire uls_nedge, uls_pedge;      // �ϰ�, ��¿���
            
            reg count_usec_e;                           // ����ũ�� sec ī��Ʈ Ȱ��ȭ ����
            reg [19:0] count_usec;                   // ����ũ�� sec ī��Ʈ 
            reg [4:0] state, next_state;            // ������� ,��������

            assign led[5:0] = state;                // �� ���¸��� led ���� 
            
            
            // �⺻Ŭ�� 10ns �� 100���ֱ⸦ ���ؼ� 1us ����
            clock_div_100 us_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
   
      
/* 58 ���ֱ⸦ ����Ͽ�  worst negative slack ���� 
            reg cnt_e;
            wire [11:0] cm;
      
            sr_04_div_58 clk_cm(
            .clk(clk), .reset_p(reset_p), .clk_usec(clk_usec),
            .cnt_e(cnt_e), .cm(cm));
*/

            
            // ����ũ�� sec = 1 && ����ũ�� ī���� (e - enable) Ȱ��ȭ �� = ī��Ʈ ���� 
            // (��, Ȱ��ȭ ���ִ� ���� Ŭ�� 1�� Ƚ�� ��  -> ������ �Ÿ����ϴ°���, 10 us�̻� ī��Ʈ ��  �ʿ� )  
             always @(negedge clk or posedge reset_p)begin
                    if(reset_p)count_usec = 0;                  // ���½� count_usec 0 �ʱ�ȭ
                    
                    else if(clk_usec && count_usec_e)count_usec = count_usec + 1;       // clk_usec�� count_usec_e �� Ȱ��ȭ �����϶� ī��Ʈ ���� 
                    
                    else if(count_usec_e == 0)count_usec = 0;       // ���� count_usec_e ��Ȱ��ȭ �����̸� 0���� �缳��
            end  


             // ������ ��°� �ϰ������� ����(pedge�� nedge ��ȣ�� �ܰ� ����)
            edge_detector_p ed(                                     // ����������_n���� p�� ���� , worst negative slack �ּ�ȭ        
            .clk(clk), .reset_p(reset_p), .cp(echo),
            .n_edge(uls_nedge), .p_edge(uls_pedge));     


            
               // ���½� idle ��� ���� �� �׿ܿ� ���� �ܰ�
                always @(negedge clk or posedge reset_p) begin
                    if (reset_p)
                        state = S_IDLE;  // ���� ������ ���, ���¸� S_IDLE�� �ʱ�ȭ
                    else
                        state = next_state;  // �� ���� ���, ���� ���¸� ���� ���·� ������Ʈ
                end
            
                // ���½� �� �� ���� �ʱ�ȭ
                always @(negedge clk or posedge reset_p) begin
                                    if (reset_p) begin          // ���� ����
                                             trig = 0;
                                             distance = 0;
                                             next_state = S_IDLE;          // ���� ���¸� IDLE(���)���·� ����
                                             count_usec_e = 0;             // Ŭ�� �ֱ� ���� Ȱ��ȭ ���� ��ȣ�� 0���� ��Ȱ��ȭ(�ʱ�ȭ)
                                     end
                            else begin
                 
                 case(state)    
                                S_IDLE : begin      // ������ ����
                                        if(count_usec > 20'd1_000_000) begin            // ����ũ�μ�ũ ī��Ʈ�� Ȱ��ȭ �Ǿ�  ī��Ʈ ��  10us �̻� ī��Ʈ�� ����  
                                                count_usec_e = 0;                                       // ��Ȱ��ȭ�ϰ�  
                                                next_state = S_10US;                                // �����ܰ� �Ѿ 
                                        end
                                        else    
                                               count_usec_e=1;                                      // else�� ���� ���� :  ����ũ�μ�ũ ī��Ʈ Ȱ��ȭ = 1
                                        end    

                                S_10US : begin // 40k HZ ���� 8�� �⺻ �ý��� �����̹Ƿ� ����      
                                        if(count_usec > 16'd12) begin     // Ȱ��ȭ �Ǿ� 12us�̻� �� ����
                                                    count_usec_e = 0;           //  ��Ȱ��ȭ
                                                    trig = 0;                           // trig = 0 (low)
                                                    next_state = S_TIMER;       // �����ܰ� �Ѿ
                                        end
                                      else begin                            // else begin ���� ����
                                            trig = 1;                           // trig = 1 (high)
                                            count_usec_e = 1;           // �Ȱ��� Ȱ��ȭ 
                                         end
                                end       
   
                                S_TIMER : begin
                                    if(uls_pedge)begin                  // �����ɿ��� ��¿����� ����
                                        count_usec_e = 1;               // Ȱ��ȭ 
                                        next_state = S_READ;            // �����ܰ�
                                   end             
                                end
                                S_READ : begin
                                      if(uls_nedge) begin                           //������ �ϰ����� �� ���� 
                                            //distance = cm ;    //58 ���ֱ� �� �ٲ����
                                            distance = count_usec  / 58  ;      // �Ÿ� ���� : ��Ƽ����(cm) ����: �Ÿ�(cm) = (�ð�(?s) / 58)
                                            next_state = S_IDLE;                    // �ٽ� ó���ܰ��� �����·� �Ѿ 
                                            count_usec_e = 0;                       // ��Ȱ��ȭ 
                                end
                           end     
                   endcase
                end
        end
endmodule



module pwm_128step_led(
    input clk,           // �Է� Ŭ�� ��ȣ
    input reset_p,       // �񵿱� ���� ��ȣ (active high)
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
    
    // �� ������ pwm_freqX128 ��ȣ�� �����Ͽ�, PWM ���ļ��� 128�� ������ ����
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77����  
                    else cnt = cnt + 1;                         // ī��Ʈ ����
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 ���� 0
                    else pwm_freqX128 = 1;                          // 39 �̻� 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    
    reg [6:0] cnt_duty;  // 7��Ʈ ī���� �������� (0���� 99���� ��)
    
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
            
             // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
            else if(pwm_freqX128_nedge)begin   
            cnt_duty = cnt_duty + 1;
                    if (cnt_duty < duty)pwm = 1;
                    else pwm = 0;
            end
     end
    

    
endmodule




module pwm_128step_motor(
    input clk,           // �Է� Ŭ�� ��ȣ
    input reset_p,       // �񵿱� ���� ��ȣ (active high)
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
    
    // �� ������ pwm_freqX128 ��ȣ�� �����Ͽ�, PWM ���ļ��� 128�� ������ ����
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77����  
                    else cnt = cnt + 1;                         // ī��Ʈ ����
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 ���� 0
                    else pwm_freqX128 = 1;                          // 39 �̻� 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    
    reg [6:0] cnt_duty;  // 7��Ʈ ī���� �������� (0���� 99���� ��)
    
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
            
             // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
            else if(pwm_freqX128_nedge)begin   
            cnt_duty = cnt_duty + 1;
                    if (cnt_duty < duty)pwm = 1;
                    else pwm = 0;
            end
     end
    

    
endmodule




module pwm_128step_servo(
    input clk,           // �Է� Ŭ�� ��ȣ
    input reset_p,       // �񵿱� ���� ��ȣ (active high)
    input [6:0] duty,
    output reg pwm
);
    
    parameter sys_clk_freq = 100_000_000;           // �ý��� Ŭ�� ���ļ�
    parameter pwm_freq = 50;                                // pwm ���ļ� 50hz (servo���� data sheet)
    parameter duty_step = 128;                              //128���ֱ�
    parameter temp = sys_clk_freq / pwm_freq / duty_step;       
    parameter temp_half = temp /2 ;                                            
    
    integer cnt;                            // ī��Ʈ
    reg pwm_freqX128;
    
    // �� ������ pwm_freqX128 ��ȣ�� �����Ͽ�, PWM ���ļ��� 128�� ������ ����
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77����  
                    else cnt = cnt + 1;                         // ī��Ʈ ����
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 ���� 0
                    else pwm_freqX128 = 1;                          // 39 �̻� 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), .cp(pwm_freqX128), 
        .n_edge(pwm_freqX128_nedge)
    ); 
    
    reg [6:0] cnt_duty;  // 7��Ʈ ī���� �������� (0���� 99���� ��)
   
   
   always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    cnt_duty = 0;
                    pwm = 0;
            end
            
             // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
            else if(pwm_freqX128_nedge)begin      
            cnt_duty = cnt_duty + 1;                           
                    if (cnt_duty < duty)pwm = 1;        // ���� duty�����϶� pwm��  1 �ƴϸ� 0
                    else pwm = 0;
            end
     end
    

    
endmodule




module drone_bldc_motor_pwm
  #(     parameter regbitdepth = 16,     
          localparam  sys_clk_freq = 100_000_000,           // �ý��� Ŭ�� ���ļ�  
          localparam pwm_freq = 50,                                // pwm ���ļ� 50hz (servo���� data sheet)
          localparam duty_step = 20*(2**regbitdepth) ,                              //128���ֱ�
          localparam temp = sys_clk_freq / pwm_freq / duty_step,       
          localparam temp_half = temp /2 )                                            
 (
    input clk,           // �Է� Ŭ�� ��ȣ
    input reset_p,       // �񵿱� ���� ��ȣ (active high)
    input [regbitdepth-1:0] motor_ouput,      //  �� duty�� 1~2ms ���� �Դϴ�!!
    output reg pwm
);
    wire [regbitdepth+4:0] duty;    
    assign duty = { {(regbitdepth*18){1'b0}}, motor_ouput, {regbitdepth{1'b0}} };
    integer cnt;                            // ī��Ʈ
    reg pwm_freqX128;
    
    // �� ������ pwm_freqX128 ��ȣ�� �����Ͽ�, PWM ���ļ��� 128�� ������ ����
    always @(posedge clk or posedge reset_p)begin
            if(reset_p)begin
                    pwm_freqX128 = 0;
                    cnt = 0;
            end
            else begin
                    if(cnt >= (temp - 1))cnt = 0;       // 77����  
                    else cnt = cnt + 1;                         // ī��Ʈ ����
                    
                    if(cnt < temp_half) pwm_freqX128 = 0;   // 39 ���� 0
                    else pwm_freqX128 = 1;                          // 39 �̻� 1
            end
     end
    
    wire pwm_freqX128_nedge;
    
    // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
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
             // pwm_freqX128 ��ȣ�� �ϰ������� �����ؼ� cnt_duty �� 1�� ����
            else if(pwm_freqX128_nedge)begin      
                    if(cnt_duty >= (duty_step - 1))cnt_duty = 0;
                    else cnt_duty = cnt_duty + 1;                           
                    
                    if (cnt_duty < duty)pwm = 1;        // ���� duty�����϶� pwm��  1 �ƴϸ� 0
                    else pwm = 0;
            end
     end
    
endmodule


module I2C_master(
    input clk, reset_p,      // Ŭ�� ��ȣ, ���� ��ȣ (Ȱ��ȭ�� High)
    input [6:0] addr,        // I2C ��ġ �ּ� (7��Ʈ)
    input [7:0] data,        // ������ ������ (8��Ʈ)
    input rd_wr, comm_go,    // �б�/���� ����, ��� ���� ��ȣ
    output reg sda, scl,      // I2C ������, Ŭ�� ��ȣ
    output reg [6:0] led
);

    // I2C ���¸� ��Ÿ���� �Ķ���� ����
    parameter IDLE                       = 7'b000_0001;  // ��� ����
    parameter COMM_START      = 7'b000_0010;  // ��� ���� ����
    parameter SEND_ADDR          = 7'b000_0100;  // �ּ� ���� ����
    parameter RD_ACK                 = 7'b000_1000;  // ACK ��ȣ ���� ����
    parameter SEND_DATA          = 7'b001_0000;  // ������ ���� ����
    parameter SCL_STOP             = 7'b010_0000;  // SCL ��ȣ ���� ����
    parameter COMM_STOP        = 7'b100_0000;  // ��� ���� ����

    // �ּҿ� �б�/���� ��Ʈ�� �����Ͽ� 8��Ʈ�� ����
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};     // ���� 7��Ʈ�� �ּ�, ���� 1��Ʈ�� �б�/����

    // 100us Ŭ���� �����ϴ� ��� �ν��Ͻ�
    wire clk_usec;
    
    clock_div_100 usec_clk(
        .clk(clk),                          // �Է� Ŭ��
        .reset_p(reset_p),          // ���� ��ȣ
        .clk_div_100(clk_usec)  // 100us ���� Ŭ�� ���
    );

    reg [2:0] count_usec5;  // 100us ī��Ʈ�� ���� 3��Ʈ ��������
    reg scl_e;                        // SCL ��ȣ�� Ȱ��ȭ�� �����ϴ� �÷���

    // Ŭ�� �� ���� ��ȣ�� ���� SCL ���� ����
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            count_usec5 = 0;     // ���� �� ī���� �ʱ�ȭ
            scl = 0;                     // SCL ��ȣ �ʱ�ȭ
        end 
        else if (scl_e) begin
            if (clk_usec) begin
                if (count_usec5 >= 4) begin  // 4 �̻��� �� SCL ���
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;  // ī���� ����
            end
        end
        else if (!scl_e) begin 
            count_usec5 = 0;    // SCL ��Ȱ��ȭ �� ī���� �ʱ�ȭ
            scl = 1;                     // SCL ��ȣ ����
        end
    end


    // comm_go ��ȣ�� ��� ���� �����
    wire comm_go_pedge;
    
    edge_detector_n ed_go(
        .clk(clk), .reset_p(reset_p), .cp(comm_go), 
        .p_edge(comm_go_pedge)
    );


    // SCL ��ȣ�� ���/�ϰ� ���� �����
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
    output reg busy  // busy �÷���
);

    // ���� �Ű����� ����
    parameter IDLE                                             = 6'b00_0001;
    parameter SEND_HIGH_NIBBLE_DISABLE    = 6'b00_0010;
    parameter SEND_HIGH_NIBBLE_ENABLE     = 6'b00_0100;
    parameter SEND_LOW_NIBBLE_DISABLE     = 6'b00_1000;
    parameter SEND_LOW_NIBBLE_ENABLE      = 6'b01_0000;
    parameter SEND_DISABLE                            = 6'b10_0000;

    reg [7:0] data;      // ������ ������
    reg comm_go;         // I2C �����ͷ� ������ �����ϴ� ��ȣ

    wire send_pedge;     // ���� ��ȣ�� ���� ���� ����

    // ���� ��ȣ�� ���� �����
    edge_detector_n ed_go(
        .clk(clk), 
        .reset_p(reset_p), 
        .cp(send), 
        .p_edge(send_pedge)
    );
   
    wire clk_usec;   // 100us ������ Ŭ�� ��ȣ

    // 100us ���� Ŭ�� ������
    clock_div_100 usec_clk(
        .clk(clk),           // �Է� Ŭ��
        .reset_p(reset_p),   // ���� ��ȣ
        .clk_div_100(clk_usec) // 100us ���� Ŭ�� ���
    );

    reg [21:0] count_usec;  // 100us ������ ī��Ʈ�ϴ� ��������
    reg count_usec_e;       // ī���� Ȱ��ȭ ��ȣ

    // ī���� ����
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) begin
            count_usec = 0;  // ���� �� ī���� �ʱ�ȭ
        end else begin
            if(clk_usec && count_usec_e) 
                count_usec = count_usec + 1;  // ī���� ����
            else if(!count_usec_e) 
                count_usec = 0;  // ī���� �ʱ�ȭ
        end
    end

    reg [5:0] state, next_state;  // ���� ���¿� ���� ���¸� ��Ÿ���� ��������

    // ���� ��ȯ ����
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) 
            state = IDLE;  // ���� �� IDLE ���·� �ʱ�ȭ
        else 
            state = next_state;  // ���� ��ȯ
    end

    // FSM ����
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            next_state = IDLE;  // ���� �� ���� ���¸� IDLE�� ����
            busy = 0;  // �ٻ� ���� ����
        end else begin
            case(state)
                IDLE: begin
                    if(send_pedge) begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;  // ���� ����
                        busy = 1;  // �ٻ� ���� ����
                    end        
                end
                SEND_HIGH_NIBBLE_DISABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[7:4], 3'b100, rs};  // ���� �Ϻ� ���� �غ�  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C ���� ����
                        count_usec_e = 1;  // ī���� Ȱ��ȭ
                    end else begin
                        next_state = SEND_HIGH_NIBBLE_ENABLE;  // ���� ���·� ��ȯ
                        count_usec_e = 0;  // ī���� ��Ȱ��ȭ
                        comm_go = 0;  // ���� ����
                    end
                end
                SEND_HIGH_NIBBLE_ENABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[7:4], 3'b110, rs};  // ���� �Ϻ� ���� ��  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C ���� ����
                        count_usec_e = 1;  // ī���� Ȱ��ȭ
                    end else begin
                        next_state = SEND_LOW_NIBBLE_DISABLE;  // ���� ���·� ��ȯ
                        count_usec_e = 0;  // ī���� ��Ȱ��ȭ
                        comm_go = 0;  // ���� ����
                    end
                end
                SEND_LOW_NIBBLE_DISABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[3:0], 3'b100, rs};  // ���� �Ϻ� ���� �غ�  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C ���� ����
                        count_usec_e = 1;  // ī���� Ȱ��ȭ
                    end else begin
                        next_state = SEND_LOW_NIBBLE_ENABLE;  // ���� ���·� ��ȯ
                        count_usec_e = 0;  // ī���� ��Ȱ��ȭ
                        comm_go = 0;  // ���� ����
                    end
                end
                SEND_LOW_NIBBLE_ENABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[3:0], 3'b110, rs};  // ���� �Ϻ� ���� ��  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C ���� ����
                        count_usec_e = 1;  // ī���� Ȱ��ȭ
                    end else begin
                        next_state = SEND_DISABLE;  // ���� ���·� ��ȯ
                        count_usec_e = 0;  // ī���� ��Ȱ��ȭ
                        comm_go = 0;  // ���� ����
                    end                                
                end
                SEND_DISABLE: begin
                    if(count_usec <= 22'd200) begin
                        data = {send_buffer[3:0], 3'b100, rs};  // ���� �Ϸ� �� ����  //[d7 d6 d5 d4] [BL EN RW] [RS]
                        comm_go = 1;  // I2C ���� ����
                        count_usec_e = 1;  // ī���� Ȱ��ȭ
                    end else begin
                        next_state = IDLE;  // ���� ���� �� IDLE ���·� ����
                        count_usec_e = 0;  // ī���� ��Ȱ��ȭ
                        comm_go = 0;  // ���� ����
                        busy = 0;
                    end                                
                end
            endcase
        end
    end

    // I2C ������ ��� �ν��Ͻ�ȭ
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
