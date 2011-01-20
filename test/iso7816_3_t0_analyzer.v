`timescale 1ns / 1ps
`default_nettype none

module Iso7816_3_t0_analyzer(
	input wire nReset,
	input wire clk,
	input wire [DIVIDER_WIDTH-1:0] clkPerCycle,
	input wire isoReset,
	input wire isoClk,
	input wire isoVdd,
	input wire isoSio,
	output reg [3:0] fiCode,
	output reg [3:0] diCode,
	output wire [12:0] fi,
	output wire [7:0] di,
	output wire [12:0] cyclesPerEtu,
	output wire [7:0] fMax,
	output wire isActivated,
	output wire tsReceived,
	output wire tsError,
	output wire useIndirectConvention,
	output wire atrIsEarly,//high if TS received before 400 cycles after reset release
	output wire atrIsLate,//high if TS is still not received after 40000 cycles after reset release
	output reg [3:0] atrK,//number of historical bytes
	output reg atrHasTck,
	output reg atrCompleted,
	output reg useT0,
	output reg useT1,
	output reg useT15,
	output reg waitCardTx,
	output reg waitTermTx,
	output reg cardTx,
	output reg termTx,
	output wire guardTime,
	output wire overrunError,
	output wire frameError,
	output reg [7:0] lastByte,
	output reg [31:0] bytesCnt
	);
parameter DIVIDER_WIDTH = 1;
	
reg [8:0] tsCnt;//counter to start ATR 400 cycles after reset release

reg [7:0] buffer[256+5:0];
localparam CLA_I= 8*4;
localparam INS_I= 8*3;
localparam P1_I = 8*2;
localparam P2_I = 8*1;
localparam P3_I = 0;
reg [CLA_I+7:0] tpduHeader;

//wire COM_clk=isoClk;
//integer COM_errorCnt;
//wire txPending=1'b0;
//wire txRun=1'b0;

wire rxRun, rxStartBit, overrunErrorFlag, frameErrorFlag, bufferFull;
assign overrunErrorFlag = overrunError;
assign frameErrorFlag = frameError;	 

wire [7:0] rxData;
reg ackFlags;

wire msbFirst = useIndirectConvention;
wire sioHighValue = ~useIndirectConvention;
wire oddParity = 1'b0;

wire [7:0] dataOut = sioHighValue ? rxData : ~rxData;


//`include "ComRxDriverTasks.v"

wire endOfRx;

wire stopBit2 = useT0;//1 if com use 2 stop bits --> 12 ETU / byte

RxCoreSelfContained #(
		.DIVIDER_WIDTH(DIVIDER_WIDTH),
		.CLOCK_PER_BIT_WIDTH(4'd13),
		.PRECISE_STOP_BIT(1'b1))
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
    .clocksPerBit(cyclesPerEtu-1), 
    .stopBit2(stopBit2), 
    .oddParity(oddParity),
    .msbFirst(msbFirst),
	 .ackFlags(ackFlags), 
    .serialIn(isoSio), 
    .comClk(isoClk), 
    .clk(clk), 
    .nReset(nReset)
    );

TsAnalyzer tsAnalyzer(
	.nReset(nReset),
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
localparam ATR_T0 = 0;
localparam ATR_TDI = 1;
localparam ATR_HISTORICAL = 2;
localparam ATR_TCK = 3;
localparam T0_HEADER = 0;
localparam T0_PB = 0;
localparam T0_DATA = 0;
integer fsmState;

reg [11:0] tdiStruct;
wire [3:0] tdiCnt;//i+1
wire [7:0] tdiData;//value of TDi
assign {tdiCnt,tdiData}=tdiStruct;

wire [1:0] nIfBytes;
HammingWeight hammingWeight(.dataIn(tdiData[7:4]), .hammingWeight(nIfBytes));
reg [7:0] tempBytesCnt;
always @(posedge isoClk, negedge nReset) begin
	if(~nReset) begin
		lastByte<=8'b0;
		ackFlags<=1'b0;	
		bytesCnt<=32'b0;		
	end else if(ackFlags) begin
		ackFlags<=1'b0;
	end else if(frameErrorFlag|bufferFull) begin
		lastByte<=dataOut;
		ackFlags<=1'b1;
		bytesCnt<=bytesCnt+1'b1;
	end
end
always @(posedge isoClk, negedge nReset) begin
	if(~nReset) begin
		fiCode<=4'b0001;
		diCode<=4'b0001;
		useT0<=1'b1;
		useT1<=1'b0;
		useT15<=1'b0;
		waitCardTx<=1'b0;
		waitTermTx<=1'b0;
		fsmState<=ATR_TDI;
		atrHasTck<=1'b0;
		tempBytesCnt<=8'h0;
		tdiStruct<=12'h0;
		atrCompleted<=1'b0;
	end else if(isActivated) begin
		if(~tsReceived) begin
			waitCardTx<=1'b1;
		end else if(~atrCompleted) begin
			//ATR analysis
			case(fsmState)
				ATR_TDI: begin
					if(endOfRx) begin
						if(tempBytesCnt==nIfBytes) begin //TDi bytes
							tempBytesCnt <= 2'h0;
							tdiStruct <= {tdiCnt+1,dataOut};
							if(4'h0==tdiCnt) begin//this is T0
								atrK <= dataOut[3:0];
								fsmState <= (4'b0!=dataOut[7:4]) ? ATR_TDI : 
												(4'b0!=dataOut[3:0]) ? ATR_HISTORICAL : T0_HEADER;
							end else begin//TDi, i from 1 to 15
								fsmState <= (4'b0!=dataOut[7:4]) ? ATR_TDI : 
												(4'b0!=atrK) ? ATR_HISTORICAL : T0_HEADER;
							end
						end else begin //TA, TB or TC bytes
							//TODO: get relevant info
							tempBytesCnt <= tempBytesCnt+1;
						end
					end
				end
				ATR_HISTORICAL: begin
					if(endOfRx) begin
						if(tempBytesCnt==atrK) begin
							atrCompleted <= ~atrHasTck;
							fsmState <= atrHasTck ? ATR_TCK : T0_HEADER;
						end else begin
							tempBytesCnt <= tempBytesCnt+1;
						end
					end
				end
				ATR_TCK: begin
					if(endOfRx) begin
					//TODO:check
						atrCompleted <= 1'b1;
						fsmState <= T0_HEADER;
					end
				end
			endcase
		end else if(useT0) begin
			//T=0 cmd/response monitoring state machine
		
		
		end
	end
end

reg [1:0] txDir;
always @(*) begin: errorSigDirectionBlock
	if(guardTime & ~isoSio)
		{cardTx, termTx}={txDir[0],txDir[1]};
	else
		{cardTx, termTx}={txDir[1],txDir[0]};
end
always @(posedge isoClk, negedge nReset) begin: comDirectionBlock
	if(~nReset | ~run) begin
		txDir<=2'b00;
	end else begin
		if(~guardTime) begin //{waitCardTx, waitTermTx} is updated during stop bits so we hold current value here
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

