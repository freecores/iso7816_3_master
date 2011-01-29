/*
Author: Sebastien Riou (acapola)
Creation date: 22:22:43 01/10/2011 

$LastChangedDate$
$LastChangedBy$
$LastChangedRevision$
$HeadURL$				 

This file is under the BSD licence:
Copyright (c) 2011, Sebastien Riou

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 
The names of contributors may not be used to endorse or promote products derived from this software without specific prior written permission. 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
`default_nettype none


module Iso7816_3_t0_analyzer 
#(parameter DIVIDER_WIDTH = 1)
(
	input wire nReset,
	input wire clk,
	input wire [DIVIDER_WIDTH-1:0] clkPerCycle,
	input wire isoReset,
	input wire isoClk,
	input wire isoVdd,
	input wire isoSioTerm,
	input wire isoSioCard,
	input wire useDirectionProbe,//if 1, isoSioTerm and isoSioCard must be connected to Iso7816_directionProbe outputs
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
	output wire cardTx,
	output wire termTx,
	output wire guardTime,
	output wire overrunError,
	output wire frameError,
	output reg [7:0] lastByte,
	output reg [31:0] bytesCnt
	);

wire isoSio = isoSioTerm & isoSioCard;
	
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
wire [12:0] clocksPerBit = cyclesPerEtu-1;
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
    .clocksPerBit(clocksPerBit), 
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
localparam T0_HEADER_TPDU = 1;
localparam T0_PB = 2;
localparam T0_DATA = 3;
localparam T0_NACK_DATA = 4;
localparam T0_SW1 = 5;
localparam T0_SW2 = 6;
localparam T0_HEADER_PPS = 100;

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
		{waitCardTx,waitTermTx}<=2'b00;
		fsmState<=ATR_TDI;
		atrHasTck<=1'b0;
		tempBytesCnt<=8'h0;
		tdiStruct<=12'h0;
		atrCompleted<=1'b0;
		atrK<=4'b0;
	end else if(isActivated) begin
		if(~tsReceived) begin
			{waitCardTx,waitTermTx}<=2'b10;
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
							if(12'h0=={dataOut,atrK}) begin
								atrCompleted <= 1'b1;
								{waitCardTx,waitTermTx}<=2'b01;
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
							tempBytesCnt <= 8'h0;
							if(atrHasTck) begin
								fsmState <= ATR_TCK;
							end else begin
								atrCompleted <= ~atrHasTck;
								{waitCardTx,waitTermTx}<=2'b10;
								fsmState <= T0_HEADER;
							end
						end else begin
							tempBytesCnt <= tempBytesCnt+1;
						end
					end
				end
				ATR_TCK: begin
					if(endOfRx) begin
					//TODO:check
						atrCompleted <= 1'b1;
						{waitCardTx,waitTermTx}<=2'b10;
						fsmState <= T0_HEADER;
					end
				end
			endcase
		end else if(useT0) begin
			//T=0 cmd/response monitoring state machine
			case(fsmState)
				T0_HEADER: begin
					if(endOfRx) begin
						tpduHeader[CLA_I+:8]<=dataOut;
						tempBytesCnt <= 1;
						if(8'hFF==dataOut)
							fsmState <= T0_HEADER_PPS;//TODO
						else
							fsmState <= T0_HEADER_TPDU;
					end
				end
				T0_HEADER_TPDU: begin
					if(endOfRx) begin
						tpduHeader[(CLA_I-(tempBytesCnt*8))+:8]<=dataOut;
						if(4==tempBytesCnt) begin
							tempBytesCnt <= 8'h0;
							fsmState <= T0_PB;
							{waitCardTx,waitTermTx}<=2'b10;
						end else begin
							tempBytesCnt <= tempBytesCnt+1;
						end
					end
				end
				T0_PB: begin
					if(endOfRx) begin
						case(dataOut[7:4])
							4'h6: begin
								fsmState <= (4'h0==dataOut[3:0]) ? T0_PB : T0_SW2;
							end
							4'h9: begin
								fsmState <= T0_SW2;
							end
							default: begin
								case(dataOut)
									tpduHeader[INS_I+:8]: begin//ACK
										fsmState <= T0_DATA;
										{waitCardTx,waitTermTx}<=2'b11;
									end
									~tpduHeader[INS_I+:8]: begin//NACK
										fsmState <= T0_NACK_DATA;
										{waitCardTx,waitTermTx}<=2'b11;
									end
									default: begin //invalid
										//TODO
									end
								endcase
							end
						endcase
					end
				end
				T0_NACK_DATA: begin
					if(endOfRx) begin
						fsmState <= T0_PB;
						{waitCardTx,waitTermTx}<=2'b10;
						tempBytesCnt <= tempBytesCnt+1;
					end
				end
				T0_SW1: begin
					if(endOfRx) begin
					//TODO:check != 60 but equal to 6x or 9x
						fsmState <= T0_SW2;
						{waitCardTx,waitTermTx}<=2'b10;
					end
				end
				T0_SW2: begin
					if(endOfRx) begin
						fsmState <= T0_HEADER;
						{waitCardTx,waitTermTx}<=2'b01;
					end
				end
				T0_DATA: begin
					if(endOfRx) begin
						if(tempBytesCnt==(tpduHeader[P3_I+:8]-1)) begin
							tempBytesCnt <= 0;
							fsmState <= T0_SW1;
							{waitCardTx,waitTermTx}<=2'b10;
						end else begin
							tempBytesCnt <= tempBytesCnt+1;
						end
					end
				end
			endcase		
		end
	end
end

reg [1:0] txDir;
reg proto_cardTx;
reg proto_termTx;
always @(*) begin: protoComDirectionCombiBlock
	if(guardTime & ~isoSio)
		{proto_cardTx, proto_termTx}={txDir[0],txDir[1]};
	else
		{proto_cardTx, proto_termTx}={txDir[1],txDir[0]};
end
always @(posedge isoClk, negedge nReset) begin: protoComDirectionSeqBlock
	if(~nReset | ~run) begin
		txDir<=2'b00;
	end else begin
		if(~guardTime) begin //{waitCardTx, waitTermTx} is updated during stop bits so we hold current value here
			case({waitCardTx, waitTermTx})
				2'b00: txDir<=2'b00;//no one should/is sending
				2'b01: txDir<=2'b01;//terminal should/is sending
				2'b10: txDir<=2'b10;//card should/is sending
				2'b11: txDir<=2'b11;//either card OR terminal should/is sending (we just don't know)
			endcase
		end
	end
end		

reg phy_cardTx;
reg phy_termTx;
always @(negedge isoSio, negedge nReset) begin: phyComDirectionBlock
	if(~nReset) begin
		phy_cardTx<=1'b0;
		phy_termTx<=1'b0;
	end else begin
		if(~isoSioTerm) begin
			phy_cardTx<=1'b0;
			phy_termTx<=1'b1;
		end else begin
			phy_cardTx<=1'b1;
			phy_termTx<=1'b0;
		end
	end
end

assign cardTx = useDirectionProbe ? phy_cardTx : proto_cardTx;
assign termTx = useDirectionProbe ? phy_termTx : proto_termTx;
		
endmodule
`default_nettype wire

