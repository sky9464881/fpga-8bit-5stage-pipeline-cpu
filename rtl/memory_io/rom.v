`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module rom(data, addr, read, ena);
input read, ena;
input [7:0] addr;
output [7:0] data;
 
reg [7:0] memory[255:0];

initial begin
	memory[0] = 8'b000_00000;	//NOP
	
	memory[1] = 8'b010_00001;	//LDA s1
	memory[2] = 8'b000_00011;	//ram 3
	
	memory[3] = 8'b010_00010;	//LDA s2
	memory[4] = 8'b000_00100;	//ram 4
	
	memory[5] = 8'b010_00011;	//LDA s3
	memory[6] = 8'b000_00101;	//ram 5

	memory[7] = 8'b100_00001;	//PRE s1
	memory[8] = 8'b101_00010;	//ADD s2
	memory[9] = 8'b110_00001;	//LDM s1
	
	memory[10] = 8'b011_00001;	//STO s1
	memory[11] = 8'b000_00001;	//ram(1)

	memory[12] = 8'b010_00010;	//LDA s2
	memory[13] = 8'b000_00001;	//ram(1)
	
	memory[14] = 8'b100_00011;	//PRE s3
	memory[15] = 8'b101_00010;	//ADD s2
	memory[16] = 8'b110_00011;	//LDM s3
	
	memory[17] = 8'b011_00011;	//STO s3
	memory[18] = 8'b000_00010;	//ram(2)
	memory[19] = 8'b000_00000;	//NOP//8'b111_00000;	//HLT

	memory[65] = 8'b001_00101;	//37
	memory[66] = 8'b010_11001;	//89
	memory[67] = 8'b001_10101;	//53
	
end


assign data = (read&&ena)? memory[addr]:8'hzz;	

endmodule
