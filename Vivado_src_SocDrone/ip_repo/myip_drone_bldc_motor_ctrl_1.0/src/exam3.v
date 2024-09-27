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


//  �⺻ �ð� Ÿ�̸� (set ��� - �� ����, �� ���� ��ư)
module watch_top(
    input clk, reset_p,       // Ŭ�� ��ȣ, ���� ��ȣ (�⺻ 10ns, active high)
    input [2:0] btn,          // 3��Ʈ ��ư �Է� (���, �� ����, �� ����)
    output [7:0] seg_7,       // 7���׸�Ʈ ���÷��� ���
    output [3:0] com,         // ���� ��ȣ ���(7���׸�Ʈ 4��)
    output mode_led           // ��� LED ���
);

    // wire ���� �� �ν��Ͻ� ���� 
    wire mode, sec_btn, min_btn;
    wire set_watch;                                              // set ���
    wire inc_sec, inc_min;                                       // increase (�� ����, �� ����)
    wire clk_usec, clk_msec, clk_sec, clk_min;      // Ŭ�� ���ֱ�  �ν��Ͻ�
    wire [3:0] sec1, sec10, min1, min10;            //  bcd �ν��Ͻ� (�� 4��Ʈ�� 4��)
    wire [15:0] value;                                           //  sec1, sec10, min1, min10 = value ������ ����(4bit * 4 = 16bit)

    // ��� ���� ��ư ī���� (0�� ��ư �Ҵ�)
    button_cntr btn_mode( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[0]), .btn_pedge(mode)
    );

    // �� ���� ��ư ī���� (1�� ��ư �Ҵ�)
    button_cntr btn_sec( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[1]), .btn_pedge(sec_btn)
    );

    // �� ���� ��ư ī���� (2�� ��ư �Ҵ�)
    button_cntr btn_min( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[2]), .btn_pedge(min_btn)
    );

    // ��� ���� T �ø��÷� (T �ø� �÷��� ����Ͽ� ��� ��ȯ�� �� ����)
    T_flip_flop_p t_mode(
        .clk(clk), .reset_p(reset_p), 
        .t(mode), .q(set_watch)
    );

    // ����ũ���� Ŭ�� ���ֱ�  (�⺻ Ŭ���� 10ns �� 100���ֱ⸦ ���Ͽ� 1us (1 micro sec) ��� - cp_div_100(clk_usec))
    clock_div_100 usec_clk(
        .clk(clk), .reset_p(reset_p),
        .cp_div_100(clk_usec)   // cp - clock pulse , div - divider = Ŭ�� �޽� ���ֱ�
    );

    // �и��� Ŭ�� ���ֱ� (��¹��� 1us�� .clk_source(clk_usec) Ŭ�� �ҽ��� �Է��Ͽ� 1000�� �ֱ⸦ ���Ͽ� 1ms (1 milli sec) ��� - cp_div_1000(clk_msec))
    clock_div_1000 msec_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_usec),
        .cp_div_1000_nedge(clk_msec)
    );

    // �� Ŭ�� ���ֱ� (��¹��� 1ms�� .clk_source(clk_msec) Ŭ�� �ҽ��� �Է��Ͽ� 1000�� �ֱ⸦ ���Ͽ� 1s (1 sec) ��� - cp_div_1000(clk_sec))
    clock_div_1000 sec_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_msec),
        .cp_div_1000_nedge(clk_sec)
    );

    // �� Ŭ�� ���ֱ� (��¹��� 1sec �� .clk_source(clk_sec) Ŭ�� �ҽ��� �Է��Ͽ� 60�� �ֱ⸦ ���Ͽ� 1min ��� - cp_div_60(clk_min))
    
    clock_div_60 min_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_sec),
        .cp_div_60_nedge(clk_min)
    );

    // BCD - segment 0���� 9����  10������ ��Ÿ�� , bcd_60_sec(���ֱ⿡�� ���� ��� (clk_sec = inc_sec)��  .clk_time(inc_sec) �Է� �� bcd1(sec1) 1���ڸ� , bcd10(sec10) 10���ڸ� �Է�)
   // *�߿�* .clk_source(clk_sec)�� �ƴ� (inc_sec) �� ���� ���� : inc_sec�� �־��  �ؿ� ������ assign inc_sec = set_watch ? sec_btn : clk_sec; ����
   //  clk_sec�� ���Խ� set��� ���� �� �� ���� x (�׳� �Ϲ� Ÿ�̸���), ������ inc_sec ���Խ� set���(�� ����) �� �⺻��� �Ѵ� ��밡��  
    counter_bcd_60 counter_sec(
        .clk(clk), .reset_p(reset_p),
        .clk_time(inc_sec),
        .bcd1(sec1), .bcd10(sec10)
    );

    // bcd_60_min(���ֱ⿡�� ���� ��� (clk_min = inc_min)��  .clk_time(inc_min) �Է� �� bcd1(min1) 1���ڸ� , bcd10(min10) 10���ڸ� �Է�)
   //  clk_min�� ���Խ� set��� ���� �� �� ���� x (�׳� �Ϲ� Ÿ�̸���), ������ inc_min ���Խ� set���(�� ����) �� �⺻��� �Ѵ� ��밡��  
    counter_bcd_60 counter_min(
        .clk(clk), .reset_p(reset_p),
        .clk_time(inc_min),
        .bcd1(min1), .bcd10(min10)
    );

    // 4�ڸ� FND ���÷��� ��Ʈ�ѷ� �ν��Ͻ� ��� �� ���� (+ value)
    fnd_4digit_cntr fnd(
        .clk(clk), .reset_p(reset_p), 
        .value(value), .seg_7(seg_7), .com(com)
    );

    // �� �Ҵ�
    assign value = {min10, min1, sec10, sec1};             // sec1, sec10, min1, min10 = value ������ ����(4bit * 4 = 16bit) �� �Ҵ�
    assign inc_sec = set_watch ? sec_btn : clk_sec;       // set_watch ��忡�� sec_btn (1:��) �Է� �� increase_sec(�� ����), clk_sec (0:����) �Է� �� ���� ����   
    assign inc_min = set_watch ? min_btn : clk_min;     // set_watch ��忡�� min_btn (1:��) �Է� �� increase_min(�� ����), clk_min (0:����) �Է� �� ���� ����   
    assign mode_led = set_watch;                                   // set_watch ��� �� led ��� ���� (led ����) 

