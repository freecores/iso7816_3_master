`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sebastien Riou
// 
// Create Date:    23:57:02 08/31/2010 
// Design Name: 
// Module Name:    RxCore 
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
module RxCoreSelfContained(
    output [7:0] dataOut,
    output overrunErrorFlag,	//new data has been received before dataOut was read
    output dataOutReadyFlag,	//new data available
    output frameErrorFlag,		//bad parity or bad stop bits
    output endOfRx,				//one cycle pulse: 1 during last cycle of last stop bit
    output run,					//rx is definitely started, one of the three flag will be set
    output startBit,				//rx is started, but we don't know yet if real rx or just a glitch
	 input [DIVIDER_WIDTH-1:0] clkPerCycle,
	 input [CLOCK_PER_BIT_WIDTH-1:0] clocksPerBit,			
	 input stopBit2,//0: 1 stop bit, 1: 2 stop bits
	 input oddParity, //if 1, parity bit is such that data+parity have an odd number of 1
    input msbFirst,  //if 1, bits order is: startBit, b7, b6, b5...b0, parity
	 input ackFlags,
	 input serialIn,
    input comClk,//not used yet
    input clk,
    input nReset
    );

//parameters to override
parameter DIVIDER_WIDTH = 1;
parameter CLOCK_PER_BIT_WIDTH = 13;	//allow to support default speed of ISO7816
//invert the polarity of the output or not
//parameter IN_POLARITY = 1'b0;
//parameter PARITY_POLARITY = 1'b1;
//default conventions
parameter START_BIT = 1'b0;
parameter STOP_BIT1 = 1'b1;
parameter STOP_BIT2 = 1'b1;

wire [CLOCK_PER_BIT_WIDTH-1:0] bitClocksCounter;
wire bitClocksCounterEarlyMatch;
wire bitClocksCounterMatch;
wire [CLOCK_PER_BIT_WIDTH-1:0] bitClocksCounterCompare;
wire bitClocksCounterInc;
wire bitClocksCounterClear;
wire bitClocksCounterInitVal;
Counter #(	.DIVIDER_WIDTH(DIVIDER_WIDTH),
				.WIDTH(CLOCK_PER_BIT_WIDTH),
				.WIDTH_INIT(1)) 
		bitClocksCounterModule(
				.counter(bitClocksCounter),
				.earlyMatch(bitClocksCounterEarlyMatch),
				.match(bitClocksCounterMatch),
				.divider(clkPerCycle),
				.compare(bitClocksCounterCompare),
				.inc(bitClocksCounterInc),
				.clear(bitClocksCounterClear),
				.initVal(bitClocksCounterInitVal),
				.clk(clk),
				.nReset(nReset));

RxCore rxCore (
    .dataOut(dataOut), 
    .overrunErrorFlag(overrunErrorFlag), 
    .dataOutReadyFlag(dataOutReadyFlag), 
    .frameErrorFlag(frameErrorFlag), 
    .endOfRx(endOfRx),
    .run(run), 
    .startBit(startBit), 
    .clocksPerBit(clocksPerBit), 
    .stopBit2(stopBit2), 
    .oddParity(oddParity),
    .msbFirst(msbFirst),
	 .ackFlags(ackFlags), 
    .serialIn(serialIn), 
    .clk(clk), 
    .nReset(nReset),
	.bitClocksCounterEarlyMatch(bitClocksCounterEarlyMatch),
   .bitClocksCounterMatch(bitClocksCounterMatch),
	.bitClocksCounterCompare(bitClocksCounterCompare),
	.bitClocksCounterInc(bitClocksCounterInc),
	.bitClocksCounterClear(bitClocksCounterClear),
	.bitClocksCounterInitVal(bitClocksCounterInitVal)
    );

endmodule
