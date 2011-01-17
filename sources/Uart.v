`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sebastien Riou
// 
// Create Date:    23:57:02 08/31/2010 
// Design Name: 
// Module Name:    Uart 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: Half duplex UART with 1 byte buffer
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module BasicHalfDuplexUart(
    output wire [7:0] rxData,
    output wire overrunErrorFlag,	//new data has been received before dataOut was read
    output wire dataOutReadyFlag,	//new data available
    output wire frameErrorFlag,		//bad parity or bad stop bits
    output wire txRun,					//tx is started
    output wire endOfRx,           //one cycle pulse: 1 during last cycle of last stop bit of rx
    output wire rxRun,					//rx is definitely started, one of the three flag will be set
    output wire rxStartBit,			//rx is started, but we don't know yet if real rx or just a glitch
    output wire txFull,
    output wire isTx,              //1 only when tx is ongoing. Indicates the direction of the com line.
    
	 input wire serialIn,				//signals to merged into a inout signal according to "isTx"
	 output wire serialOut,
	 output wire comClk,
	 
    input wire [DIVIDER_WIDTH-1:0] clkPerCycle,
	 input wire [7:0] txData,
	 input wire [CLOCK_PER_BIT_WIDTH-1:0] clocksPerBit,			
	 input wire stopBit2,//0: 1 stop bit, 1: 2 stop bits
	 input wire oddParity, //if 1, parity bit is such that data+parity have an odd number of 1
    input wire msbFirst,  //if 1, bits order is: startBit, b7, b6, b5...b0, parity
	 input wire startTx,
	 input wire ackFlags,
	 input wire clk,
    input wire nReset
    );

//parameters to override
parameter DIVIDER_WIDTH = 1;
parameter CLOCK_PER_BIT_WIDTH = 13;	//allow to support default speed of ISO7816
//invert the polarity of the output or not
parameter IN_POLARITY = 1'b0;
parameter PARITY_POLARITY = 1'b1;
//default conventions
parameter START_BIT = 1'b0;
parameter STOP_BIT1 = 1'b1;
parameter STOP_BIT2 = 1'b1;

//constant definition for states
localparam IDLE_STATE = 	3'b000;
localparam RX_STATE = 	3'b001;
localparam TX_STATE = 	3'b011;

wire rxSerialIn = isTx ? STOP_BIT1 : serialIn;
//wire serialOut;
wire loadDataIn;

wire txStopBits;

assign isTx = txRun & ~txStopBits;
//let this to top level to avoid inout signal
//assign serialLine = isTx ? serialOut : 1'bz;

assign loadDataIn = startTx & ~rxStartBit & (~rxRun | endOfRx);

/*//complicated approach... instead we can simply divide the clock at lower levels
wire useEarlyComClk = |clkPerCycle ? 1'b1:1'b0;
reg dividedClk;
wire earlyComClk;//earlier than comClk by 1 cycle of clk (use to make 1 cycle pulse signals)
always @(posedge clk)begin
	if(useEarlyComClk)
		dividedClk <= earlyComClk;
end
assign comClk=useEarlyComClk ? dividedClk : clk;//clock for communication
wire endOfRxComClk;//pulse of 1 cycle of comClk
assign endOfRx = useEarlyComClk ? endOfRxComClk & earlyComClk & ~comClk : endOfRxComClk;//pulse of 1 cycle of clk
ClkDivider #(.DIVIDER_WIDTH(DIVIDER_WIDTH))
	clkDivider(
		.nReset(nReset),
		.clk(clk),
		.divider(clkPerCycle),
		.dividedClk(earlyComClk)
		);
*/	

// Instantiate the module
RxCoreSelfContained #(
		.DIVIDER_WIDTH(DIVIDER_WIDTH),
		.PARITY_POLARITY(PARITY_POLARITY))
	rxCore (
    .dataOut(rxData), 
    .overrunErrorFlag(overrunErrorFlag), 
    .dataOutReadyFlag(dataOutReadyFlag), 
    .frameErrorFlag(frameErrorFlag), 
    .endOfRx(endOfRx),
    .run(rxRun), 
    .startBit(rxStartBit), 
	 .clkPerCycle(clkPerCycle),
    .clocksPerBit(clocksPerBit), 
    .stopBit2(stopBit2), 
    .oddParity(oddParity),
    .msbFirst(msbFirst),
	 .ackFlags(ackFlags), 
    .serialIn(rxSerialIn), 
    .comClk(comClk), 
    .clk(clk), 
    .nReset(nReset)
    );
TxCore #(.DIVIDER_WIDTH(DIVIDER_WIDTH))
	txCore (
	.serialOut(serialOut), 
	.run(txRun), 
	.full(txFull), 
   .stopBits(txStopBits),
	.dataIn(txData), 
	.clkPerCycle(clkPerCycle),
	.clocksPerBit(clocksPerBit),
	.stopBit2(stopBit2),
   .oddParity(oddParity),
   .msbFirst(msbFirst),
	.loadDataIn(loadDataIn), 
	.comClk(comClk), 
   .clk(clk), 
   .nReset(nReset)
);

endmodule
