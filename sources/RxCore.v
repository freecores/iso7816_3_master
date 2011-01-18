`timescale 1ns / 1ps
`default_nettype none
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
module RxCore(
   output reg [7:0] dataOut,
   output reg overrunErrorFlag,	//new data has been received before dataOut was read
   output reg dataOutReadyFlag,	//new data available
   output reg frameErrorFlag,		//bad parity or bad stop bits
   output reg endOfRx,				//one cycle pulse: 1 during last cycle of last stop bit
   output reg run,					//rx is definitely started, one of the three flag will be set
   output wire startBit,			//rx is started, but we don't know yet if real rx or just a glitch
	output wire stopBit,				//rx is over but still in stop bits
	input wire [CLOCK_PER_BIT_WIDTH-1:0] clocksPerBit,			
	input wire stopBit2,//0: 1 stop bit, 1: 2 stop bits
	input wire oddParity, //if 1, parity bit is such that data+parity have an odd number of 1
   input wire msbFirst,  //if 1, bits order is: startBit, b7, b6, b5...b0, parity
	input wire ackFlags,
	input wire serialIn,
	input wire clk,
   input wire nReset,
	//to connect to an instance of Counter.v (see RxCoreSelfContained.v for example)
	output reg [CLOCK_PER_BIT_WIDTH-1:0] bitClocksCounterCompare,
	output reg bitClocksCounterInc,
	output reg bitClocksCounterClear,
	output wire bitClocksCounterInitVal,
   input wire bitClocksCounterEarlyMatch,
	input wire bitClocksCounterMatch
    );

//parameters to override
parameter CLOCK_PER_BIT_WIDTH = 13;	//allow to support default speed of ISO7816

//default conventions
parameter START_BIT = 1'b0;
parameter STOP_BIT1 = 1'b1;
parameter STOP_BIT2 = 1'b1;

//constant definition for states
localparam IDLE_STATE = 	3'b000;
localparam START_STATE = 	3'b001;
localparam DATA_STATE = 	3'b011;
localparam PARITY_STATE = 	3'b010;
localparam STOP1_STATE = 	3'b110;
localparam STOP2_STATE = 	3'b111;
localparam END_STATE = 		3'b101;
localparam END2_STATE =    3'b100;

localparam IDLE_BIT = ~START_BIT;

reg [2:0] nextState;

reg [2:0] bitCounter;
wire [2:0] bitIndex = msbFirst ? 7-bitCounter : bitCounter;
reg parityBit;

wire internalIn;
wire parityError;

assign startBit = (nextState == START_STATE);
assign stopBit = (nextState == STOP1_STATE) | (nextState == STOP2_STATE);
assign internalIn = serialIn;
assign parityError= parityBit ^ internalIn ^ 1'b1;
reg flagsSet;

assign bitClocksCounterInitVal=(nextState==IDLE_STATE);
always @(nextState, clocksPerBit, run, bitClocksCounterMatch) begin
	case(nextState)
		IDLE_STATE: begin
			bitClocksCounterCompare = (clocksPerBit/2);
			bitClocksCounterInc = run & ~bitClocksCounterMatch;//stop when reach 0
			bitClocksCounterClear = ~run;
		end
		START_STATE: begin
			bitClocksCounterCompare = (clocksPerBit/2);
			bitClocksCounterInc = 1;
			bitClocksCounterClear = 0;
		end
		STOP2_STATE: begin
         //make the rx operation is one cycle shorter, 
         //since we detect the start bit at least one cycle later it starts.
			bitClocksCounterCompare = clocksPerBit-1;
			bitClocksCounterInc = 1;
			bitClocksCounterClear = 0;
		end
		default: begin
			bitClocksCounterCompare = clocksPerBit;
			bitClocksCounterInc = 1;
			bitClocksCounterClear = 0;		
		end
	endcase
end

