`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:16:40 01/09/2011 
// Design Name: 
// Module Name:    Iso7816_3_Master 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Iso7816_3_Master(
    input nReset,
    input clk,
	 //input [15:0] clkPerCycle,//not supported yet
	 input startActivation,//Starts activation sequence
	 input startDeactivation,//Starts deactivation sequence
    input [7:0] dataIn,
    input nWeDataIn,
	 input [12:0] cyclePerEtu,
    output [7:0] dataOut,
    input nCsDataOut,
    output [7:0] statusOut,
    input nCsStatusOut,
	 output reg isActivated,//set to high by activation sequence, set to low by deactivation sequence
	 output useIndirectConvention,
	 output tsError,//high if TS character is wrong
	 output atrIsEarly,//high if TS received before 400 cycles after reset release
	 output atrIsLate,//high if TS is still not received after 40000 cycles after reset release
	 //ISO7816 signals
    inout isoSio,
	 output isoClk,
	 output isoReset,
	 output isoVdd
    );

	assign isoSio = isTx ? serialOut : 1'bz;

	HalfDuplexUartIf uart (
		.nReset(nReset), 
		.clk(clk),
		.clkPerCycle(1'b0),
		.dataIn(dataIn), 
		.nWeDataIn(nWeDataIn), 
		.dataOut(dataOut), 
		.nCsDataOut(nCsDataOut), 
		.statusOut(statusOut), 
		.nCsStatusOut(nCsStatusOut), 
		.serialIn(isoSio),
		.serialOut(serialOut),
		.isTx(isTx),
		.comClk(comClk)
	);
	
	reg isoClkEn;
	assign isoClk = isoClkEn ? comClk : 1'b0;
	
	reg [16:0] resetCnt;
	assign atrIsEarly = ~waitTs & (resetCnt<(16'h100+16'd400));
	assign atrIsLate = resetCnt>(16'h100+16'd40000);
	assign useIndirectConvention = ~waitTs & (ts==8'h3F);
	assign tsError = ~waitTs & (ts!=8'h3B) & ~useIndirectConvention;
	reg waitTs;
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
