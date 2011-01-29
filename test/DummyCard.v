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

module DummyCard(
	input wire isoReset,
	input wire isoClk,
	input wire isoVdd,
	inout wire isoSio
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
	reg [12:0] cyclesPerEtu;

	wire cardIsoClk;//card use its own generated clock (like true UARTs)
	HalfDuplexUartIf uartIf (
		.nReset(isoReset), 
		.clk(isoClk), 
		.clkPerCycle(clkPerCycle), 
		.dataIn(dataIn), 
		.nWeDataIn(nWeDataIn), 
		.clocksPerBit(cyclesPerEtu), 
		.dataOut(dataOut), 
		.nCsDataOut(nCsDataOut), 
		.statusOut(statusOut), 
		.nCsStatusOut(nCsStatusOut), 
		.serialIn(isoSio), 
		.serialOut(serialOut),  
		.comClk(cardIsoClk)
	);

reg sendAtr;
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

wire txRun,txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull;
assign {txRun, txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull} = statusOut;

`include "ComDriverTasks.v"

assign isoSio = isTx ? serialOut : 1'bz;


/*T=0 card model

ATR:
	3B 00

Implemented commands: 
	write buffer: 
		tpdu: 00 0C 00 00 LC data
		sw:   90 00
	read buffer:
		tpdu: 00 0A 00 00 LE
		response: data
		sw:   90 00
	any other:
		sw:   69 86
*/
task sendAckByte;
	sendByte(tpduHeader[INS_I+7:INS_I]);
endtask

task writeBufferCmd;
integer i;
begin
	sendAckByte;
	for(i=0;i<tpduHeader[P3_I+7:P3_I];i=i+1) begin
		receiveByte(buffer[i]);
	end
	sendHexBytes("9000");//sendWord(16'h9000);
end
endtask

task readBufferCmd;
integer i;
integer le;
begin
	sendAckByte;
	le=tpduHeader[P3_I+7:P3_I];
	if(0==le) le=256;
	for(i=0;i<le;i=i+1) begin
		sendByte(buffer[i]);
	end
	sendHexBytes("9000");//sendWord(16'h9000);
end
endtask

integer i;
always @(posedge isoClk, negedge isoReset) begin
	if(~isoReset) begin
		nWeDataIn<=1'b1;
		nCsDataOut<=1'b1;
		nCsStatusOut<=1'b1;
		tsCnt<=9'b0;
		sendAtr<=1'b1;
		cyclesPerEtu <= 13'd372-1'b1;
	end else if(tsCnt!=9'd400) begin
		tsCnt <= tsCnt + 1'b1;
	end else if(sendAtr) begin
		sendAtr<=1'b0;
		sendHexBytes("3B00");
		waitEndOfTx;
	end else begin
		//get CLA
		receiveByte(tpduHeader[CLA_I+:8]);
		
		//get INS~P2 or PPS
		for(i=1;i<4;i=i+1)
			receiveByte(tpduHeader[(CLA_I-(i*8))+:8]);
		
		if(8'hFF==tpduHeader[CLA_I+:8]) begin
			//support only PPS8 for the time being
			if(32'hFF789778==tpduHeader[7+CLA_I:P2_I]) begin
				sendHexBytes("FF789778");
				waitEndOfTx;
				cyclesPerEtu <= 13'd8-1'b1;
			end
		end else begin
			//tpdu: get P3
			receiveByte(tpduHeader[P3_I+:8]);
			//dispatch
			case(tpduHeader[7+CLA_I:P2_I])
					32'h000C0000: writeBufferCmd;
					32'h000A0000: readBufferCmd;
					default: sendHexBytes("6986");//sendWord(16'h6986);
			endcase
		end
	end
end
      
endmodule
`default_nettype wire