endmodule





module stop_watch_top(

        input clk, reset_p,
        input [1:0] btn,            // �� ���� ��ư �Է� (����/����, ��)
        output [3:0] com,
        output [7:0] seg_7);
        
        wire btn0_pedge, btn1_pedge, start_stop, lap;   // ��ư �޽� ���� ��ȣ, ����/���� �� �� ���� ��ȣ
        wire clk_start;                                                         // ����/���� ���¿� ���� Ŭ�� ��ȣ ����
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] sec1, sec10, min1, min10;                  // �� �� ���� BCD ���
        wire [15:0] cur_time ;
        reg [15:0] lap_time;                                              // �� Ÿ�� ����
        wire[15:0] value;
       
        // ǥ���� ���� �� ���¿� ���� ���� �ð� �Ǵ� �� Ÿ������ ����
        assign value = lap ? lap_time : cur_time;
        
        // ����/���� ���¿� ���� Ŭ�� ��ȣ ����
        assign clk_start = start_stop ? clk : 0; 
        
       // ���� �ð� ���� BCD ������� ����
        assign cur_time = {min10, min1, sec10, sec1};
        
        // 0�� ��ư ����/���� 
        button_cntr btn_start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn0_pedge));
        
        // T �ø��÷��� ����Ͽ� ����/���� ���� ��ȯ      
        T_flip_flop_p t_start(
                .clk(clk), .reset_p(reset_p), 
                .t(btn0_pedge), .q(start_stop));
       
        // 1�� ��ư �� ����        
        button_cntr btn_lap( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn1_pedge));
        
        // T �ø��÷��� ����Ͽ� �� ���� ��ȯ        
        T_flip_flop_p t_lap(
                .clk(clk), .reset_p(reset_p), 
                .t(btn1_pedge), .q(lap));       

          // Ŭ�� ���ֱ� ���� 
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
                
        // bcd ����
        counter_bcd_60 counter_sec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_sec),
                .bcd1(sec1), .bcd10(sec10)); 
                  
        counter_bcd_60 counter_min(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .bcd1(min1), .bcd10(min10));

       
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
       
      // �� Ÿ�� ���� ����
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;
               else if(btn1_pedge)lap_time = cur_time;  // 1�� ��ư ��¿���(�������� high-��¿���)
        end                                                                     //�� ��ư�� ������ ��, ���� �ð��� lap_time�� ����


endmodule






