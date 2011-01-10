`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sebastien Riou
// 
// Create Date:    18:05:27 01/09/2011 
// Design Name: 
// Module Name:    clkDivider 
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

/*
Basic clock divider

if divider=0
	dividedClk=clk
else
	F(dividedClk)=F(clk)/(divider*2)
	dividedClk has a duty cycle of 50%	

WARNING:	
	To change divider on the fly:
		1. set it to 0 at least for one cycle
		2. set it to the new value.
*/
module ClkDivider(
	input nReset,
	input clk,									// input clock
	input [DIVIDER_WIDTH-1:0] divider,	// divide factor
	output dividedClk,						// divided clock
	output divideBy1,
	output match,
	output risingMatch,
	output fallingMatch
	); 
//parameters to override
parameter DIVIDER_WIDTH = 16;
	
	reg out;//internal divided clock
	reg [DIVIDER_WIDTH-1:0] cnt;
  
	// if divider=0, dividedClk = clk.
	assign divideBy1 = |divider ? 1'b0 : 1'b1;
	assign dividedClk = divideBy1 ? clk : out;
	
	assign match = (cnt==(divider-1));
	assign risingMatch = match & ~out;
	assign fallingMatch = match & out;
	
	always @(posedge clk, negedge nReset)
	begin
		if(~nReset | divideBy1) begin
			cnt <= 0;
			out <= 1'b0;
		end else if(~divideBy1)	begin
			if(match) begin
				cnt <= 0;
				out <= ~out;
			end else begin
				cnt <= cnt + 1'b1;
			end
		end
	end

endmodule
