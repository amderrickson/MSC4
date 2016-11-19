/*
The Intel-4001 functions as a 256x8 word ROM and an I/O device. 

A single MSC-4 Computer can consist of up to 16 Intel-4001 chips, without having to add any exterior logic.

For executing a single 8 bit instruction, the MSC4 has 8 clock cycles known as: A1, A2, A3, M1, M2, X1, X2, X3.
Typically the Intel-4001 is only active for the A1, A2, A3, M1 and M2 cycles, if no I/O is being used. 

*/

module I4001(D0,D1,D2,D3,CLK0,CLK1,VSS,SYNC,O0,O1,O2,O3,VDD,CM,P0,RESET);
	inout reg D0;
	inout reg D1;
	inout reg D2;
	inout reg D3;
	
	inout reg O0;
	inout reg O1;
	inout reg O2;
	inout reg O3;
	
	input CLK0;
	input CLK1;
	input VSS;
	input SYNC;
	input VDD;
	input CM;
	input P0;
	input RESET;
	
	reg [4:0] ROM_ADDRESS;
	reg [7:0] ROM_STORAGE[7:0];
	
	reg [7:0] DATA_ADDRESS;
	reg [3:0] ACTIVE_CHIP;
	reg [3:0] ACTIVE_ADDRESS;
	
	reg [0:2] CURRENT_STATE;
	
	reg TRANSFER;
	reg WRR;
	reg RDR;
	
	reg [3:0] IO;
	reg [3:0] IO_OUTS;

	parameter A1 = 4'b000;
	parameter A2 = 4'b001;
	parameter A3 = 4'b010;
	parameter M1 = 4'b011;
	parameter M2 = 4'b100;
	parameter X1 = 4'b101;
	parameter X2 = 4'b110;
	parameter X3 = 4'b111;
	
	initial begin
		$readmemb("ROM.txt",ROM_STORAGE);
		$readmemb("IO.txt",IO);
		$readmemb("OUTPUTS.txt",IO_OUTS);
		CURRENT_STATE<=A1;
		TRANSFER<=1'b0;
		WRR<=1'b0;
		RDR<=1'b0;
	end
	
	always @(posedge CLK0) begin
		if(SYNC==0) begin
			CURRENT_STATE=A1;
		end
		case(CURRENT_STATE)
			A1: begin
				DATA_ADDRESS[0]<=D0;
				DATA_ADDRESS[1]<=D1;
				DATA_ADDRESS[2]<=D2;
				DATA_ADDRESS[3]<=D3;
				CURRENT_STATE<=A2;
				end
			
			A2: begin
				DATA_ADDRESS[4]<=D0;
				DATA_ADDRESS[5]<=D1;
				DATA_ADDRESS[6]<=D2;
				DATA_ADDRESS[7]<=D3;
				CURRENT_STATE<=A3;
				end
			
			A3: begin
				if(CM==0) begin
					TRANSFER=1'b1;
				end
				ACTIVE_CHIP<=D3+D2+D1+D0;
				CURRENT_STATE<=M1;
				end
			
			M1: begin
				if(TRANSFER) begin
					D0<=ROM_STORAGE[DATA_ADDRESS][0];
					D1<=ROM_STORAGE[DATA_ADDRESS][1];
					D2<=ROM_STORAGE[DATA_ADDRESS][2];
					D3<=ROM_STORAGE[DATA_ADDRESS][3];
					if((D3+D2+D1+D0)==4'b0010) begin
						WRR<=1'b1;
					end
					if((D3+D2+D1+D0)==4'b1010) begin
						RDR<=1'b1;
					end
				end
				CURRENT_STATE<=M2;
				end
			
			M2: begin
					if(CM==1) begin
						WRR<=1'b0;
						RDR<=1'b0;
					end
					if(TRANSFER) begin
						D0<=ROM_STORAGE[DATA_ADDRESS][4];
						D1<=ROM_STORAGE[DATA_ADDRESS][5];
						D2<=ROM_STORAGE[DATA_ADDRESS][6];
						D3<=ROM_STORAGE[DATA_ADDRESS][7];
					end
					CURRENT_STATE<=X1;
				end
			
			X1: begin
				CURRENT_STATE<=X2;
				end
				
			X2: begin
				if(CM==0) begin
					ACTIVE_ADDRESS<=D3+D2+D1+D0;
				end
				if(WRR) begin
					if(IO[0]==0) begin
						O0=D0;
					end
					if(IO[1]==0) begin
						O1=D1;
					end
					if(IO[2]==0) begin
						O2=D2;
					end
					if(IO[3]==0) begin
						O3=D3;
					end
				end
				if(RDR) begin
					if(IO[0]==1) begin
						D0=O0;
					end
					else begin
						D0=IO_OUTS[0];
					end
					if(IO[1]==1) begin
						D1=O1;
					end
					else begin
						D1=IO_OUTS[1];
					end
					if(IO[2]==1) begin
						D2=O2;
					end
					else begin
						D2=IO_OUTS[2];
					end
					if(IO[3]==1) begin
						D3=O3;
					end
					else begin
						D3=IO_OUTS[3];
					end
				end
				CURRENT_STATE<=X3;
				end
			
			X3: begin			
				CURRENT_STATE<=A1;
				end
		endcase
	end
endmodule
