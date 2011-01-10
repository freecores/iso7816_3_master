`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:16:42 01/10/2011
// Design Name:   Iso7816_3_Master
// Module Name:   tbIso7816_3_Master.v
// Project Name:  Uart
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: Iso7816_3_Master
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tbIso7816_3_Master;
parameter CLK_PERIOD = 10;//should be %2
	// Inputs
	reg nReset;
	reg clk;
	reg [15:0] clkPerCycle;
	reg startActivation;
	reg startDeactivation;
	reg [7:0] dataIn;
	reg nWeDataIn;
	reg [12:0] cyclePerEtu;
	reg nCsDataOut;
	reg nCsStatusOut;

	// Outputs
	wire [7:0] dataOut;
	wire [7:0] statusOut;
	wire isActivated;
	wire useIndirectConvention;
	wire tsError;
	wire tsReceived;
	wire atrIsEarly;
	wire atrIsLate;
	wire isoClk;
	wire isoReset;
	wire isoVdd;

	// Bidirs
	wire isoSio;

	// Instantiate the Unit Under Test (UUT)
	Iso7816_3_Master uut (
		.nReset(nReset), 
		.clk(clk), 
		.clkPerCycle(clkPerCycle), 
		.startActivation(startActivation), 
		.startDeactivation(startDeactivation), 
		.dataIn(dataIn), 
		.nWeDataIn(nWeDataIn), 
		.cyclePerEtu(cyclePerEtu), 
		.dataOut(dataOut), 
		.nCsDataOut(nCsDataOut), 
		.statusOut(statusOut), 
		.nCsStatusOut(nCsStatusOut), 
		.isActivated(isActivated), 
		.useIndirectConvention(useIndirectConvention), 
		.tsError(tsError),
		.tsReceived(tsReceived),
		.atrIsEarly(atrIsEarly), 
		.atrIsLate(atrIsLate), 
		.isoSio(isoSio), 
		.isoClk(isoClk), 
		.isoReset(isoReset), 
		.isoVdd(isoVdd)
	);
	
	DummyCard card(
		.isoReset(isoReset),
		.isoClk(isoClk),
		.isoVdd(isoVdd),
		.isoSio(isoSio)
	);
	integer tbErrorCnt;
	initial begin
		// Initialize Inputs
		nReset = 0;
		clk = 0;
		clkPerCycle = 0;
		startActivation = 0;
		startDeactivation = 0;
		dataIn = 0;
		nWeDataIn = 0;
		cyclePerEtu = 0;
		nCsDataOut = 0;
		nCsStatusOut = 0;

		// Wait 100 ns for global reset to finish
		#100;
      nReset = 1;  
		// Add stimulus here
		#100
		startActivation = 1'b1;
		wait(isActivated);
		wait(atrIsEarly|atrIsLate);
		#200
		$finish;
	end
	initial begin
		// timeout
		#10000;  
      tbErrorCnt=tbErrorCnt+1;
      $display("ERROR: timeout expired");
      #10;
		$finish;
	end
	always
		#(CLK_PERIOD/2) clk =  ! clk;       
endmodule

