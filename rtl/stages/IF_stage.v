`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// IF_stage.v
// 명령어 인출 단계: PC와 외부 ROM 모듈을 통해 명령어를 읽어, 1바이트 또는 2바이트 명령어를 구성합니다.
//////////////////////////////////////////////////////////////////////////////////
module IF_stage(
    input  wire clk,          // 시스템 클럭
    input  wire rst,          // 비동기 리셋 (LOW 활성)
    input  wire stall,        // IF 단계 스톨 제어 (해저드 발생 시 1)
    input  wire halt,  
	 // HLT 명령 시 동작 정지
    output reg  [2:0] out_opcode, // 명령어 opcode (상위 3비트)
    output reg  [4:0] out_ad1,    // 명령어 피연산자 필드 (하위 5비트)
    output reg  [7:0] out_imm,    // 즉치(immediate) 데이터 (2바이트 명령어의 두번째 바이트)
    output reg  out_valid        // 해당 사이클에 유효한 명령어가 준비되었는지
);
    // 프로그램 카운터(8비트, 0~255 주소)
    reg [7:0] PC;
    // 2바이트 명령어의 첫 바이트 임시 저장
    reg [7:0] inst_buf;
    // 2바이트 명령어 처리 상태: 즉치(immediate) 바이트를 기다리는 중이면 1
    reg waiting_for_imm;
    
    // 외부 ROM 모듈 인스턴스화
    // 이 모듈은 별도의 ROM 모듈(예: 위에 제공된 rom 모듈)을 사용합니다.
    wire [7:0] rom_data;
    rom rom_inst (
        .data(rom_data),
        .addr(PC),
        .read(1'b1),
        .ena(1'b1)
    );


    // IF 단계 동작: 매 클럭마다 명령어 페치 및 PC 업데이트
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            PC             <= 8'd0;
            waiting_for_imm<= 1'b0;
            out_valid      <= 1'b0;
            out_opcode     <= 3'd0;
            out_ad1        <= 5'd0;
            out_imm        <= 8'd0;
        end else if (halt) begin
            // HLT 발생 시 동작 정지
            PC        <= PC;
            out_valid <= 1'b0;
        end else if (stall) begin
            // 스톨 시 PC 및 출력 유지 (새 명령어 전달하지 않음)
            PC        <= PC;
            out_valid <= 1'b0;
        end else begin
            if (!waiting_for_imm) begin
                // 첫 번째 바이트 페치
                inst_buf <= rom_data;
                // opcode가 001 (LDO), 010 (LDA), 011 (STO)인 경우 2바이트 명령어 처리
                if (rom_data[7:5] == 3'b001 || rom_data[7:5] == 3'b010 || rom_data[7:5] == 3'b011) begin
                    waiting_for_imm <= 1'b1;  // 다음 사이클에 즉치값을 읽어옴
                    PC <= PC + 1;
                    out_valid <= 1'b0;        // 아직 명령어 완성되지 않음
						  //out_opcode <= inst_buf[7:5];
                end else begin
                    // 1바이트 명령어: 바로 출력
                    out_opcode <= rom_data[7:5];
                    out_ad1    <= rom_data[4:0];
                    out_imm    <= 8'bz;
                    out_valid  <= 1'b1;
                    PC <= PC + 1;
                end
            end else begin
                // waiting_for_imm == 1: 즉치값 읽기
						if (rom_data[7:5] == 3'b011) begin
							out_opcode <= inst_buf[7:5];
							out_ad1    <= inst_buf[4:0];
							out_imm    <= rom_data;   // 이번 사이클의 rom_data가 즉치값
							out_valid  <= 1'b1;
							waiting_for_imm <= 1'b0;
							PC <= PC + 1;
						 
                  end
						else begin
							out_opcode <= inst_buf[7:5];
							out_ad1    <= inst_buf[4:0];
							out_imm    <= rom_data;   // 이번 사이클의 rom_data가 즉치값
							out_valid  <= 1'b1;
							waiting_for_imm <= 1'b0;
							PC <= PC + 1;
						end
            end
        end
    end
endmodule