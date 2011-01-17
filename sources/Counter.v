`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sebastien Riou
// 
// Create Date:    23:57:02 08/31/2010 
// Design Name: 
// Module Name:    Counter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: A counter with increment and clear operation
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Counter(
    output reg [WIDTH-1:0] counter,
    output wire earlyMatch,
	 output reg match,
	 output wire dividedClk,
	 input wire [DIVIDER_WIDTH-1:0] divider,	// clock divide factor
	 input wire [WIDTH-1:0] compare,
	 input wire inc,
	 input wire clear,
	 input wire [WIDTH_INIT-1:0] initVal,
	 input wire clk,
    input wire nReset
    );

//parameters to override
parameter DIVIDER_WIDTH = 16;
parameter WIDTH = 8;
parameter WIDTH_INIT = 1;

wire divideBy1;
wire divMatch;
wire divRisingMatch;
wire divFallingMatch;

ClkDivider #(.DIVIDER_WIDTH(DIVIDER_WIDTH))
	clkDivider(
		.nReset(nReset),
		.clk(clk),
		.divider(divider),
		.dividedClk(dividedClk),
		.divideBy1(divideBy1),
		.match(divMatch),
		.risingMatch(divRisingMatch),
		.fallingMatch(divFallingMatch)
		);

wire [WIDTH-1:0] nextCounter = counter+1'b1;

wire doInc = divideBy1 ? inc :inc & divRisingMatch;
wire doEarlyMatch = divideBy1 ? (compare == nextCounter) : (compare == counter) & divRisingMatch;

reg earlyMatchReg;
assign earlyMatch = divideBy1 ? earlyMatchReg : doEarlyMatch;

always @(posedge clk, negedge nReset) begin
	if(~nReset) begin
		counter <= 0;//initVal;
      earlyMatchReg <= 0;
		match <= 0;
	end else begin
		if(clear) begin
			counter <= initVal;
		end else if(doInc) begin
			if(compare == counter)
				counter <= initVal;
			else
				counter <= nextCounter;
		end
		if(doEarlyMatch)
			earlyMatchReg <= 1;
		else begin
			earlyMatchReg <= 0;
		end
      match <= divideBy1 ? earlyMatchReg : doEarlyMatch;
	end					
end

endmodule
