`timescale 1ps / 1ps
module core_tb_00;

  reg clk;
  reg rst;
  
  // 상위 모듈 cpu_pipeline 인스턴스화
  cpu_pipeline DUT (
    .clk(clk),
    .rst(rst)
  );

  // Clock Pattern: dutyCycle = 50%
  // 시작 시간 0 ps, period 100 ps, 초기 150 ps 대기 후 반복 시작
  initial begin
      clk = 1'b0;
      #100;
      // 99회 반복: 매 반복마다 50 ps 동안 1, 50 ps 동안 0
      repeat(99) begin
          clk = 1'b1;
          #50;
          clk = 1'b0;
          #50;
      end
      clk = 1'b1;
      #50;
  end

  // Reset 생성: 초기 100 ps 동안 rst = 0, 이후 rst = 1로 설정
  initial begin
      rst = 1'b0;
      #150;
      rst = 1'b1;
      #9000;
  end

  // 시뮬레이션 종료: 20000 ps 후 시뮬레이션 정지
  initial begin
      #200000 $stop;
  end

  // 내부 신호 모니터링:
  // - IF_stage 내의 PC
  // - 상위 모듈 내 누산기(accum)
  // - 각 단계의 opcode 신호
  // - EX_stage의 halt 신호 (HLT 명령 발생 시)
  initial begin
      $monitor("Time=%0t | PC=%h | ACC=%h | IF_opcode=%b | IF_valid=%b | ID_opcode=%b | EX_opcode=%b | HLT=%b",
               $time,
               DUT.if_stage_inst.PC,         // IF_stage 내부의 프로그램 카운터
               DUT.accum,                    // 상위 모듈 내 누산기
               DUT.if_stage_inst.out_opcode, // IF_stage 출력 opcode
               DUT.if_stage_inst.out_valid,  // IF_stage의 유효 신호
               DUT.if_id_reg_inst.out_opcode,// IF_ID 레지스터를 통해 전달된 ID 단계 opcode
               DUT.id_stage_inst.out_opcode, // ID_stage에서 해독된 opcode (EX 단계로 전달될 값)
               DUT.ex_stage_inst.halt        // EX_stage에서 HLT 명령 시 설정되는 halt 신호
      );
  end

endmodule
