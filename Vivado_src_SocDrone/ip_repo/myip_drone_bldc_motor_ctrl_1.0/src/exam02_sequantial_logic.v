`timescale 1ns / 1ps

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