module cook_timer(
        input clk, reset_p,             // clk: ���� Ŭ�� ��ȣ, reset_p: ���� ��ȣ (���� Ȱ��)
        input [3:0] btn,                // 4���� ��ư �Է�
        output [3:0] com,               // 4�ڸ� 7���׸�Ʈ ���÷����� ���� ���� ��ȣ
        output [7:0] seg_7,             // 7���׸�Ʈ ���÷����� ���׸�Ʈ ���� ��ȣ
        output reg timeout_led,         // Ÿ�̸Ӱ� 0�� �Ǿ��� �� ������ LED
        output buzz,                    // Ÿ�̸Ӱ� 0�� �Ǿ��� �� Ȱ��ȭ�Ǵ� ���� ��ȣ
        output buzz_clk);               // ������ Ŭ�� ��ȣ
        
        wire [3:0] btn_pedge;           // ��ư�� ���� ������ �����ϴ� ��ȣ
        wire [15:0] value, set_time, cur_time; // value: ���� �Ǵ� ������ �ð�, set_time: ������ �ð�, cur_time: ���� �ð�
        wire load_enable;               // �ð� ������ �ε��ϱ� ���� ��ȣ
        wire clk_usec, clk_msec, clk_sec; // ���� ����ũ����, �и���, �� Ŭ�� ��ȣ
        wire alarm_off, inc_min, inc_sec, btn_start; // �˶� ����, �� ����, �� ����, ���� ��ư ��ȣ
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10; // ������ �ʿ� ���� BCD ��
        wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10; // ���� �ʿ� ���� BCD ��
        wire dec_clk;                   // ���� Ŭ�� ��ȣ
        
        reg start_stop;                 // Ÿ�̸��� ����/���� ���¸� ��Ÿ���� ��������
        
        reg [16:0] clk_div;             // Ŭ�� ���ֱ�
        always @(posedge clk) clk_div = clk_div + 1; // Ŭ���� �����Ͽ� ���� Ŭ�� ��ȣ ����
        
        assign buzz_clk = timeout_led ? clk_div[13] : 0; // Ÿ�Ӿƿ� �� ���� Ŭ�� ��ȣ ���
        assign buzz = timeout_led; // Ÿ�Ӿƿ� �� ���� ��ȣ ���
        
        // ���� ��ư ��Ʈ��
        button_cntr start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));
                 
        // Ÿ�̸� ���� ����
        always @(posedge clk or posedge reset_p) begin
                if (reset_p) begin
                        start_stop = 0;
                        timeout_led = 0;
                end
                else begin 
                    if (btn_start) start_stop = ~start_stop; // ����/���� ��ư�� ������ ���� ����
                    else if (cur_time == 0 && start_stop) begin 
                        start_stop = 0;
                        timeout_led = 1; // Ÿ�̸Ӱ� 0�� �����ϸ� LED �ѱ�
                    end
                    else if (alarm_off) timeout_led = 0; // �˶� ���� ��ư�� ������ LED ����
                end
        end    
        
        // ���� �����
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(start_stop), 
                    .p_edge(load_enable)); 
        
        // �� ���� ��ư ��Ʈ��
        button_cntr btn_inc_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));
                
        // �� ���� ��ư ��Ʈ��
        button_cntr btn_inc_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2]));
                
        // �˶� ���� ��ư ��Ʈ��
        button_cntr btn_alarm_stop( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[3]), .btn_pedge(btn_pedge[3]));       
        
        // ����ũ���� Ŭ�� ���ֱ�
        clock_div_100 usec_clk(
               .clk(clk), .reset_p(reset_p),
               .cp_div_100(clk_usec));   

        // �и��� Ŭ�� ���ֱ�
        clock_div_1000 msec_clk(
             .clk(clk), .reset_p(reset_p),
             .clk_source(clk_usec),
             .cp_div_1000_nedge(clk_msec));

        // �� Ŭ�� ���ֱ�
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
       
        // ��ư ��ȣ ����
        assign {alarm_off, inc_sec, btn_start, inc_min} = btn_pedge;
       
        // ������ �ð��� BCD ī���� (��)
        counter_bcd_60 counter_sec(
                    .clk(clk), .reset_p(reset_p),
                    .clk_time(inc_sec),
                    .bcd1(set_sec1), .bcd10(set_sec10));

        // ������ �ð��� BCD ī���� (��)
        counter_bcd_60 counter_min(
                   .clk(clk), .reset_p(reset_p),
                   .clk_time(inc_min),
                   .bcd1(set_min1), .bcd10(set_min10));
           
        // ���� �ð��� �ٿ� ī���� (��)
        loadable_down_counter_bcd_60 cur_sec(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(clk_sec),
                    .load_enable(load_enable),
                    .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                    .bcd1(cur_sec1), .bcd10(cur_sec10),
                    .dec_clk(dec_clk));
                    
        // ���� �ð��� �ٿ� ī���� (��)
        loadable_down_counter_bcd_60 cur_min(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(dec_clk),
                    .load_enable(load_enable),
                    .load_bcd1(set_min1), .load_bcd10(set_min10),
                    .bcd1(cur_min1), .bcd10(cur_min10));

        // ������ �ð��� ���� �ð� ����
        assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
        assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
        
        // ���� �ð� �Ǵ� ������ �ð��� �����Ͽ� ���
        assign value = start_stop ? cur_time : set_time;
        
        // 4�ڸ� 7���׸�Ʈ ���÷��� ����
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);     
endmodule







