`timescale 1ns / 1ps
`default_nettype none

module Iso7816_3_t0_analyzer(
	input wire nReset,
	input wire clk,
	input wire isoReset,
	input wire isoClk,
	input wire isoVdd,
	input wire isoSio,
	output reg [3:0] fiCode,
	output reg [3:0] diCode,
	output reg [3:0] fi,
	output reg [3:0] di,
	output reg [12:0] cyclesPerEtu,
	output reg [7:0] fMax,
	output wire isActivated,
	output wire tsReceived,
	output wire tsError,
	output wire useIndirectConvention,
	output wire atrIsEarly,//high if TS received before 400 cycles after reset release
	output wire atrIsLate,//high if TS is still not received after 40000 cycles after reset release
	output wire atrCompleted,
	output reg useT0,
	output reg useT1,
	output reg useT15,
	output reg waitCardTx,
	output reg waitTermTx,
	output wire cardTx,
	output wire termTx,
	output wire guardTime,
	output wire overrunError,
	output wire frameError,
	output reg [7:0] lastByte
	);

	
reg [8:0] tsCnt;//counter to start ATR 400 cycles after reset release

reg [7:0] buffer[256+5:0];
localparam CLA_I= 8*4;
localparam INS_I= 8*3;
localparam P1_I = 8*2;
localparam P2_I = 8*1;
localparam P3_I = 0;
reg [CLA_I+7:0] tpduHeader;

wire COM_statusOut=statusOut;
wire COM_clk=isoClk;
integer COM_errorCnt;

wire rxRun, rxStartBit, overrunErrorFlag, frameErrorFlag, bufferFull;
assign overrunErrorFlag = overrunError;
assign frameErrorFlag = frameError;	 

wire [7:0] rxData;
wire nCsDataOut;

`include "ComRxDriverTasks.v"

wire endOfRx;

wire msbFirst = useIndirectConvention;
wire sioHighValue = ~useIndirectConvention;
wire oddParity = 1'b0;

wire plainRxData = sioHighValue ? rxData : ~rxData;

RxCoreSelfContained #(
		.DIVIDER_WIDTH(4'd13))
	rxCore (
    .dataOut(rxData), 
    .overrunErrorFlag(overrunError), 
    .dataOutReadyFlag(bufferFull), 
    .frameErrorFlag(frameError), 
    .endOfRx(endOfRx),
    .run(rxRun), 
    .startBit(rxStartBit), 
	 .stopBit(guardTime),
    .clkPerCycle(clkPerCycle),
    .clocksPerBit(cyclesPerEtu), 
    .stopBit2(stopBit2), 
    .oddParity(oddParity),
    .msbFirst(msbFirst),
	 .ackFlags(nCsDataOut), 
    .serialIn(isoSio), 
    .comClk(comClk), 
    .clk(clk), 
    .nReset(nReset)
    );

TsAnalyzer tsAnalyzer(
	.nReset(nReset),
	.clk(clk),
	.isoReset(isoReset),
	.isoClk(isoClk),
	.isoVdd(isoVdd),
	.isoSio(isoSio),
	.endOfRx(endOfRx),
	.rxData(rxData),
	.isActivated(isActivated),
	.tsReceived(tsReceived),
	.tsError(tsError),
	.atrIsEarly(atrIsEarly),
	.atrIsLate(atrIsLate),
	.useIndirectConvention(useIndirectConvention)
	);

FiDiAnalyzer fiDiAnalyzer(
	.fiCode(fiCode),
	.diCode(diCode),
	.fi(fi),
	.di(di),
	.cyclesPerEtu(cyclesPerEtu),
	.fMax(fMax)
	);
	
wire run = rxStartBit | rxRun;
localparam WAIT_CLA = 0;
integer t0State;
always @(posedge comClk, negedge nReset) begin
	if(~nReset) begin
		fiCode<=4'b0001;
		diCode<=4'b0001;
		useT0<=1'b0;
		useT1<=1'b0;
		useT15<=1'b0;
		waitCardTx<=1'b0;
		waitTermTx<=1'b0;
		lastByte<=8'b0;
		t0State<=WAIT_CLA;
	end else if(isActivated) begin
		if(~tsReceived) begin
			waitCardTx<=1'b1;
		end else if(~t0Received) begin
		end else if(~atrCompleted) begin
		end else if(useT0) begin
			//T=0 cmd/response monitoring state machine
		
		
		end
	end
end

reg [1:0] txDir;
always @(*) begin: errorSigDirectionBlock
	if(stopBit & ~isoSio)
		{cardTx, termTx}=txDir[0:1];
	else
		{cardTx, termTx}=txDir[1:0];
end
always @(posedge comClk, negedge nReset) begin: comDirectionBlock
	if(~nReset | ~run) begin
		txDir<=2'b00;
	end else begin
		if(~stopBit) begin //{waitCardTx, waitTermTx} is updated during stop bits so we hold current value here
			case({waitCardTx, waitTermTx})
				2'b00: txDir<=2'b00;
				2'b01: txDir<=2'b01;
				2'b10: txDir<=2'b10;
				2'b11: txDir<=2'b00;
			endcase
		end
	end
end		
		
endmodule

