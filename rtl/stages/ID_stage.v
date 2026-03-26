// ID_stage.v
// IF_ID 레지스터의 출력 명령어를 해독하고, 범용 레지스터 파일의 읽기 값 및 누산기 값을 이용해 제어 신호와 피연산자를 생성합니다.
// 이 모듈은 실제 레지스터 파일 읽기는 상위 모듈(cpu_pipeline.v)에서 수행한 후 읽은 값을 입력으로 받습니다.
`timescale 1ns / 1ps
module ID_stage(
    input  wire clk,
    input  wire rst,
    input  wire [2:0] in_opcode,   // IF_ID 레지스터로부터 전달받은 opcode
    input  wire [4:0] in_ad1,      // 피연산자(레지스터 주소) 필드
    input  wire [7:0] in_imm,      // 즉치(immediate) 값 (필요한 경우)
    input  wire [7:0] reg_data,    // 범용 레지스터 파일에서 읽은 데이터 (주소: in_ad1)
    input  wire [7:0] acc_value,   // 현재 누산기(accum) 값
    output reg  [2:0] out_opcode,  // EX 단계로 전달할 opcode
    output reg  [4:0] out_dest,    // 목적 레지스터 번호 (주로 in_ad1 사용)
    output reg  [7:0] out_imm,     // 즉치값 그대로 전달
    output reg  [7:0] out_reg_val, // ID 단계에서 읽은 범용 레지스터 값 (필요 시 EX_stage로 전달)
    output reg  [7:0] out_acc_val, // 누산기 값 (EX_stage 연산 시 사용)
    output reg        out_reg_write, // 레지스터 파일 쓰기 제어 (EX_stage에서 write-back)
    output reg        out_mem_write  // 데이터 메모리 쓰기 제어
);
    always @* begin
        // 기본값: 별다른 동작이 없으면 NOP로 처리
        out_opcode   = in_opcode;
        out_dest     = in_ad1;
        out_imm      = in_imm;
        out_reg_val  = reg_data;
        out_acc_val  = acc_value;
        out_reg_write = 1'b0;
        out_mem_write = 1'b0;
        
        case(in_opcode)
            3'b000: begin // NOP
                out_reg_write = 1'b0;
                out_mem_write = 1'b0;
            end
            3'b111: begin // HLT: CPU 정지 (추후 EX_stage에서 halt 신호 생성)
                out_reg_write = 1'b0;
                out_mem_write = 1'b0;
            end
            3'b001: begin // LDO: ROM에서 읽은 데이터(외부에서 읽어온 값을 EX_stage에서 사용)를 레지스터에 로드
                out_reg_write = 1'b1; // EX_stage에서 write-back 수행
                out_mem_write = 1'b0;
            end
            3'b010: begin // LDA: RAM에서 읽은 데이터를 레지스터에 로드
                out_reg_write = 1'b1;
                out_mem_write = 1'b0;
            end
            3'b011: begin // STO: 범용 레지스터 값을 데이터 메모리에 저장
                out_reg_write = 1'b0;
                out_mem_write = 1'b1;
                //out_reg_val   = reg_data;  // 저장할 데이터는 reg_file에서 읽은 값
					 out_reg_val   = reg_data;
            end
            3'b100: begin // PRE: 범용 레지스터 값을 누산기에 로드
                out_reg_write = 1'b0;
                out_mem_write = 1'b0;
                out_reg_val   = reg_data;
            end
            3'b101: begin // ADD: 누산기와 범용 레지스터 값을 더해 누산기를 갱신
                out_reg_write = 1'b0;
                out_mem_write = 1'b0;
					 out_reg_val   = reg_data;
             
            end
            3'b110: begin // LDM: 누산기 값을 범용 레지스터에 저장
                out_reg_write = 1'b1;
                out_mem_write = 1'b0;
            end
            default: begin
                out_opcode    = out_opcode;
                out_dest      = out_dest;
                out_imm       = out_imm;
                out_reg_val   = out_reg_val;
                out_acc_val   = acc_value;
                out_reg_write = out_reg_write;
                out_mem_write = out_mem_write;
            end
        endcase
    end
endmodule
