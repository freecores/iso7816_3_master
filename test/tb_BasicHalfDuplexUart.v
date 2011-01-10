`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:45:19 10/31/2010
// Design Name:   BasicHalfDuplexUart
// Module Name:   /home/seb/dev/hardware/Uart/tb_BasicHalfDuplexUart.v
// Project Name:  Uart
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: BasicHalfDuplexUart
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_BasicHalfDuplexUart;

	// Inputs
	reg [7:0] txData;
	reg [12:0] clocksPerBit;
	reg stopBit2;
	reg startTx;
	reg ackFlags;
	reg clk;
	reg nReset;

	// Outputs
	wire [7:0] rxData;
	wire overrunErrorFlag;
	wire dataOutReadyFlag;
	wire frameErrorFlag;
	wire run;
	wire rxStartBit;
	wire txFull;
	wire isTx;

	// Bidirs
	wire serialLine;

	// Instantiate the Unit Under Test (UUT)
	BasicHalfDuplexUart uut (
		.rxData(rxData), 
		.overrunErrorFlag(overrunErrorFlag), 
		.dataOutReadyFlag(dataOutReadyFlag), 
		.frameErrorFlag(frameErrorFlag), 
		.run(run), 
		.rxStartBit(rxStartBit), 
		.txFull(txFull), 
		.isTx(isTx), 
		.serialLine(serialLine), 
		.txData(txData), 
		.clocksPerBit(clocksPerBit), 
		.stopBit2(stopBit2), 
		.startTx(startTx), 
		.ackFlags(ackFlags), 
		.clk(clk), 
		.nReset(nReset)
	);

	initial begin
		// Initialize Inputs
		txData = 0;
		clocksPerBit = 0;
		stopBit2 = 0;
		startTx = 0;
		ackFlags = 0;
		clk = 0;
		reset = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

