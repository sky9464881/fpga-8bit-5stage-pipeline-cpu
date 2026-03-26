`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// cpu_pipeline.v
// 5단계 파이프라인 CPU 상위 모듈
// 기존 3단계(IF, ID, EX) 모듈을 유지하고, MEM, WB 단계를 추가 연결
////////////////////////////////////////////////////////////////////////////////
module cpu_pipeline(
    input wire clk,
    input wire rst,
    input wire button,    // KEY[3]
    input wire key_down,      // KEY[1]
    input wire key_up,        // KEY[2]
    input wire key_enter,     // KEY[0]
    input wire [9:0] switches,// SW[9:0]
    output reg [6:0] hex0,
    output reg [6:0] hex1,
    output reg [6:0] hex2,
    output reg [6:0] hex5,
	 output [9:0] LEDR
);
    // ---------------------------
    // IF_stage -> IF_ID_reg 사이 신호
    // ---------------------------
    wire [2:0] if_opcode;
    wire [4:0] if_ad1;
    wire [7:0] if_imm;
    wire       if_valid;
    wire [7:0] wb_accum_val;
    wire [7:0] alu_result;
    wire [7:0] wb_mem_wr_data;
	 // pipeline_start가 1일 때 reset 활성화 (active-low reset 구조)
	 reg pipeline_start = 0;  // ✅ 리셋 트리거 신호 (1클럭 HIGH)
    wire cpu_rst = ~pipeline_start;
    // IF 단계 스톨 및 HLT 신호 (현재 해저드 없음, halt 기본 0)
	 reg if_stage_stall;

always @(posedge clk or negedge cpu_rst) begin
    if (!cpu_rst)
        if_stage_stall <= 0;
    else if ((if_opcode==3'b011 && !if_stage_stall))//(if_opcode==3'b100 && !if_stage_stall)||(if_opcode==3'b101 && !if_stage_stall))
        if_stage_stall <= 1;  // PRE 명령어일 때 1클럭만 stall
    else
        if_stage_stall <= 0;
end
	 
    wire halt_signal;
    // IF_stage 인스턴스 (명령어 인출)
    IF_stage if_stage_inst (
        .clk(clk),
        .rst(cpu_rst),
        .stall(1'b0),
        .halt(1'b0),           // EX_stage의 halt_signal을 연결 가능 (현재 미사용)
        .out_opcode(if_opcode),
        .out_ad1(if_ad1),
        .out_imm(if_imm),
        .out_valid(if_valid)
    );
    
    // ---------------------------
    // IF_ID 레지스터 (IF -> ID)
    // ---------------------------
    wire [2:0] id_opcode;
    wire [4:0] id_ad1;
    wire [7:0] id_imm;
    wire       id_valid;
    IF_ID_reg if_id_reg_inst (
        .clk(clk),
        .rst(cpu_rst),
        .stall(1'b0),
        .in_valid(if_valid),
        .in_opcode(if_opcode),
        .in_ad1(if_ad1),
        .in_imm(if_imm),
        .out_opcode(id_opcode),
        .out_ad1(id_ad1),
        .out_imm(id_imm),
        .out_valid(id_valid)
    );
    
    // ---------------------------
    // 범용 레지스터 파일 (32 x 8비트) 및 누산기(accumulator)
    // ---------------------------
    reg [7:0] reg_file [0:31];
    reg [7:0] accum;
    integer j;
    // ID 단계에서 사용할 레지스터 읽기 데이터 (동기 읽기: 조합논리로 단순 할당)
	 reg [7:0] reg_data;
	 wire [2:0] ex_opcode;
    wire [4:0] ex_dest;
	 wire [2:0] id_ex_opcode;
    wire [4:0] id_ex_dest;
always @(posedge clk or negedge cpu_rst) begin
    if (!cpu_rst) begin
        reg_data <= 8'd0;
    end else  if (id_opcode == 3'b011 || id_opcode == 3'b100 || id_opcode == 3'b101) begin
            reg_data <= reg_file[id_ad1];
        end
        // else 아무것도 하지 않으면 → 값 유지됨
    end
	 
    // ---------------------------
    // ID_stage: 명령 해독 및 오퍼랜드 준비
    // ---------------------------
 
    wire [7:0] id_ex_imm;
    wire [7:0] id_ex_reg_val;
    wire [7:0] id_ex_acc_val;    // 누산기 값 (ID_EX_reg로 전달)
    // 제어 신호 (레지스터/메모리 쓰기)
    wire       id_ex_reg_write;
    wire       id_ex_mem_write;
    ID_stage id_stage_inst (
        .clk(clk),
        .rst(cpu_rst),
        .in_opcode(id_opcode),
        .in_ad1(id_ad1),
        .in_imm(id_imm),
        .reg_data(5'b00000),      // 범용 레지스터 파일에서 읽은 값
        .acc_value(accum),        // 현재 누산기(accum) 값
        .out_opcode(id_ex_opcode),
        .out_dest(id_ex_dest),
        .out_imm(id_ex_imm),
        .out_reg_val(id_ex_reg_val),
        .out_acc_val(id_ex_acc_val),
        .out_reg_write(id_ex_reg_write),
        .out_mem_write(id_ex_mem_write)
    );
    
    // ---------------------------
    // ID_EX 레지스터 (ID -> EX)
    // ---------------------------
   
    wire [7:0] ex_imm;
    wire [7:0] ex_reg_val;
    wire [7:0] ex_acc_val;
    wire       ex_reg_write;
    wire       ex_mem_write;
    ID_EX_reg id_ex_reg_inst (
        .clk(clk),
        .rst(cpu_rst),
        .in_opcode(id_ex_opcode),
        .in_dest(id_ex_dest),
        .in_imm(id_ex_imm),
        .in_reg_val(id_ex_reg_val),
        .in_acc_val(id_ex_acc_val),
        .in_reg_write(id_ex_reg_write),
        .in_mem_write(id_ex_mem_write),
        .out_opcode(ex_opcode),
        .out_dest(ex_dest),
        .out_imm(ex_imm),
        .out_reg_val(ex_reg_val),
        .out_acc_val(ex_acc_val),
        .out_reg_write(ex_reg_write),
        .out_mem_write(ex_mem_write)
    );
    
    // ---------------------------
    // EX_stage: 연산 수행 (기존 EX 단계 유지)
    // ---------------------------
    wire [7:0] wire_forwarding;
	 wire [2:0] ex_reg_opcode;
	 reg [7:0] forwarding;
	 always @(posedge clk or negedge cpu_rst) begin // pre명령어를 위한 forwarding accumlater에 업데이트 되기전에 미리 data forwarding 
    if (!cpu_rst) begin
        forwarding <= 8'd0;
    end else  begin
            forwarding <= wire_forwarding;
        end
        // else 아무것도 하지 않으면 → 값 유지됨
    end

	 wire ex_out_reg_write;
	 wire [7:0] wb_reg_data;
    wire       mem_reg_write;
    wire [7:0] mem_wb_reg;
	 wire [4:0] mem_wb_dest;
	 wire mem_wb_reg_write;
	 wire [4:0] wb_dest;
	 wire wb_reg_write;
	 reg [7:0] forwarding_reg;
	 always @(*) begin
		if ((ex_dest == mem_wb_dest) && ex_out_reg_write) begin
			forwarding_reg = mem_wb_reg;  // forwarding from MEM
		end else if ((ex_dest == wb_dest) && mem_reg_write) begin
			forwarding_reg = wb_reg_data;   // forwarding from WB
		end else begin
			forwarding_reg = reg_data; // 그냥 읽기
		end
	end
	 
    
    wire ex_out_mem_write;
    wire [4:0] ex_out_dest;
    wire [7:0] ex_out_mem_data;
    wire ex_halt;
    EX_stage ex_stage_inst (
        .clk(clk),
        .rst(cpu_rst),
        .in_opcode(ex_opcode),
        .in_dest(ex_dest),
        .in_imm(ex_imm),
        .in_reg_val(forwarding_reg),
        .in_acc_val(ex_acc_val),
		  .in_forwarding(forwarding),
        .in_reg_write(ex_reg_write),
        .in_mem_write(ex_mem_write),
        .alu_result(alu_result),         // 연산 결과 (콤비네이션 출력)
        .out_reg_write(ex_out_reg_write),
        .out_mem_write(ex_out_mem_write),
        .out_dest(ex_out_dest),
        .out_mem_data(ex_out_mem_data),
		  .out_forwarding(wire_forwarding),
		  .out_opcode(ex_reg_opcode),
        .halt(ex_halt)
    );
    
    // **주의**: EX_stage 내부에서 data memory(ram) 접근을 수행하지만, 5단계 파이프라인에서는 
    // 메모리 쓰기/읽기를 새로운 MEM, WB 단계에서 처리할 것이므로, EX_stage의 메모리 관련 출력은 
    // 제어신호로만 사용하고 실제 메모리 갱신은 수행하지 않습니다.
    
    // ---------------------------
    // EX_MEM 레지스터 (EX -> MEM)
    // ---------------------------
    wire [2:0] mem_opcode;
    wire       mem_mem_write;
    wire [4:0] mem_dest;
    wire [7:0] mem_imm;
    wire [7:0] mem_alu_result;
    wire [7:0] mem_ex_data;
    EX_MEM_reg ex_mem_reg_inst (
        .clk(clk),
        .rst(cpu_rst),
        .in_opcode(ex_opcode),         // ID_EX_reg에서 바로 가져온 opcode (제어용)
        .in_reg_write(ex_out_reg_write),
        .in_mem_write(ex_out_mem_write),
        .in_dest(ex_dest),
        .in_imm(ex_imm),
        .in_alu_result(alu_result),
        .in_mem_data(ex_out_mem_data),
        .out_opcode(mem_opcode),
        .out_reg_write(mem_reg_write),
        .out_mem_write(mem_mem_write),
        .out_dest(mem_dest),
        .out_imm(mem_imm),
        .out_alu_result(mem_alu_result),
        .out_mem_data(mem_ex_data)
    );
    
    // ---------------------------
    // 데이터 메모리 (RAM) 모듈 인스턴스
    // ---------------------------
    wire [7:0] data_mem_out;
	 wire wb_mem_write;
	 wire [7:0] wb_mem_data;
	 wire [7:0] wb_mem_addr;
	 wire [7:0] mem_address;
	 wire mem_wb_mem_write;
    // 데이터 메모리 접근을 위해 단일 RAM 인스턴스를 사용합니다.
    // 읽기 주소는 MEM 단계의 주소(mem_imm)를 사용하고,
    // 쓰기 제어는 WB 단계의 신호를 사용하도록 연결합니다.
	 
	 reg prev_sw8;
  	 wire sw8_falling_edge;

	 always @(posedge clk) begin
		 prev_sw8 <= switches[8];
	 end

	 assign sw8_falling_edge = (prev_sw8 == 1'b1 && switches[8] == 1'b0);

	 
	 ram data_memory_inst (
    .clk(clk),
    .rst(cpu_rst),
    .ex_out_mem_write(mem_wb_mem_write),
    .ena(1'b1),
    .ex_imm(mem_imm),
    .ex_write_address(wb_mem_addr),
    .ex_out_mem_data(wb_mem_wr_data),
    .sw8_write_en(sw8_falling_edge),               // ✅ SW8 write
    .sw8_addr(user_digit[7:0]),
    .sw8_data(switches[7:0]),
    .data_mem(data_mem_out)
);
	 
    // 메모리 주소 선택:
    // 메모리 읽기와 쓰기 요청이 동시에 발생할 수 있으므로, 우선순위에 따라 주소 선택
    // - WB 단계에서 메모리 쓰기 신호가 활성화된 사이클에는 wb_mem_addr를 우선 사용하여 정확한 주소에 쓰기를 수행합니다.
    wire [2:0] wb_opcode;
	 wire [7:0] mem_wb_data;
    reg [7:0] forwarding_ram;
	 wire [7:0] wb_imm;
		always @(*) begin	 
		if ((wb_opcode ==  3'b011) &&(mem_opcode == 3'b010) &&(wb_imm == mem_imm)) begin
				forwarding_ram = wb_reg_data;  // forwarding
		end else begin
			 forwarding_ram = data_mem_out;      // 평소처럼 메모리 접근
		end
		end

    // ---------------------------
    // MEM_stage: 메모리 접근 (읽기 전용)
    // ---------------------------
    wire [7:0] mem_wb_imm;
    wire [7:0] mem_wb_acc;
	 wire [2:0] mem_wb_opcode;
	
    MEM_stage mem_stage_inst (
        .clk(clk),
        .rst(cpu_rst),
        .in_opcode(mem_opcode),
        .in_reg_write(mem_reg_write),
        .in_mem_write(mem_mem_write),
        .in_dest(mem_dest),
        .in_imm(mem_imm),
        .in_alu_result(mem_alu_result),
        .in_mem_data(forwarding_ram),
        .mem_read_data(data_mem_out),   // RAM으로부터 현재 mem_imm 주소의 데이터 출력
        .out_reg_write(mem_wb_reg_write),
		  .out_wb_opcode(mem_wb_opcode),
        .out_mem_write(mem_wb_mem_write),
        .out_dest(mem_wb_dest),
        .out_imm(mem_wb_imm),
        .out_acc_data(mem_wb_acc),
        .out_mem_data(mem_wb_data),
		  .out_reg_data (mem_wb_reg)
    );
    
    // ---------------------------
    // MEM_WB 레지스터 (MEM -> WB)
    // ---------------------------
    wire [7:0] wb_value;
	 wire [7:0] mem_wb_reg_data;
	 
    MEM_WB_reg mem_wb_reg_inst (
        .clk(clk),
        .rst(cpu_rst),
		  .in_reg_data(mem_wb_reg),
        .in_reg_write(mem_wb_reg_write),
        .in_mem_write(mem_wb_mem_write),
        .in_dest(mem_wb_dest),
        .in_imm(mem_wb_imm),
        .in_acc_data(mem_wb_acc),
        .in_mem_data(mem_wb_data),
		  .in_wb_opcode(mem_wb_opcode),
        .out_reg_write(wb_reg_write),
		  .out_opcode(wb_opcode),
        .out_mem_write(wb_mem_write),
        .out_dest(wb_dest),
        .out_imm(wb_imm),
        .out_acc_data(wb_value),
        .out_mem_data(wb_mem_data),
		  .out_reg_data(mem_wb_reg_data)
    );
    
    // ---------------------------
    // WB_stage: 최종 Write-Back 제어
    // ---------------------------
    wire wb_reg_en;
    wire [4:0] wb_reg_addr;
    wire wb_mem_en;

    WB_stage wb_stage_inst (
        .clk(clk),
        .rst(cpu_rst),
        .in_reg_write(wb_reg_write),
        .in_mem_write(wb_mem_write),
        .in_dest(wb_dest),
        .in_imm(wb_imm),
		  .in_opcode(wb_opcode),
        .in_acc_data(wb_value),
		  .in_reg_data(mem_wb_reg_data),
        .in_mem_data(wb_mem_data),
        .reg_write_enable(wb_reg_en),
        .reg_write_addr(wb_reg_addr),
        .reg_write_data(wb_reg_data),
        .mem_write_enable(wb_mem_en),
        .mem_write_addr(wb_mem_addr),
        .mem_write_data(wb_mem_wr_data),
        .accum_value(wb_accum_val)
    );
    
    // ---------------------------
    // 범용 레지스터 파일 및 누산기(accum) 갱신 (Write-Back 동작)
    // ---------------------------
reg reg_write_pulse;

always @(posedge clk or negedge cpu_rst) begin
    if (!cpu_rst) begin
        accum <= 8'd0;
        for (j = 0; j < 32; j = j + 1)
            reg_file[j] <= 8'd0;
        reg_write_pulse <= 0;
    end else begin
			accum <= wb_accum_val;
        if (mem_wb_reg_write ) begin
            reg_file[wb_reg_addr] <= wb_reg_data;
            reg_write_pulse <= 1;
        end else begin
            reg_write_pulse <= 0;
        end
    end
end


		
    // ========== FSM 상태 기반 숫자 입력 & ROM 제어 확장 ==========

    // FSM 상태 관리: 1 → 2 → 3 순환
    wire [3:0] digit;
    fsm_counter u_fsm (
        .clk(clk),
        .button(button),
        .digit(digit)
    );
	 
    // ========== 버튼 edge 감지용 동기화 레지스터 ==========
    reg key_up_sync_0, key_up_sync_1;
    reg key_down_sync_0, key_down_sync_1;

    // 버튼 동기화
    always @(posedge clk) begin
        key_up_sync_0   <= key_up;
        key_up_sync_1   <= key_up_sync_0;
        key_down_sync_0 <= key_down;
        key_down_sync_1 <= key_down_sync_0;
    end

    // falling edge (high → low) 검출: 버튼 눌림
    wire key_up_pulse   = key_up_sync_1 & ~key_up_sync_0;
    wire key_down_pulse = key_down_sync_1 & ~key_down_sync_0;

    // ========== 사용자 입력 숫자 (0~999) ==========
	 reg [9:0] user_digit = 0;
    always @(posedge clk) begin
        if (digit >= 4'd1 && digit <= 4'd3) begin  // 상태 1,2,3 모두 주소 변경 가능
            if (key_up_pulse && user_digit < 999)
                user_digit <= user_digit + 1;
            else if (key_down_pulse && user_digit > 0)
                user_digit <= user_digit - 1;
        end
    end

// ROM 주소 연결
wire [7:0] rom_data;
wire [7:0] rom_addr = user_digit[7:0];
rom rom_inst (
    .data(rom_data),
    .addr(rom_addr),
    .read(1'b1),
    .ena(1'b1)
);
//

// RAM 미러 저장소 (정상 출력용)
reg [7:0] ram_view [0:255];

always @(posedge clk) begin
    if (mem_wb_mem_write) begin
        ram_view[wb_mem_addr] <= wb_mem_wr_data;
    end else if (sw8_falling_edge) begin
        ram_view[user_digit[7:0]] <= switches[7:0];
    end
end


// LED에 표시할 값
reg [7:0] display_led;

always @(posedge clk) begin
    if (switches[8]) begin
        display_led <= switches[7:0];  // 입력 미리보기
    end else begin
        if (digit == 4'd1 && key_enter == 1'b0)
            display_led <= rom_data;
        else if (digit == 4'd2 && key_enter == 1'b0)
            display_led <= ram_view[user_digit[7:0]];
        else if (digit == 4'd3 && key_enter == 1'b0)
            display_led <= reg_file[user_digit[4:0]];
        else
            display_led <= 8'b00000000;
    end
end


assign LEDR[7:0] = display_led;
assign LEDR[8] = switches[8];

    // 7-Segment 출력 연결
    wire [6:0] seg_fsm, seg_hundreds, seg_tens, seg_ones;
    // FSM 상태 출력 → HEX5
    seg_decoder u_fsm_seg (
        .digit(digit),
        .seg(seg_fsm)
    );

    // 10진 자릿수 분리
    wire [3:0] digit_hundreds = (user_digit / 100) % 10;
    wire [3:0] digit_tens     = (user_digit / 10) % 10;
    wire [3:0] digit_ones     = user_digit % 10;
	 // 3자리 숫자 출력 → HEX2 (백), HEX1 (십), HEX0 (일)

    // 각각을 7-segment 디코더에 연결
    seg_decoder u_seg_h (
        .digit(digit_hundreds),
        .seg(seg_hundreds)
    );
    seg_decoder u_seg_t (
        .digit(digit_tens),
        .seg(seg_tens)
    );
    seg_decoder u_seg_o (
        .digit(digit_ones),
        .seg(seg_ones)
    );

    // ========== SW9 기반 pipeline_start 및 5초간 8888 표시 제어 ==========

    reg [27:0] count = 0;
    reg started = 0;
    reg prev_sw9 = 0;

always @(posedge clk or negedge cpu_rst) begin
    if (!cpu_rst) begin
        count <= 0;
        started <= 0;
        prev_sw9 <= 0;
        pipeline_start <= 0;
    end else begin
        prev_sw9 <= switches[9];

        if (switches[9] && !prev_sw9) begin
            started <= 1;
            count <= 28'd100_000_000;
            pipeline_start <= 1;
        end else begin
            pipeline_start <= 0;
        end

        if (started) begin
            if (count > 0)
                count <= count - 1;
            else
                started <= 0;  // count가 0까지 줄었으면 꺼줌
        end
    end
end


    // HEX 출력: 실행 중에는 8888, 아니면 정상 출력
    always @(*) begin
        if (started) begin
            hex0 = 7'b0000000;
            hex1 = 7'b0000000;
            hex2 = 7'b0000000;
            hex5 = 7'b0000000;
        end else begin
            hex0 = seg_ones;
            hex1 = seg_tens;
            hex2 = seg_hundreds;
            hex5 = seg_fsm;
        end
    end
	 
	 
endmodule
