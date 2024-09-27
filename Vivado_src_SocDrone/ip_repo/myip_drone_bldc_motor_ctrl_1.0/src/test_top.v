`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/06/19 09:18:13
// Design Name: 
// Module Name: test_top
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


module decoder_7seg_top(
    input [3:0] sw_value,   // �Է�: 4��Ʈ ����ġ ��
    output  [7:0] seg_7, // ���: 7���׸�Ʈ ��ȣ
    output  [3:0] com    // ���: Ŀ�� ��ȣ
);
    
    assign com = 4'b0000;  // ������ Ŀ�� ��ȣ �Ҵ�
    
    // decoder_7seg ��� �ν��Ͻ�ȭ
    decoder_7seg fnd(
        .hex_value(sw_value),  // sw_value�� decoder_7seg ����� hex_value�� ����
        .seg_7(seg_7)          // decoder_7seg ����� seg_7�� seg_7 ����
    );

endmodule

module fnd_test_top(
    input clk,               // �Է�: Ŭ��
    input reset_p,           // �Է�: �񵿱� ����
    input [15:0] value,      // �Է�: 16��Ʈ ��
    output  [7:0] seg_7,  // ���: 7���׸�Ʈ ��ȣ
    output  [3:0] com     // ���: Ŀ�� ��ȣ
);

    // fnd_4digit_cntr ��� �ν��Ͻ�ȭ
    fnd_4digit_cntr fnd(
        .clk(clk),
        .reset_p(reset_p),
        .value(value),
        .seg_7(seg_7),
        .com(com)
    );

endmodule




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
    wire set_watch;                                                  // set ���
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




//  loadable �ð� Ÿ�̸� :  ���� watch_top���� �߻��ϴ� ����(mux���� �ϰ����� �� 1min ����)�� ���� �ڵ�
// (clk_sec�� btn_sec ���� ���� )(set ��� - �� ����, �� ���� ��ư)
module loadable_watch_top(

        input clk, reset_p,
        input [2:0] btn,
        output [7:0] seg_7,
        output [3:0] com,
        output mode_led);
        
        wire mode, sec_btn, min_btn ;
        wire set_watch;
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;       
        wire [3:0] watch_sec1, watch_sec10, watch_min1, watch_min10;    // ������ ���ֱ� ���� (����) ���� ����  
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10;                        // ������ ���ֱ� ���� (����) ���� ����  
        wire[15:0] value, set_value, watch_value;
        wire watch_time_load_en, set_time_load_en;                                       // �⺻ ���, set��� load_enable ����
        
        button_cntr btn_mode( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(mode));
                
        button_cntr btn_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(sec_btn));
                
        button_cntr btn_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(min_btn));
        
        T_flip_flop_p t_mode(
                .clk(clk), .reset_p(reset_p), 
                .t(mode), .q(set_watch));
    
    // ���� �����: set_watch ��ȣ�� ��� ������ �ϰ� ������ �����Ͽ�
    // ���� set_time_load_en �� watch_time_load_en ��ȣ�� ����.
    // �̸� ���� ��� ��ȯ �� ��Ȯ�� Ÿ�ֿ̹� �ε� ������ ����.
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(set_watch), 
                    .n_edge(watch_time_load_en), .p_edge(set_time_load_en)); 
        

        clock_div_100 usec_clk(
             .clk(clk), .reset_p(reset_p),
             .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
            .clk(clk), .reset_p(reset_p),    
            .clk_source(clk_usec),
            .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
            
        clock_div_60 min_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(inc_sec),
            .cp_div_60_nedge(clk_min));
       
       
       // loadable watch�� Ư¡ 
       // ���� watch_top�� �ٸ��� { .load_enable( ), .load_bcd1( ), .load_bcd10( ) } ������ �߰��Ǿ�����.
       // ���� sec_watch �� sec_set �ν��Ͻ����� �Է°��� { .bcd1( ), .bcd10( ) }  set <---> watch ���� �ݴ�Ǵ°��� Ȯ��
       // �� ���� loadable�� Ư��(�������� �����Ͽ� ��������)�� set�� watch���� watch�� set���� �����ϴ°��� �� ������.
       // load_enable ���� ���� ������������ enable���� 1(on)�϶� Ȱ��ȭ��      

       loadable_counter_bcd_60 sec_watch(
                  .clk(clk), .reset_p(reset_p),
                  .clk_time(clk_sec), 
                  .load_enable(watch_time_load_en),
                  .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                  .bcd1(watch_sec1), .bcd10(watch_sec10));
                  
       loadable_counter_bcd_60 min_watch(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .load_enable(watch_time_load_en),
                .load_bcd1(set_min1), .load_bcd10(set_min10),
                .bcd1(watch_min1), .bcd10(watch_min10));
       
         loadable_counter_bcd_60 sec_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(sec_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_sec1), .load_bcd10(watch_sec10),
                .bcd1(set_sec1), .bcd10(set_sec10));
                
          loadable_counter_bcd_60 min_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(min_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_min1), .load_bcd10(watch_min10),
                .bcd1(set_min1), .bcd10(set_min10));
        
        
       assign inc_sec = set_watch ? sec_btn : clk_sec;
     // �Ⱦ� -  assign inc_min = set_watch ? min_btn : clk_min;
       assign mode_led = set_watch;
       assign set_value = {set_min10,set_min1, set_sec10, set_sec1};
       assign watch_value = {watch_min10,watch_min1,watch_sec10,watch_sec1};
       assign value = set_watch ? set_value : watch_value;          // set value��(1) �� watch value(0) �� ����
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);


endmodule


module loadable_watch_exam_top(

        input clk, reset_p,
        input [2:0] btn,
        output [15:0] value);
        
        wire mode, sec_btn, min_btn ;
        wire set_watch;
        wire inc_sec, inc_min;
        wire clk_usec, clk_msec, clk_sec, clk_min;       
        wire [3:0] watch_sec1, watch_sec10, watch_min1, watch_min10;    // ������ ���ֱ� ���� (����) ���� ����  
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10;                        // ������ ���ֱ� ���� (����) ���� ����  
        wire[15:0] set_value, watch_value;
        wire watch_time_load_en, set_time_load_en;                                       // �⺻ ���, set��� load_enable ����
        

                
        button_cntr btn_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(sec_btn));
                
        button_cntr btn_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(min_btn));
                
        button_cntr btn_mode( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(mode));
        
        T_flip_flop_p t_mode(
                .clk(clk), .reset_p(reset_p), 
                .t(mode), .q(set_watch));
    
    // ���� �����: set_watch ��ȣ�� ��� ������ �ϰ� ������ �����Ͽ�
    // ���� set_time_load_en �� watch_time_load_en ��ȣ�� ����.
    // �̸� ���� ��� ��ȯ �� ��Ȯ�� Ÿ�ֿ̹� �ε� ������ ����.
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(set_watch), 
                    .n_edge(watch_time_load_en), .p_edge(set_time_load_en)); 
        

        clock_div_100 usec_clk(
             .clk(clk), .reset_p(reset_p),
             .cp_div_100(clk_usec));
        
        clock_div_1000 msec_clk(
            .clk(clk), .reset_p(reset_p),    
            .clk_source(clk_usec),
            .cp_div_1000_nedge(clk_msec));
    
        clock_div_1000 sec_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(clk_msec),
            .cp_div_1000_nedge(clk_sec));
            
        clock_div_60 min_clk(
            .clk(clk), .reset_p(reset_p),     
            .clk_source(inc_sec),
            .cp_div_60_nedge(clk_min));
       
       
       // loadable watch�� Ư¡ 
       // ���� watch_top�� �ٸ��� { .load_enable( ), .load_bcd1( ), .load_bcd10( ) } ������ �߰��Ǿ�����.
       // ���� sec_watch �� sec_set �ν��Ͻ����� �Է°��� { .bcd1( ), .bcd10( ) }  set <---> watch ���� �ݴ�Ǵ°��� Ȯ��
       // �� ���� loadable�� Ư��(�������� �����Ͽ� ��������)�� set�� watch���� watch�� set���� �����ϴ°��� �� ������.
       // load_enable ���� ���� ������������ enable���� 1(on)�϶� Ȱ��ȭ��      

       loadable_counter_bcd_60 sec_watch(
                  .clk(clk), .reset_p(reset_p),
                  .clk_time(clk_sec), 
                  .load_enable(watch_time_load_en),
                  .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                  .bcd1(watch_sec1), .bcd10(watch_sec10));
                  
       loadable_counter_bcd_60 min_watch(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_min),
                .load_enable(watch_time_load_en),
                .load_bcd1(set_min1), .load_bcd10(set_min10),
                .bcd1(watch_min1), .bcd10(watch_min10));
       
         loadable_counter_bcd_60 sec_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(sec_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_sec1), .load_bcd10(watch_sec10),
                .bcd1(set_sec1), .bcd10(set_sec10));
                
          loadable_counter_bcd_60 min_set(
                .clk(clk), .reset_p(reset_p),
                .clk_time(min_btn),
                .load_enable(set_time_load_en),
                .load_bcd1(watch_min1), .load_bcd10(watch_min10),
                .bcd1(set_min1), .bcd10(set_min10));
        
        
       assign inc_sec = set_watch ? sec_btn : clk_sec;
     // �Ⱦ� -  assign inc_min = set_watch ? min_btn : clk_min;
     //  assign mode_led = set_watch;
       assign set_value = {set_min10,set_min1, set_sec10, set_sec1};
       assign watch_value = {watch_min10,watch_min1,watch_sec10,watch_sec1};
       assign value = set_watch ? set_value : watch_value;          // set value��(1) �� watch value(0) �� ����
     //   fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);


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


module stop_watch_exam_top(

        input clk, reset_p,
        input [1:0] btn,            // �� ���� ��ư �Է� (����/����, ��)
        output [15:0] value);
        
        wire btn0_pedge, btn1_pedge, start_stop, lap;   // ��ư �޽� ���� ��ȣ, ����/���� �� �� ���� ��ȣ
        wire clk_start;                                                         // ����/���� ���¿� ���� Ŭ�� ��ȣ ����
        wire clk_usec, clk_msec, clk_sec, clk_min;
        wire [3:0] sec1, sec10, min1, min10;                  // �� �� ���� BCD ���
        wire [15:0] cur_time ;
        reg [15:0] lap_time;                                              // �� Ÿ�� ����

       
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



// sec : msec Ÿ�̸� 
module stop_watch_top_sec(
        input clk, reset_p,
        input [1:0] btn,
        output [3:0] com,
        output [7:0] seg_7);
        
        wire btn0_pedge, btn1_pedge, start_stop, lap;
        
        button_cntr btn_start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn0_pedge));
                
        T_flip_flop_p t_start(
                .clk(clk), .reset_p(reset_p), 
                .t(btn0_pedge), .q(start_stop));
                
        button_cntr btn_lap( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn1_pedge));
                
        T_flip_flop_p t_lap(
                .clk(clk), .reset_p(reset_p), 
                .t(btn1_pedge), .q(lap));       
                
        wire clk_start;
        assign clk_start = start_stop ? clk : 0;   // ����/���� ���¿� ���� Ŭ�� ��ȣ ����
                
        wire clk_usec, clk_msec, clk_sec, clk_min, clk_10msec;
        
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
         
         // 10 �и��� ���� Ŭ�� ���ֱ� ��� �ν��Ͻ�ȭ       
         clock_div_10 msecc_clk(                         // msecc : �ν��Ͻ� �� ������ ���� �ӽ� ����
                .clk(clk_start), .reset_p(reset_p),
                .clk_source(clk_msec), .cp_div_10_nedge(clk_10msec));   // 10���� msec
                
        wire [3:0] msec1, msec10, sec1, sec10;      // ���� 4��Ʈ
      
         // �и��� ī���� ��� �ν��Ͻ�ȭ (0~99 BCD ī����)        
        counter_bcd_100 counter_msec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_10msec),                      // 10���� msec
                .bcd1(msec1), .bcd10(msec10));      
         
        // �� ī���� ��� �ν��Ͻ�ȭ (0~59 BCD ī����)                 
        counter_bcd_60 counter_sec(
                .clk(clk), .reset_p(reset_p),
                .clk_time(clk_sec),
                .bcd1(sec1), .bcd10(sec10)); 
                  
       wire [15:0] cur_time ;       
       
       // ���� �ð� ���� BCD ������� ����
       assign cur_time = {sec10, sec1, msec10, msec1};  // ���׸�Ʈ �ڸ��� ���� (���ʺ��� 10,1sec : 10,1 ms) 
      
       // �� Ÿ�� ���� ����
       reg [15:0] lap_time;
       always @(posedge clk or posedge reset_p)begin
               if(reset_p)
                    lap_time = 0;                                         // ���� ��ȣ�� Ȱ��ȭ�� ���, lap_time�� 0���� �ʱ�ȭ
               else if(btn1_pedge)lap_time = cur_time;      // �� ��ư�� ������ ��, ���� �ð��� lap_time�� ����
        end

       wire[15:0] value;
       
        // ǥ���� ���� �� ���¿� ���� ���� �ð� �Ǵ� �� Ÿ������ ����
       assign value = lap ? lap_time : cur_time;
       
       // 4�ڸ� 7-���׸�Ʈ ���÷��� ��Ʈ�ѷ� ��� �ν��Ͻ�ȭ
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);

endmodule




module cook_timer(
        input clk, reset_p,             // clk: ���� Ŭ�� ��ȣ, reset_p: ���� ��ȣ (���� Ȱ��)
        input [3:0] btn,                // 4���� ��ư �Է�
        output [3:0] com,               // 4�ڸ� 7���׸�Ʈ ���÷����� ���� ���� ��ȣ
        output [7:0] seg_7,             // 7���׸�Ʈ ���÷����� ���׸�Ʈ ���� ��ȣ
        output reg timeout_led        // Ÿ�̸Ӱ� 0�� �Ǿ��� �� ������ LED
     //   output buzz,                    // Ÿ�̸Ӱ� 0�� �Ǿ��� �� Ȱ��ȭ�Ǵ� ���� ��ȣ
     // output buzz_clk
        );               // ������ Ŭ�� ��ȣ
        
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
                    .load_enable(btn_start),
                    .load_bcd1(set_sec1), .load_bcd10(set_sec10),
                    .bcd1(cur_sec1), .bcd10(cur_sec10),
                    .dec_clk(dec_clk));
                    
        // ���� �ð��� �ٿ� ī���� (��)
        loadable_down_counter_bcd_60 cur_min(
                    .clk(clk), .reset_p(reset_p), 
                    .clk_time(dec_clk),
                    .load_enable(btn_start),
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


module cook_timer_exam(
        input clk, reset_p,             // clk: ���� Ŭ�� ��ȣ, reset_p: ���� ��ȣ (���� Ȱ��)
        input [2:0] btn,                 // 4���� ��ư �Է�
        input alarm_off,
        output [15:0] value,               
        output reg timeout_led       // Ÿ�̸Ӱ� 0�� �Ǿ��� �� ������ LED
);               // ������ Ŭ�� ��ȣ
        
        wire [2:0] btn_pedge;           // ��ư�� ���� ������ �����ϴ� ��ȣ
        wire [15:0] set_time, cur_time; // value: ���� �Ǵ� ������ �ð�, set_time: ������ �ð�, cur_time: ���� �ð�
        wire load_enable;               // �ð� ������ �ε��ϱ� ���� ��ȣ
        wire clk_usec, clk_msec, clk_sec; // ���� ����ũ����, �и���, �� Ŭ�� ��ȣ
        wire  inc_min, inc_sec, btn_start; // �˶� ����, �� ����, �� ����, ���� ��ư ��ȣ
        wire [3:0] set_sec1, set_sec10, set_min1, set_min10; // ������ �ʿ� ���� BCD ��
        wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10; // ���� �ʿ� ���� BCD ��
        wire dec_clk;                   // ���� Ŭ�� ��ȣ
        
        reg start_stop;                 // Ÿ�̸��� ����/���� ���¸� ��Ÿ���� ��������
        
        reg [16:0] clk_div;             // Ŭ�� ���ֱ�
        always @(posedge clk) clk_div = clk_div + 1; // Ŭ���� �����Ͽ� ���� Ŭ�� ��ȣ ����
        
//        assign buzz_clk = timeout_led ? clk_div[13] : 0; // Ÿ�Ӿƿ� �� ���� Ŭ�� ��ȣ ���
//        assign buzz = timeout_led; // Ÿ�Ӿƿ� �� ���� ��ȣ ���
        

                 
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
        
        // assign sw = alarm_off;
        
        // ���� �����
        edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), .cp(start_stop), 
                    .p_edge(load_enable)); 
        
                        
        // �� ���� ��ư ��Ʈ��
        button_cntr btn_inc_sec( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));
                
        // �� ���� ��ư ��Ʈ��
        button_cntr btn_inc_min( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));
                
         // ���� ��ư ��Ʈ��
        button_cntr start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2]));
                
//        // �˶� ���� ��ư ��Ʈ��
//        button_cntr btn_alarm_stop( 
//                .clk(clk), .reset_p(reset_p),
//                .btn(btn[3]), .btn_pedge(btn_pedge[3]));       
        
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
        assign {inc_sec, btn_start, inc_min} = btn_pedge;
       
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



module key_pad_test_top(
            input clk, reset_p,
            input [3:0] row,
            output [3:0] col,
            output [3:0] com,
            output [7:0] seg_7,
            output key_valid);
            
        wire [3:0] key_value;
        
        
        keypad_cntr_FSM keypad(clk, reset_p, row, col, key_value, key_valid );
        
        wire [15:0] value;
        assign value = {12'b0, key_value};
        fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
endmodule


module dht11_test_top(
           input clk, reset_p,
           inout dht11_data, 
           output [3:0] com,
           output [7:0] seg_7,
           output [15:0] led);
           
           wire  [7:0] humidity, temperature; 
           dht11_cntr dht11(clk, reset_p, dht11_data, humidity, temperature, led);

           wire [15:0] bcd_humi, bcd_tmpr;
           bin_to_dec b2d_humi(.bin({4'b0000, humidity}), .bcd(bcd_humi));
           bin_to_dec b2d_tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr)); 
            
           wire [15:0] value;
           assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};
           fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
            
            
endmodule


module uls_test_top(
           input clk, reset_p,
           input echo, 
           output trig,
           output [3:0] com,
           output [7:0] seg_7,
           output [15:0] led);
           
           wire  [15:0] distance;
           ultrasound_cntr uls(.clk(clk), .reset_p(reset_p), .echo(echo), .trig(trig), .distance(distance), .led(led));

           wire [15:0] distance_bcd;        // distance bcd ǥ�� 
           bin_to_dec b2d_distance(.bin(distance[11:0]), .bcd(distance_bcd));
           
           assign value = {distance_bcd};           
           fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(distance_bcd), .seg_7(seg_7), .com(com));
            
            
endmodule




module mf_watch_top(
    input clk, reset_p,          
    input [3:0] btn,                 
    input alarm_off,
    output [7:0] seg_7,             
    output [3:0] com,            
    output [15:0]led );


    parameter WATCH             = 3'b001;    
    parameter STOP_WATCH  = 3'b010; 
    parameter COOK_TIMER    = 3'b100; 
    
    wire [3:0]btn_pedge;
    wire alarm_off_pedge;
    
    reg [2:0] state, next_state;
    assign led[2:0] = state;
    
    
        button_cntr start( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0])
        );
        
        
        // ���� �����
        edge_detector_p ed(
                  .clk(clk), .reset_p(reset_p), .cp(alarm_off), 
                  .p_edge(alarm_off_pedge)); 
                    
        
        wire [15:0] w_value, stop_w_value, cook_w_value ;
        
        
        //��� ����� ���� Ÿ�̸� ���� ����
        wire w_clk, sw_clk, cw_clk; 
        
        assign cw_clk = (COOK_TIMER == state) ? clk : 0;
        assign sw_clk = (STOP_WATCH == state) ? clk : 0;
        assign w_clk = (WATCH == state) ? clk : 0;
        
        
        loadable_watch_exam_top inst(
                .clk(w_clk), .reset_p(reset_p),
                .btn(btn[3:1]), .value(w_value)
         );
                    
        stop_watch_exam_top inst1(
                .clk(sw_clk), .reset_p(reset_p),
                .btn(btn[2:1]), .value(stop_w_value)
        );
                
        cook_timer_exam inst2(
                .clk(cw_clk), .reset_p(reset_p),          
                .btn(btn[3:1]), . value(cook_w_value),
                .alarm_off(alarm_off_pedge),
                .timeout_led(led[3])
        );             
    
        reg [15:0] fnd_value;

        

        
    always @(negedge clk or posedge reset_p) begin
                    if (reset_p)
                        state = WATCH;  
                    else
                        state = next_state;  
                end
            

                always @(negedge clk or posedge reset_p) begin
                                    if (reset_p) begin         
                                             next_state = WATCH;      
                                     end
                            else begin
                                       
                 
                 case(state)    
                                WATCH : begin  
                                        if(btn_pedge) begin        
                                                next_state = STOP_WATCH;
                                        end
                                        else begin 
                                                fnd_value = w_value;
                                        end
                                end
                                STOP_WATCH : begin  
                                        if(btn_pedge) begin        
                                                next_state = COOK_TIMER;          
                                        end
                                        else begin
                                                fnd_value = stop_w_value ;
                                        end
                                end
                                COOK_TIMER : begin  
                                        if(btn_pedge) begin        
                                                next_state = WATCH;          
                                        end
                                        else begin
                                                fnd_value = cook_w_value ;
                                        end
                                end
                    endcase
            end
      end      
      
       fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(fnd_value), .seg_7(seg_7), .com(com));
endmodule




module led_pwm_top(
          input clk, reset_p,
          output led_pwm, led_r, led_g, led_b );
          
          
          reg [31:0] clk_div;
          always @(posedge clk) clk_div = clk_div + 1;
          
          pwm_128step_led pwm_led(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[27:21]),
                .pwm(led_pwm)
                );
                
          pwm_128step_led pwm_led_r(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[31:25]),
                .pwm(led_r)
                );
                
           pwm_128step_led pwm_led_g(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[30:24]),
                .pwm(led_g)
                );
                
            pwm_128step_led pwm_led_b(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[29:23]),
                .pwm(led_b)
                );

endmodule


module dc_motor_pwm_top(
          input clk, reset_p,      
          output motor_pwm,
          output [3:0] com,
          output [7:0] seg_7
          );
          
          
          reg [32:0] clk_div;
          always @(posedge clk) clk_div = clk_div + 1;
          
          pwm_128step_motor pwm_motor(
                .clk(clk),  .reset_p(reset_p),
                .duty(clk_div[32:26]),
                .pwm(motor_pwm)
                );
         
         wire [15:0] duty_bcd;       
         bin_to_dec b2d_distance(.bin({5'b0, clk_div[32:26]}), .bcd(duty_bcd));       
         
         fnd_4digit_cntr fnd(.clk(clk),  .value(duty_bcd), .seg_7(seg_7), .com(com));
endmodule



module servo_motor_pwm_top(
          input clk, reset_p,
          input [2:0] btn,
          output servo_pwm
          );
          
          
          reg [6:0] duty;

          // 128 pwm instance
          pwm_128step_servo pwm_motor(
                .clk(clk),  .reset_p(reset_p),
                .duty(duty),
                .pwm(servo_pwm)
                );
                
        
         wire [2:0]btn_pedge;
         
          // ��ư ��� - ��ư ��¿��� ����
          button_cntr mid( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0])
        );
        

           button_cntr left( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1])
        );
        
           button_cntr right( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2])
        );


          // ��ư - ���� ���� ����
          always @(negedge clk or posedge reset_p) begin
                    if (reset_p)begin
                            duty = 0 ;
                    end
                    
                    else if(btn_pedge[0])begin
                            duty = 9 ;     // 0
                    end
                    
                    else if(btn_pedge[1])begin
                            duty =  16;     // -90
                    end
                    
                    else if(btn_pedge[2])begin
                            duty = 3;        // 90
                    end
             end

endmodule




module servo_motor_pwm_top_um(
          input clk, reset_p,
          input  btn,
          output servo_pwm,
          output [3:0] com,
          output [7:0] seg_7
          );
          
          
          integer  clk_div;
          always @(posedge clk) clk_div = clk_div + 1;


         wire clk_div_nedge;
         wire btn_nedge;
         edge_detector_n ed(
                  .clk(clk), .reset_p(reset_p), .cp(clk_div[20]), 
                  .n_edge(clk_div_nedge)
        ); 
        
        button_cntr mid( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn), .btn_nedge(btn_nedge)
        );
        
          
          integer cnt;
          reg down_up;
          
          always @(posedge clk or posedge reset_p)begin
                   if(reset_p)begin
                        cnt = 6;
                        down_up = 0;
                   end      
                   else if(clk_div_nedge) begin
                            if(down_up)begin
                                    if (cnt <= 6)down_up = 0;
                                    else cnt = cnt - 1;
                            end
                            else begin
                                    if (cnt >= 32)down_up = 1;
                                   else cnt = cnt + 1;
                           end   
                    end      
           else if(btn_nedge)down_up = ~ down_up;
     end
 


          // 128 pwm instance
          pwm_128step_freq
           #(.pwm_freq(50)) 
          pwm_motor(
                .clk(clk),  .reset_p(reset_p),
                .duty(cnt),
                .pwm(servo_pwm)
                );
                
        
         wire [15:0] duty_bcd;
         
         bin_to_dec b2d_distance(.bin({cnt}), .bcd(duty_bcd));       
         
         fnd_4digit_cntr fnd(.clk(clk),  .value(duty_bcd), .seg_7(seg_7), .com(com));

endmodule





module adc_top (
        input clk, reset_p,
        input vauxp6, vauxn6,
        output [3:0] com,
        output [7:0] seg_7
);

    wire  [4:0]channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
    (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out)           // End of Conversion Signal
);
 
        
        wire eoc_out_pedge;
         edge_detector_p ed(
                  .clk(clk), .reset_p(reset_p), .cp(eoc_out), 
                  .p_edge(eoc_out_pedge)
        );   
         
         reg [11:0] adc_value;
         always @(posedge clk or posedge reset_p)begin
                    if(reset_p)adc_value = 0;
                    else if(eoc_out_pedge)begin
                           adc_value = do_out[15:4];
                    end
          end                     
        
          wire [15:0] adc_value_bcd;
          bin_to_dec btd_duty(.bin(adc_value), .bcd(adc_value_bcd));       
         
          fnd_4digit_cntr fnd(.clk(clk),  .value(adc_value_bcd), .seg_7(seg_7), .com(com));

endmodule




module led_dimmer_top (
        input clk, reset_p,
        input vauxp6, vauxn6,
        output led_pwm,
        output [3:0] com,
        output [7:0] seg_7
);

    wire  [4:0]channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_0 adc_ch6
    (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .reset_in(reset_p),            // Reset signal for the System Monitor control logic
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out)           // End of Conversion Signal
);
 
        
        wire eoc_out_pedge;
         edge_detector_p ed(
                  .clk(clk), .reset_p(reset_p), .cp(eoc_out), 
                  .p_edge(eoc_out_pedge)
        );   
         
         reg [11:0] adc_value;
         always @(posedge clk or posedge reset_p)begin
                    if(reset_p)adc_value = 0;
                    else if(eoc_out_pedge)begin
                           adc_value = do_out[15:4];
                    end
          end                     
        

          pwm_128step_led dimmer(
                .clk(clk),  .reset_p(reset_p),
                .duty(adc_value[11:5]),
                .pwm(led_pwm));
        
        
        
        
          wire [15:0] adc_value_bcd;
          bin_to_dec btd_duty(.bin({5'b0, do_out[11:5]}), .bcd(adc_value_bcd));       
         
          fnd_4digit_cntr fnd(.clk(clk),  .value(adc_value_bcd), .seg_7(seg_7), .com(com));

endmodule


module adc_sequence2_top(

    input clk,reset_p,              // �ý��� Ŭ�� �� ���� ��ȣ �Է�
    input vauxp6, vauxn6,           // ���� ä�� 6�� ��(+) �� ��(-) �Է�
    input vauxp15, vauxn15,         // ���� ä�� 15�� ��(+) �� ��(-) �Է�
    output led_r, led_g,            // LED ��� 
    output [3:0] com,               
    output [7:0] seg_7         
);

    wire [4:0] channel_out;         // ���õ� ADC ä�� ���
    wire eoc_out;                   // ��ȯ �Ϸ�(End of Conversion) ��ȣ ���
    wire [15:0] do_out;             // ADC ������ ���

    // XADC ������ ��� �ν��Ͻ�
    xadc_sequencer adc_seq2 (
        .daddr_in({2'b0, channel_out}), // ���� �籸�� ��Ʈ�� �ּ� ����
        .dclk_in(clk),                  // ���� �籸�� ��Ʈ�� Ŭ�� �Է�
        .den_in(eoc_out),               // ���� �籸�� ��Ʈ�� Ȱ��ȭ ��ȣ
        .reset_in(reset_p),             // �ý��� ����� ���� ������ ���� ��ȣ
        .vauxp6(vauxp6),                // ���� ä�� 6�� ��(+) �Է�
        .vauxn6(vauxn6),                // ���� ä�� 6�� ��(-) �Է�
        .vauxp15(vauxp15),              // ���� ä�� 15�� ��(+) �Է�
        .vauxn15(vauxn15),              // ���� ä�� 15�� ��(-) �Է�
        .channel_out(channel_out),      // ���õ� ä�� ���
        .do_out(do_out),                // ���� �籸�� ��Ʈ�� ������ ��� ����
        .eoc_out(eoc_out)               // ��ȯ �Ϸ� ��ȣ
    );
    
    wire eoc_out_pedge;               // ��ȯ �Ϸ� ��ȣ�� ��(+) ���� ���� ��ȣ
    edge_detector_n ed(
        .clk(clk), .reset_p(reset_p), 
        .cp(eoc_out), .p_edge(eoc_out_pedge)
    ); 

    reg [11:0] adc_value_x, adc_value_y;   // ADC ����� ������ ��������

    // ADC ���� �������Ϳ� �����ϴ� Always ���
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            adc_value_x = 0;           // ���� �� ADC ���� 0���� �ʱ�ȭ
            adc_value_y = 0;
        end
        else if (eoc_out_pedge) begin  // ��ȯ �Ϸ� ��ȣ�� ��(+) ���� ���� ��
            case (channel_out[3:0])
                6: adc_value_x = do_out[15 : 4];  // ä�� 6�� ADC ��� ����
                15: adc_value_y = do_out[15 : 4]; // ä�� 15�� ADC ��� ����
            endcase
        end                     
    end
    
     pwm_128step_led pwm_r(
        .clk(clk),  .reset_p(reset_p),
        .duty(adc_value_x[11:5]),
        .pwm(led_r));
                
     pwm_128step_led pwm_g(
        .clk(clk),  .reset_p(reset_p),
        .duty(adc_value_y[11:5]),
        .pwm(led_g));
    


    wire [15:0] value, adc_value_bcd_x, adc_value_bcd_y;
    
    // ADC ����� BCD�� ��ȯ
    bin_to_dec bcd_x(
        .bin({6'b0, adc_value_x[11:6]}), 
        .bcd(adc_value_bcd_x)
    );       
    bin_to_dec bcd_y(
        .bin({6'b0, adc_value_y[11:6]}), 
        .bcd(adc_value_bcd_y)
    );
    
    // 4�ڸ� 7-���׸�Ʈ ���÷��̿� ǥ���� ���� ����
    assign value = {adc_value_bcd_x[7:0], adc_value_bcd_y[7:0]};
    
    // 4�ڸ� 7-���׸�Ʈ ���÷��� ���� ��� �ν��Ͻ�
    fnd_4digit_cntr fnd(
        .clk(clk), 
        .value(value), 
        .seg_7(seg_7), 
        .com(com)
    );

endmodule



module I2C_master_top(
            input clk, reset_p,
            input [1:0]btn,
            output sda, scl,
            output [6:0]led);
    
            reg [7:0] data;
            reg comm_go;
    
    
            I2C_master(
                        .clk(clk), 
                        .reset_p(reset_p),
                        .addr(7'h27), 
                        .data(data), 
                        .rd_wr(0), 
                        .comm_go(comm_go), 
                        .sda(sda), 
                        .scl(scl),
                        .led(led));
                        
            wire [1:0] btn_pedge;
            button_cntr btn_0( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));
           
             button_cntr btn_1( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));
            
            always @(posedge clk or posedge reset_p) begin
                    if(reset_p)begin
                            data = 0;
                            comm_go = 0;
                    end
                    else begin
                            if(btn_pedge[0])begin
                                   data = 8'b0000_0000;
                                   comm_go = 1;              
                            end
                            else if(btn_pedge[1])begin
                                    data = 8'b1111_1111;
                                    comm_go = 1;
                            end
                            else comm_go = 0;
                     end
              end
                          
endmodule



module i2c_txtlcd_test_top(
        input clk, reset_p,            // �ý��� Ŭ���� ���� ��ȣ �Է�
        input [3:0]btn,                // 4���� ��ư �Է�
        output scl, sda);              // I2C Ŭ���� ������ ���� ���

        // ���� ����: �� ���´� 6��Ʈ�� ǥ��
        parameter IDLE                                 = 6'b00_0001;  // ��� ����
        parameter INIT                                  = 6'b00_0010;  // �ʱ�ȭ ����
        parameter SEND_BYTE                     = 6'b00_0100;  // ������ ���� ����
        parameter SHIFT_RIGHT_DISPLAY   = 6'b00_1000;  
        parameter SHIFT_LEFT_DISPLAY     = 6'b01_0000;  
        
        
        // 100us ������ Ŭ�� ����
        wire clk_usec;
        clock_div_100 usec_clk(
                .clk(clk),                  // �Է� Ŭ��
                .reset_p(reset_p),          // ���� ��ȣ
                .clk_div_100(clk_usec)      // 100us ���� Ŭ�� ���
            );
        
        // 100us ������ ī��Ʈ�ϴ� �������� �� ī���� Ȱ��ȭ ��ȣ
        reg [21:0] count_usec;  
        reg count_usec_e;       

        // ī���� ����
        always @(negedge clk or posedge reset_p) begin
            if (reset_p) begin
                count_usec = 0;  // ���� �� ī���� �ʱ�ȭ
            end else begin
                if (clk_usec && count_usec_e) 
                    count_usec = count_usec + 1;  // ī���� ����
                else if (!count_usec_e) 
                    count_usec = 0;  // ī���� �ʱ�ȭ
            end
        end
        
        // ��ư�� ��� ����(pedge) ������ ���� ����
        wire [3:0] btn_pedge;
        button_cntr btn_0( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[0]), .btn_pedge(btn_pedge[0]));   // ��ư 0�� ��� ���� ����

        button_cntr btn_1( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[1]), .btn_pedge(btn_pedge[1]));   // ��ư 1�� ��� ���� ����

        button_cntr btn_2( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[2]), .btn_pedge(btn_pedge[2]));   // ��ư 2�� ��� ���� ����

        button_cntr btn_3( 
                .clk(clk), .reset_p(reset_p),
                .btn(btn[3]), .btn_pedge(btn_pedge[3]));   // ��ư 3�� ��� ���� ����

        // I2C LCD�� ������ ������ ���ۿ� ���� ��ȣ��
        reg [7:0] send_buffer;  // ������ ������ ����
        reg send, rs;           // ���� ���� ��ȣ �� �������� ���� ��ȣ
        wire busy;              // I2C ���� �� ���� ��ȣ
        
        // I2C LCD ���� ������ ����
        i2c_lcd_send_byte(.clk(clk), .reset_p(reset_p),
                .addr(7'h27),                  // LCD�� I2C �ּ�
                .send_buffer(send_buffer),     // ������ ������ ����
                .send(send),                   // ���� ���� ��ȣ
                .rs(rs),                       // �������� ���� ��ȣ (���/������)
                .scl(scl),                     // I2C Ŭ�� ���
                .sda(sda),                     // I2C ������ ���
                .busy(busy));                  // I2C ���� �� ���� ��ȣ
        
        // FSM ���� ��������
        reg [5:0] state, next_state;
        always @(negedge clk or posedge reset_p) begin
            if (reset_p)
                state = IDLE;  // ���� �� �ʱ� ���·� ��ȯ
            else 
                state = next_state;  // ���� ���·� ����
        end
        
        // �ʱ�ȭ �÷��� �� ������ ī����
        reg init_flag;
        reg [5:0] cnt_data; // 2^3 = 8 -> A B C D E F G H 
        
        // FSM ���� ���� �� ����
        always @(posedge clk or posedge reset_p) begin
            if (reset_p) begin
                init_flag = 0;            // �ʱ�ȭ �÷��� �ʱ�ȭ
                next_state = IDLE;        // IDLE ���·� ��ȯ
                send = 0;                 // ���� ��Ȱ��ȭ
                send_buffer = 0;          // ������ ���� �ʱ�ȭ
                cnt_data = 0;             // ������ ī���� �ʱ�ȭ
                rs = 0;                   // �������� ���� �ʱ�ȭ
            end else begin
                case(state)
                    IDLE: begin
                        if (init_flag) begin
                            if (btn_pedge[0]) next_state = SEND_BYTE;  // ��ư�� ������ SEND_BYTE ���·� ��ȯ                               
                            if(btn_pedge[1])  next_state = SHIFT_LEFT_DISPLAY;  
                            if(btn_pedge[2])  next_state = SHIFT_RIGHT_DISPLAY;  
                        end else begin
                            if (count_usec <= 22'd80_000) begin
                                count_usec_e = 1;  // 80ms ���� ���
                            end else begin
                                init_flag = 1;  // �ʱ�ȭ �Ϸ� �÷��� ����
                                next_state = INIT;  // INIT ���·� ��ȯ
                                count_usec_e = 0;  // ī���� ��Ȱ��ȭ
                            end
                        end
                    end
                    INIT: begin
                        if (busy) begin
                            send = 0;  // ���� �Ϸ� �� ���� ��Ȱ��ȭ
                            if (cnt_data >= 6) begin
                                cnt_data = 0;  // ������ ī���� �ʱ�ȭ
                                next_state = IDLE;  // IDLE ���·� ��ȯ
                                init_flag = 1;  // �ʱ�ȭ �Ϸ� �÷��� ����
                            end
                        end else if(send == 0) begin
                            case(cnt_data)
                                0: send_buffer = 8'h33;  // �ʱ�ȭ ��� ����
                                1: send_buffer = 8'h32;
                                2: send_buffer = 8'h28;
                                3: send_buffer = 8'h0c;
                                4: send_buffer = 8'h01;
                                5: send_buffer = 8'h06;
                            endcase
                            send = 1;  // ������ ���� ����
                            cnt_data = cnt_data + 1;  // ������ ī���� ����
                        end
                    end
                    SEND_BYTE: begin
                        if (busy) begin
                            next_state = IDLE;  // ���� �Ϸ� �� IDLE ���·� ��ȯ
                            send = 0;  // ���� ��Ȱ��ȭ
                            if(cnt_data >= 9) cnt_data = 0;
                            cnt_data = cnt_data + 1;
                        end 
                        else begin
                            rs = 1;  // ������ ���� ����
                            send_buffer = "0" + cnt_data;  // ������ ������ ����
                            send = 1;  // ���� ����
                        end
                 end 
                         SHIFT_LEFT_DISPLAY: begin
                            if (busy) begin
                                next_state = IDLE;  // ���� �Ϸ� �� IDLE ���·� ��ȯ
                                send = 0;  // ���� ��Ȱ��ȭ
                        end 
                        else begin
                            rs = 0;  // ������ ���� ����
                            send_buffer = 8'h18;  // ������ ������ ����
                            send = 1;  // ���� ����
                        end
                     end
                         SHIFT_RIGHT_DISPLAY: begin
                            if (busy) begin
                                next_state = IDLE;  // ���� �Ϸ� �� IDLE ���·� ��ȯ
                                send = 0;  // ���� ��Ȱ��ȭ
                        end 
                        else begin
                            rs = 0;  // ������ ���� ����
                            send_buffer = 8'h1c;  // ������ ������ ����
                            send = 1;  // ���� ����
                        end
                    end
                endcase
            end
        end
        
endmodule



module stop_watch_reg(
    input clk, reset_p,
    input [1:0] control_reg,
    output [3:0] com,
    output [7:0] seg_7
);
    
    wire start_stop, lap, lap_pedge;
    assign {start_stop, lap} = control_reg;
    
    edge_detector_p ed_div(
        .clk(clk), .reset_p(reset_p), .cp(lap), .p_edge(lap_pedge));
       
    
    wire clk_start;
    assign clk_start = start_stop ? clk : 0;
    
    wire clk_usec, clk_msec, clk_min;
    clock_div_100 usec_clk(                              
        .clk(clk_start),                          // clk�� clk�� ��Ʈ�� ����              
        .reset_p(reset_p),                  // reset_p�� reset_p�� ��Ʈ�� ����      
        .cp_div_100(clk_usec)
    );             // clk_usec�� cp_div_100�� ��Ʈ�� ����          
     
    clock_div_1000 msec_clk(
        .clk(clk_start),                         // clk�� clk�� ��Ʈ�� ����                   
        .reset_p(reset_p),                 // reset_p�� reset_p�� ��Ʈ�� ����           
        .clk_source(clk_usec),               
        .cp_div_1000_nedge(clk_msec)
    );       
      
    clock_div_1000 sec_clk(
        .clk(clk_start),
        .reset_p(reset_p),        
        .clk_source(clk_msec),      
        .cp_div_1000_nedge(clk_sec)
    );    
      
    clock_div_60 min_clk(
        .clk(clk_start),
        .reset_p(reset_p),  
        .clk_source(clk_sec),
        .cp_div_60_nedge(clk_min)
    );
    
    wire [3:0] sec1, sec10, min1, min10;
    counter_bcd_60 counter_sec(
        .clk(clk), .reset_p(reset_p),
        .clk_time(clk_sec),
        .bcd1(sec1), .bcd10(sec10)
    );

    counter_bcd_60 counter_min(
        .clk(clk), .reset_p(reset_p),
        .clk_time(clk_min),
        .bcd1(min1), .bcd10(min10)
    );
    
    wire [15:0] cur_time;
    assign cur_time = {min10, min1, sec10, sec1};
    reg [15:0] lap_time;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)lap_time = 0;
        else if(lap_pedge)lap_time = cur_time;
    end
        
    wire [15:0] value;

    assign value = lap ? lap_time : cur_time;
    fnd_4digit_cntr fnd(clk, reset_p, value, seg_7, com);
    
endmodule

