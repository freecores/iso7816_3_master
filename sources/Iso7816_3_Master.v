`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Sebastien Riou
// Creation date: 17:16:40 01/09/2011 
//
// Last change date:	$LastChangedDate$
// Last changed by:	$LastChangedBy$
// Last revision:		$LastChangedRevision$
// Head URL:			$HeadURL$				 
//
//////////////////////////////////////////////////////////////////////////////////
module Iso7816_3_Master(
    input wire nReset,
    input wire clk,
	 input wire [15:0] clkPerCycle,//not supported yet
	 input wire startActivation,//Starts activation sequence
	 input wire startDeactivation,//Starts deactivation sequence
    input wire [7:0] dataIn,
    input wire nWeDataIn,
	 input wire [12:0] cyclesPerEtu,
    output wire [7:0] dataOut,
    input wire nCsDataOut,
    output wire [7:0] statusOut,
    input wire nCsStatusOut,
	 output reg isActivated,//set to high by activation sequence, set to low by deactivation sequence
	 output wire useIndirectConvention,
	 output wire tsError,//high if TS character is wrong
	 output wire tsReceived,
	 output wire atrIsEarly,//high if TS received before 400 cycles after reset release
	 output wire atrIsLate,//high if TS is still not received after 40000 cycles after reset release
	 //ISO7816 signals
    inout wire isoSio,
	 output wire isoClk,
	 output reg isoReset,
	 output reg isoVdd
    );

wire txRun,txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull;
assign {txRun, txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull} = statusOut;

wire serialOut;
assign isoSio = isTx ? serialOut : 1'bz;
pullup(isoSio);
wire comClk;

	HalfDuplexUartIf #(
		.DIVIDER_WIDTH(1'b1),
		.CLOCK_PER_BIT_WIDTH(4'd13)
		)
	uart (
		.nReset(nReset), 
		.clk(clk),
		.clkPerCycle(1'b0),
		.dataIn(dataIn), 
		.nWeDataIn(nWeDataIn), 
		.clocksPerBit(cyclesPerEtu), 
		.dataOut(dataOut), 
		.nCsDataOut(nCsDataOut), 
		.statusOut(statusOut), 
		.nCsStatusOut(nCsStatusOut), 
		.serialIn(isoSio),
		.serialOut(serialOut),
		.comClk(comClk)
	);
	
	reg isoClkEn;
	assign isoClk = isoClkEn ? comClk : 1'b0;
	
reg [16:0] resetCnt;
reg waitTs;
assign tsReceived = ~waitTs;
reg [7:0] ts;
assign atrIsEarly = ~waitTs & (resetCnt<(16'h100+16'd400));
assign atrIsLate = resetCnt>(16'h100+16'd40000);
assign useIndirectConvention = ~waitTs & (ts==8'h3F);
assign tsError = ~waitTs & (ts!=8'h3B) & ~useIndirectConvention;
always @(posedge comClk, negedge nReset) begin
	if(~nReset) begin
		isoClkEn <= 1'b0;
		resetCnt<=16'b0;
		waitTs<=1'b1;
		isoReset <= 1'b0;
		isoVdd <= 1'b0;
		isActivated <= 1'b0;
	end else if(isActivated) begin
		if(waitTs) begin
			if(statusOut[0]) begin
				waitTs<=1'b0;
				ts<=dataOut;
			end
			resetCnt<=resetCnt+1;
		end
		if(startDeactivation) begin
			isoVdd <= 1'b0;
			isoClkEn <= 1'b0;
			isoReset <= 1'b0;
			resetCnt<=16'b0;
			isActivated <= 1'b0;
		end
	end else begin
		if(startActivation) begin
			waitTs <= 1'b1;
			isoVdd <= 1'b1;
			isoClkEn <= 1'b1;
			if(16'h100 == resetCnt) begin
				isActivated <=1'b1;
				isoReset <=1'b1;
			end else
				resetCnt<=resetCnt + 1;
		end else begin
			resetCnt<=16'b0;
		end
	end
end
endmodule
