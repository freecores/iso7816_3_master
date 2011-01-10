`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:57:35 10/31/2010 
// Design Name: 
// Module Name:    HalfDuplexUartIf 
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
module HalfDuplexUartIf(
    input nReset,
    input clk,
    input [DIVIDER_WIDTH-1:0] clkPerCycle,
	 input [7:0] dataIn,
    input nWeDataIn,
    output [7:0] dataOut,
    input nCsDataOut,
    output [7:0] statusOut,
    input nCsStatusOut,
    input serialIn,
	 output serialOut,
	 output comClk
    );
//parameters to override
parameter DIVIDER_WIDTH = 1;

   reg [7:0] dataReg;

	// Inputs
	wire [7:0] txData;
	wire [12:0] clocksPerBit;
	wire stopBit2=1;
	wire oddParity=0; //if 1, parity bit is such that data+parity have an odd number of 1
   wire msbFirst=0;  //if 1, bits will be send in the order startBit, b7, b6, b5...b0, parity
	reg txPending;
	wire ackFlags;

	// Outputs
	wire [7:0] rxData;
	wire overrunErrorFlag;
	wire dataOutReadyFlag;
	wire frameErrorFlag;
	wire txRun;
   wire endOfRx;
	wire rxRun;
	wire rxStartBit;
	wire txFull;
	wire isTx;
   
   wire rxFlagsSet = dataOutReadyFlag | overrunErrorFlag | frameErrorFlag;
   reg bufferFull;
   reg [1:0] flagsReg;
   
   assign txData = dataReg;
   assign clocksPerBit = 7;

   assign dataOut=dataReg;
   assign statusOut[7:0]={txRun, txPending, rxRun, rxStartBit, isTx, flagsReg, bufferFull};

reg waitTxFull0;//internal reg for managing bufferFull bit in Tx

assign ackFlags=~txPending & ~txRun & rxFlagsSet & ((bufferFull & ~nCsDataOut)| ~bufferFull);

always @(posedge clk, negedge nReset) begin
   if(~nReset) begin
      bufferFull <= 1'b0;
      flagsReg <= 1'b0;
      txPending <= 1'b0;
   end else begin
      if(ackFlags) begin
         dataReg <= rxData;
         flagsReg <= {overrunErrorFlag, frameErrorFlag};
         if(rxFlagsSet)
            bufferFull <= 1'b1;
         else
            bufferFull <= 1'b0;
      end else if(txPending) begin
         if(waitTxFull0) begin
            if(~txFull)
               waitTxFull0 <= 1'b0;
         end else if(txFull) begin//tx actually started, clear txPending and free buffer
            txPending <= 1'b0;
            bufferFull <= 1'b0; //buffer is empty
         end
      end else if(~nCsDataOut) begin
         bufferFull <= 1'b0;
      end else if(~nWeDataIn) begin
         dataReg <= dataIn;
         bufferFull <= 1'b1;
         txPending <= 1'b1;
         waitTxFull0 <= txFull;
      end
   end
end   

	BasicHalfDuplexUart #(.DIVIDER_WIDTH(DIVIDER_WIDTH))
	uart (
		.rxData(rxData), 
		.overrunErrorFlag(overrunErrorFlag), 
		.dataOutReadyFlag(dataOutReadyFlag), 
		.frameErrorFlag(frameErrorFlag), 
		.txRun(txRun), 
		.endOfRx(endOfRx),
      .rxRun(rxRun), 
		.rxStartBit(rxStartBit), 
		.txFull(txFull), 
		.isTx(isTx), 
		.serialIn(serialIn),
		.serialOut(serialOut),
		.comClk(comClk),
		.txData(txData), 
		.clocksPerBit(clocksPerBit), 
		.stopBit2(stopBit2), 
		.oddParity(oddParity), 
      .msbFirst(msbFirst),  
	   .startTx(txPending), 
		.ackFlags(ackFlags),
		.clkPerCycle(clkPerCycle),
		.clk(clk), 
		.nReset(nReset)
	);

endmodule