/*
module watch_top_2(
    input clk, reset_p,       // Ŭ�� ��ȣ, ���� ��ȣ (�⺻ 10ns, active high)
    input [3:0] btn,          // 3��Ʈ ��ư �Է� (���, �� ����, �� ����)
    output [7:0] seg_7,       // 7���׸�Ʈ ���÷��� ���
    output [3:0] com,         // ���� ��ȣ ���(7���׸�Ʈ 4��)
    output led           // ��� LED ���
);

    parameter watch            = 3'b001; 
    parameter stop_watch    = 3'b010;
    parameter cook_watch   = 3'b100;
    
    reg [2:0] state, next_state;
    
 


    // wire ���� �� �ν��Ͻ� ���� 
    wire mode, set_watch,next;
    wire sec_btn,min_btn;                                                  // set ���
    wire inc_sec, inc_min;                                       // increase (�� ����, �� ����)    
    wire clk_usec, clk_msec, clk_sec, clk_min;      // Ŭ�� ���ֱ�  �ν��Ͻ�
    wire [3:0] sec1, sec10, min1, min10;            //  bcd �ν��Ͻ� (�� 4��Ʈ�� 4��)
    wire [15:0] value; 
    
     wire [3:0] btn;
     
     edge_detector_p ed(       
          .clk(clk), .reset_p(reset_p), .cp(btn[0]),
          .p_edge(btn[0]));  
          
    assign value = {min10, min1, sec10, sec1};             // sec1, sec10, min1, min10 = value ������ ����(4bit * 4 = 16bit) �� �Ҵ�
    assign inc_sec = set_watch ? sec_btn : clk_sec;       // set_watch ��忡�� sec_btn (1:��) �Է� �� increase_sec(�� ����), clk_sec (0:����) �Է� �� ���� ����   
    assign inc_min = set_watch ? min_btn : clk_min;     // set_watch ��忡�� min_btn (1:��) �Է� �� increase_min(�� ����), clk_min (0:����) �Է� �� ���� ����   
    assign mode_led = set_watch;    
              
   /////////////////////////////////////       
       wire start_stop, lap,clk_start;   
       wire [15:0] cur_time ;   
       reg [15:0] lap_time;   // �� Ÿ�� ���� ����
       
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;
               else if(sec_btn)lap_time = cur_time;  // 1�� ��ư ��¿���(�������� high-��¿���)
        end                                                                     //�� ��ư�� ������ ��, ���� �ð��� lap_time�� ����
    
            // ǥ���� ���� �� ���¿� ���� ���� �ð� �Ǵ� �� Ÿ������ ����
        assign value = lap ? lap_time : cur_time;
        
        // ����/���� ���¿� ���� Ŭ�� ��ȣ ����
        assign clk_start = start_stop ? clk : 0; 
        
       // ���� �ð� ���� BCD ������� ����
        assign cur_time = {min10, min1, sec10, sec1};
   /////////////////////////////////////////////////////////////////////////////////////////
   
    // ��� ���� ��ư ī���� (0�� ��ư �Ҵ�)
    button_cntr btn_mode( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[0]), .btn_pedge(next)
    );

    // �� ���� ��ư ī���� (1�� ��ư �Ҵ�)
    button_cntr btn_sec( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[1]), .btn_pedge(sec_btn)
    );

    // �� ���� ��ư ī���� (2�� ��ư �Ҵ�)
    button_cntr btn_min( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[2]), .btn_pedge(min_btn)
    );
    
        // set ��ư  (3�� ��ư �Ҵ�)
    button_cntr btn_set( 
        .clk(clk), .reset_p(reset_p),
        .btn(btn[3]), .btn_pedge(mode)
    );
    
//////////////////////////////////////////////////////////////////////////////////////////
   
    // watch - ��� ���� T �ø��÷� (T �ø� �÷��� ����Ͽ� ��� ��ȯ�� �� ����)
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


    // ����ũ���� Ŭ�� ���ֱ�  (�⺻ Ŭ���� 10ns �� 100���ֱ⸦ ���Ͽ� 1us (1 micro sec) ��� - cp_div_100(clk_usec))
    clock_div_100 usec_clk(
        .clk(clk), .reset_p(reset_p),
        .cp_div_100(clk_usec)   // cp - clock pulse , div - divider = Ŭ�� �޽� ���ֱ�
    );

    // �и��� Ŭ�� ���ֱ� (��¹��� 1us�� .clk_source(clk_usec) Ŭ�� �ҽ��� �Է��Ͽ� 1000�� �ֱ⸦ ���Ͽ� 1ms (1 milli sec) ��� - cp_div_1000(clk_msec))
    clock_div_1000 msec_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_usec),
        .cp_div_1000_nedge(clk_msec)
    );

    // �� Ŭ�� ���ֱ� (��¹��� 1ms�� .clk_source(clk_msec) Ŭ�� �ҽ��� �Է��Ͽ� 1000�� �ֱ⸦ ���Ͽ� 1s (1 sec) ��� - cp_div_1000(clk_sec))
    clock_div_1000 sec_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_msec),
        .cp_div_1000_nedge(clk_sec)
    );

    // �� Ŭ�� ���ֱ� (��¹��� 1sec �� .clk_source(clk_sec) Ŭ�� �ҽ��� �Է��Ͽ� 60�� �ֱ⸦ ���Ͽ� 1min ��� - cp_div_60(clk_min))
    
    clock_div_60 min_clk(
        .clk(clk), .reset_p(reset_p),
        .clk_source(clk_sec),
        .cp_div_60_nedge(clk_min)
    );

/////////////////////////////////////////////////////////////////////////////////

    // BCD - segment 0���� 9����  10������ ��Ÿ�� , bcd_60_sec(���ֱ⿡�� ���� ��� (clk_sec = inc_sec)��  .clk_time(inc_sec) �Է� �� bcd1(sec1) 1���ڸ� , bcd10(sec10) 10���ڸ� �Է�)
   // *�߿�* .clk_source(clk_sec)�� �ƴ� (inc_sec) �� ���� ���� : inc_sec�� �־��  �ؿ� ������ assign inc_sec = set_watch ? sec_btn : clk_sec; ����
   //  clk_sec�� ���Խ� set��� ���� �� �� ���� x (�׳� �Ϲ� Ÿ�̸���), ������ inc_sec ���Խ� set���(�� ����) �� �⺻��� �Ѵ� ��밡��  
    counter_bcd_60 counter_sec(
        .clk(clk), .reset_p(reset_p),
        .clk_time(inc_sec),
        .bcd1(sec1), .bcd10(sec10)
    );

    // bcd_60_min(���ֱ⿡�� ���� ��� (clk_min = inc_min)��  .clk_time(inc_min) �Է� �� bcd1(min1) 1���ڸ� , bcd10(min10) 10���ڸ� �Է�)
   //  clk_min�� ���Խ� set��� ���� �� �� ���� x (�׳� �Ϲ� Ÿ�̸���), ������ inc_min ���Խ� set���(�� ����) �� �⺻��� �Ѵ� ��밡��  
    counter_bcd_60 counter_min(
        .clk(clk), .reset_p(reset_p),
        .clk_time(inc_min),
        .bcd1(min1), .bcd10(min10)
    );

    // 4�ڸ� FND ���÷��� ��Ʈ�ѷ� �ν��Ͻ� ��� �� ���� (+ value)
    fnd_4digit_cntr fnd(
        .clk(clk), .reset_p(reset_p), 
        .value(value), .seg_7(seg_7), .com(com)
    );
    
////////////////////////////////////////////////////////////////////////////////   

     // ���½� ���� �ʱ�ȭ �� �����ܰ�
     always @(negedge clk or posedge reset_p) begin
            if (reset_p)begin
                     state = watch;  // ���� ������ ���, ���¸� S_IDLE�� �ʱ�ȭ
            end
            else begin
                     state = next_state;  // �� ���� ���, ���� ���¸� ���� ���·� ������Ʈ
            end                
     end

    // ���� ��ȯ
    always @(*) begin
        next_state = state; 
        
       case(state)    
               watch : begin  // IDLE ����: MCU�� DHT11���� ����� �����ϱ� �� ��� ����
                        if(btn[0]) begin // ������ 3��   // Ŭ���ֱⰡ 3�� �̸��Ͻ�  (������)
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
                            if(btn[0]) begin // ������ 3��   // Ŭ���ֱⰡ 3�� �̸��Ͻ�  (������)
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
                            if(btn[0]) begin // ������ 3��   // Ŭ���ֱⰡ 3�� �̸��Ͻ�  (������)
                                  next_state = watch;         
                            end
                            else begin                                      // 3�� �ʰ��Ͻ� (��ȣ ������)
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