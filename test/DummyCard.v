`timescale 1ns / 1ps
`default_nettype none
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
	

	wire cardIsoClk;//card use its own generated clock (like true UARTs)
	HalfDuplexUartIf uartIf (
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
	sendWord(16'h9000);
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
	sendWord(16'h9000);
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
	end else if(tsCnt!=9'd400) begin
		tsCnt <= tsCnt + 1'b1;
	end else if(sendAtr) begin
		sendAtr<=1'b0;
		sendByte(8'h3B);
		sendByte(8'h00);
		waitEndOfTx;
	end else begin
		//get tpdu
		for(i=0;i<5;i=i+1)
			receiveByte(tpduHeader[(CLA_I-(i*8))+:8]);
		//dispatch
		case(tpduHeader[7+CLA_I:P2_I])
				32'h000C0000: writeBufferCmd;
				32'h000A0000: readBufferCmd;
				default: sendWord(16'h6986);
		endcase
	end
end
      
endmodule