always @(posedge clk, negedge nReset) begin
	if(~nReset) begin
		nextState <= #1 IDLE_STATE;
		bitCounter <= #1 0;
		parityBit <= #1 0;
		overrunErrorFlag <= #1 0;
		dataOutReadyFlag <= #1 0;
		frameErrorFlag <= #1 0;
		run <= #1 0;
      endOfRx <= #1 0;
	end else begin	
		case(nextState)
			IDLE_STATE: begin
				if(bitClocksCounterEarlyMatch)
               endOfRx <= #1 1'b1;
            if(bitClocksCounterMatch)
               endOfRx <= #1 0;
            if(ackFlags) begin
					//overrunErrorFlag is auto cleared at PARITY_STATE
					//meanwhile, it prevent dataOutReadyFlag to be set by the termination of the lost byte
					dataOutReadyFlag <= #1 0;
					frameErrorFlag <= #1 0;
				end
				if(START_BIT == internalIn) begin
					if(frameErrorFlag | overrunErrorFlag) begin
						//wait clear from outside
						if(bitClocksCounterMatch) begin
                     //endOfRx <= #1 0;
							run <= #1 0;
                  end
					end else begin
						parityBit <= #1 oddParity;
						run <= #1 0;
						nextState <= #1 START_STATE;
					end
				end else begin
					if(bitClocksCounterMatch) begin
                  //endOfRx <= #1 0;
						run <= #1 0;
               end
				end
			end
			START_STATE: begin
				if(ackFlags) begin
					dataOutReadyFlag <= #1 0;
					frameErrorFlag <= #1 0;
				end
				if(bitClocksCounterMatch) begin
					if(START_BIT != internalIn) begin
						nextState <= #1 IDLE_STATE;
					end else begin
						run <= #1 1;
						nextState <= #1 DATA_STATE;
					end
				end
			end
			DATA_STATE: begin
				if(ackFlags) begin
					dataOutReadyFlag <= #1 0;
					frameErrorFlag <= #1 0;
				end
				if(bitClocksCounterMatch) begin
					if(dataOutReadyFlag) begin
						overrunErrorFlag <= #1 1;
					end else
						dataOut[bitIndex] <= #1 internalIn;			
					parityBit <= #1 parityBit ^ internalIn;
					bitCounter <= #1 (bitCounter + 1'b1) & 3'b111;
					if(bitCounter == 7)
						nextState <= #1 PARITY_STATE;
				end
			end
			PARITY_STATE: begin
				if(bitClocksCounterMatch) begin
					if(~overrunErrorFlag) begin
						frameErrorFlag <= #1 parityError;
						dataOutReadyFlag <= #1 ~parityError;
					end else if(ackFlags) begin
						frameErrorFlag <= #1 0;
					end
					flagsSet=1;
					if(stopBit2)
						nextState <= #1 STOP1_STATE;
					else
						nextState <= #1 STOP2_STATE;
				end else if(ackFlags) begin
					dataOutReadyFlag <= #1 0;
					frameErrorFlag <= #1 0;
				end
			end
			STOP1_STATE: begin
				if(ackFlags) begin
					dataOutReadyFlag <= #1 0;
				end
				if(bitClocksCounterMatch) begin
					if(STOP_BIT1 != internalIn) begin
						frameErrorFlag <= #1 parityError;
					end else if(ackFlags) begin
						frameErrorFlag <= #1 0;
					end
					nextState <= #1 STOP2_STATE;
				end else if(ackFlags) begin
					frameErrorFlag <= #1 0;
				end
			end
			STOP2_STATE: begin
				if(ackFlags) begin
					dataOutReadyFlag <= #1 0;
				end
            if(bitClocksCounterMatch) begin
					if(STOP_BIT2 != internalIn) begin
						frameErrorFlag <= #1 1;
					end else if(ackFlags) begin
						frameErrorFlag <= #1 0;
					end
					nextState <= #1 IDLE_STATE;
				end else if(ackFlags) begin
					frameErrorFlag <= #1 0;
				end
			end
			default: nextState <= #1 IDLE_STATE;
		endcase
	end
end

endmodule
