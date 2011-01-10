`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:22:43 01/10/2011
// Design Name:   HalfDuplexUartIf
// Module Name:   dummyCard.v
// Project Name:  Uart
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: HalfDuplexUartIf
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module DummyCard(
	input isoReset,
	input isoClk,
	input isoVdd,
	inout isoSio
	);

	// Inputs
	wire [0:0] clkPerCycle=0;
	reg [7:0] dataIn;
	reg nWeDataIn;
	reg nCsDataOut;
	reg nCsStatusOut;

	// Outputs
	wire [7:0] dataOut;
	wire [7:0] statusOut;
	wire serialOut;
	


	// Instantiate the Unit Under Test (UUT)
	HalfDuplexUartIf uut (
		.nReset(isoReset), 
		.clk(isoClk), 
		.clkPerCycle(clkPerCycle), 
		.dataIn(dataIn), 
		.nWeDataIn(nWeDataIn), 
		.dataOut(dataOut), 
		.nCsDataOut(nCsDataOut), 
		.statusOut(statusOut), 
		.nCsStatusOut(nCsStatusOut), 
		.serialIn(isoSio), 
		.serialOut(serialOut),  
		.comClk(comClk)
	);

wire txRun,txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull;
assign {txRun, txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull} = statusOut;

assign isoSio = isTx ? serialOut : 1'bz;

reg sendAtr;
reg [8:0] tsCnt;//counter to start ATR 400 cycles after reset release
always @(posedge isoClk, negedge isoReset) begin
	if(~isoReset) begin
		nWeDataIn<=1'b1;
		nCsDataOut<=1'b1;
		nCsStatusOut<=1'b1;
		
		tsCnt<=9'b0;
		sendAtr<=1'b1;
	end else if(tsCnt!=9'd400) begin
		tsCnt <= tsCnt + 1'b1;
	end else if(sendAtr) begin
		sendAtr<=1'b0;
		dataIn<=8'h3B;
		nWeDataIn<=1'b0;
		@(posedge isoClk)
		nWeDataIn<=1'b1;
		@(posedge isoClk)//should not be needed
		wait(txPending==0);
		dataIn<=8'h00;
		nWeDataIn<=1'b0;
		@(posedge isoClk)
		nWeDataIn<=1'b1;
	end else begin
	end
end
      
endmodule

