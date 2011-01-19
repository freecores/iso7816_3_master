`timescale 1ns / 1ps
`default_nettype none
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

wire COM_statusOut=statusOut;
wire COM_clk=isoClk;
integer COM_errorCnt;

wire txRun,txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull;
assign {txRun, txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull} = statusOut;

`include "ComDriverTasks.v"


wire [3:0] spy_fiCode;
wire [3:0] spy_diCode;
wire [12:0] spy_fi;
wire [7:0] spy_di;
wire [12:0] spy_cyclesPerEtu;
wire [7:0] spy_fMax;
wire spy_isActivated,spy_tsReceived,spy_tsError;
wire spy_useIndirectConvention,spy_atrIsEarly,spy_atrIsLate;
wire [3:0] spy_atrK;
wire spy_atrHasTck,spy_atrCompleted; 
wire spy_useT0,spy_useT1,spy_useT15,spy_waitCardTx,spy_waitTermTx,spy_cardTx,spy_termTx,spy_guardTime; 
wire spy_overrunError,spy_frameError;
wire [7:0] spy_lastByte;

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

	Iso7816_3_t0_analyzer spy (
    .nReset(nReset), 
    .clk(clk), 
    .clkPerCycle(clkPerCycle[0]), 
    .isoReset(isoReset), 
    .isoClk(isoClk), 
    .isoVdd(isoVdd), 
    .isoSio(isoSio), 
    .fiCode(spy_fiCode), 
    .diCode(spy_diCode), 
    .fi(spy_fi), 
    .di(spy_di), 
    .cyclesPerEtu(spy_cyclesPerEtu), 
    .fMax(spy_fMax), 
    .isActivated(spy_isActivated), 
    .tsReceived(spy_tsReceived), 
    .tsError(spy_tsError), 
    .useIndirectConvention(spy_useIndirectConvention), 
    .atrIsEarly(spy_atrIsEarly), 
    .atrIsLate(spy_atrIsLate), 
    .atrK(spy_atrK), 
    .atrHasTck(spy_atrHasTck), 
    .atrCompleted(spy_atrCompleted), 
    .useT0(spy_useT0), 
    .useT1(spy_useT1), 
    .useT15(spy_useT15), 
    .waitCardTx(spy_waitCardTx), 
    .waitTermTx(spy_waitTermTx), 
    .cardTx(spy_cardTx), 
    .termTx(spy_termTx), 
    .guardTime(spy_guardTime), 
    .overrunError(spy_overrunError), 
    .frameError(spy_frameError), 
    .lastByte(spy_lastByte)
    );

	
	integer tbErrorCnt;
	initial begin
		// Initialize Inputs
		COM_errorCnt=0;
		nReset = 0;
		clk = 0;
		clkPerCycle = 0;
		startActivation = 0;
		startDeactivation = 0;
		dataIn = 0;
		nWeDataIn = 1'b1;
		cyclePerEtu = 0;
		nCsDataOut = 1'b1;
		nCsStatusOut = 1'b1;

		// Wait 100 ns for global reset to finish
		#100;
      nReset = 1;  
		// Add stimulus here
		#100
		startActivation = 1'b1;
		wait(isActivated);
		wait(tsReceived);
		if(atrIsEarly) begin
			$display("ERROR: ATR is early");
			tbErrorCnt=tbErrorCnt+1;
		end
		if(atrIsLate) begin
			$display("ERROR: ATR is late");
			tbErrorCnt=tbErrorCnt+1;
		end
		@(posedge clk);
		while((txRun===1'b1)||(rxRun===1'b1)||(rxStartBit===1'b1)) begin
			while((txRun===1'b1)||(rxRun===1'b1)||(rxStartBit===1'b1)) begin
				@(posedge clk);
			end
			@(posedge clk);
		end
		$display("Two cycle pause in communication detected, stop simulation");
		#200
		$finish;
	end
	//T=0 tpdu stimuli
	initial begin
		receiveAndCheckByte(8'h3B);
		receiveAndCheckByte(8'h00);
		//sendBytes("000C000001");//would be handy, TODO
		sendByte(8'h00);
		sendByte(8'h0C);
		sendByte(8'h00);
		sendByte(8'h00);
		sendByte(8'h01);
		receiveAndCheckByte(8'h0C);
		//sendBytes("55");
		sendByte(8'h55);
		receiveAndCheckByte(8'h90);
		receiveAndCheckByte(8'h00);
	end
	initial begin
		// timeout
		#100000;  
      tbErrorCnt=tbErrorCnt+1;
      $display("ERROR: timeout expired");
      #10;
		$finish;
	end
	always
		#(CLK_PERIOD/2) clk =  ! clk;       
endmodule

