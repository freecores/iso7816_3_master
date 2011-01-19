`timescale 1ns / 1ps
`default_nettype none

module TsAnalyzer(
	input wire nReset,
	input wire isoReset,
	input wire isoClk,
	input wire isoVdd,
	input wire isoSio,
	input wire endOfRx,
	input wire [7:0] rxData,//assumed to be sent lsb first, high level coding logical 1.
	output wire isActivated,
	output wire tsReceived,
	output wire tsError,
	output wire atrIsEarly,//high if TS received before 400 cycles after reset release
	output wire atrIsLate,//high if TS is still not received after 40000 cycles after reset release
	output wire useIndirectConvention
	);

	
reg [8:0] tsCnt;//counter to start ATR 400 cycles after reset release

reg [16:0] resetCnt;
reg waitTs;
assign tsReceived = ~waitTs;
reg [7:0] ts;
assign atrIsEarly = ~waitTs & (resetCnt<(16'h100+16'd400));
assign atrIsLate = resetCnt>(16'h100+16'd40000);
assign useIndirectConvention = ~waitTs & (ts==8'hFC);//FC is 3F written LSB first
assign tsError = ~waitTs & (ts!=8'h3B) & ~useIndirectConvention;

assign isActivated = isoReset & isoVdd;

always @(posedge isoClk, negedge nReset) begin
	if(~nReset) begin
		resetCnt<=16'b0;
		waitTs<=1'b1;
	end else if(isActivated) begin
		if(waitTs) begin
			if(endOfRx) begin
				waitTs<=1'b0;
				ts<=rxData;
			end
			resetCnt<=resetCnt+1;
		end
	end else begin
		if(isoVdd & isoReset) begin
			resetCnt<=resetCnt + 1;
		end else begin
			resetCnt<=16'b0;
		end
	end
end
		
endmodule

