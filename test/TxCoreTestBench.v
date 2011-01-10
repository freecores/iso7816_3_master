`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sebastien Riou
//
// Create Date:   22:53:00 08/29/2010
// Design Name:   TxCore
// Module Name:   tb_TxCore.v
// Project Name:  Uart
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: TxCore
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_TxCore;
parameter PARITY	= 1;
parameter CLK_PERIOD = 10;//should be %2
	// Inputs
	reg [7:0] dataIn;
	reg loadDataIn;
	reg [12:0] clocksPerBit;
	reg stopBit2;
	wire oddParity=0; //if 1, parity bit is such that data+parity have an odd number of 1
   wire msbFirst=0;  //if 1, bits will be send in the order startBit, b7, b6, b5...b0, parity
	reg clk;
	reg nReset;

	// Outputs
	wire serialOut;
	wire run;
	wire full;
   wire stopBits;

	// Instantiate the Unit Under Test (UUT)
	TxCore #(.PARITY_POLARITY(PARITY)) uut (
		.serialOut(serialOut), 
		.run(run), 
		.full(full), 
      .stopBits(stopBits),
		.dataIn(dataIn), 
		.clocksPerBit(clocksPerBit),
		.stopBit2(stopBit2),
		.oddParity(oddParity),
      .msbFirst(msbFirst),
	   .loadDataIn(loadDataIn), 
		.clk(clk), 
		.nReset(nReset)
	);
	
	//test bench signals
	reg tbClock;
	reg tbBitCounter;

	initial begin
		tbClock=0;
		tbBitCounter=0;
		// Initialize Inputs
		dataIn = 0;
		loadDataIn = 0;
		clocksPerBit = 8;
		stopBit2=0;
		clk = 0;
		nReset = 0;
		#(CLK_PERIOD*10);     
		nReset = 1;
		#(CLK_PERIOD*10);
		// Add stimulus here
		dataIn = 8'b1000_0000;
		loadDataIn = 1;
		wait(full==1);
		wait(full==0);
		//loadDataIn=0;
		dataIn = 8'b0111_1111;
		//loadDataIn = 1;
		wait(full==1);
		wait(full==0);
		loadDataIn=0;
	end
	
	initial begin
		// timeout
		#10000;        
		$finish;
	end
	
	always 
		#1	tbClock =  ! tbClock;
	always
		#(CLK_PERIOD/2) clk =  ! clk;
      
endmodule

