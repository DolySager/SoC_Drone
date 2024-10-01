`timescale 1ns / 1ps

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
