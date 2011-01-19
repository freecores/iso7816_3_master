
`timescale 1ns / 1ps
`default_nettype none

module HammingWeight(
	dataIn,
	hammingWeight
	);
parameter DATA_WIDTH=4;
parameter WEIGHT_WIDTH=2;

input wire [DATA_WIDTH-1:0] dataIn;
output reg [WEIGHT_WIDTH-1:0] hammingWeight;

always @(*) begin:hamminWeightBlock
	integer i;
	for(i=0;i<DATA_WIDTH;i=i+1) begin
		hammingWeight=hammingWeight + dataIn[i];
	end
end
endmodule

/*
task hammingWeight
parameter DATA_WIDTH=4;
parameter WEIGHT_WIDTH=2;
input wire [DATA_WIDTH-1:0] dataIn;
output reg [WEIGHT_WIDTH-1:0] hammingWeight;
integer i;
begin
	
	for(i=0;i<DATA_WIDTH;i=i+1) begin
		hammingWeight=hammingWeight + dataIn[i];
	end
	
end
endtask
*/
/*
function hammingWeight
parameter DATA_WIDTH=4;
parameter WEIGHT_WIDTH=2;
input wire [DATA_WIDTH-1:0] dataIn;
output reg [WEIGHT_WIDTH-1:0] hammingWeight;
integer i;
begin
	
	for(i=0;i<DATA_WIDTH;i=i+1) begin
		hammingWeight=hammingWeight + dataIn[i];
	end
	
end
endtask
*/