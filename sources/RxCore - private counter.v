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
module RxCore(
    output reg [7:0] dataOut,
    output reg overrunErrorFlag,	//new data has been received before dataOut was read
    output reg dataOutReadyFlag,	//new data available
    output reg frameErrorFlag,		//bad parity or bad stop bits
    output reg run,					//rx is definitely started, one of the three flag will be set
    output startBit,				//rx is started, but we don't know yet if real rx or just a glitch
	 input [CLOCK_PER_BIT_WIDTH-1:0] clocksPerBit,			
	 input stopBit2,//0: 1 stop bit, 1: 2 stop bits
	 input ackFlags,
	 input serialIn,
    input clk,
    input reset
    );

//parameters to override
parameter CLOCK_PER_BIT_WIDTH = 13;	//allow to support default speed of ISO7816
//invert the polarity of the output or not
parameter IN_POLARITY = 1'b0;
parameter PARITY_POLARITY = 1'b0;
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
reg [CLOCK_PER_BIT_WIDTH-1:0] bitClocksCounter;
//Counter #()bitClocksCounter();

reg [2:0] bitCounter;
//reg [7:0] dataBuffer;

reg parityBit;

wire internalIn;
wire parityError;

//assign run = (nextState != IDLE_STATE) && (nextState != START_STATE);
assign startBit = (nextState == START_STATE);
assign internalIn = serialIn ^ IN_POLARITY;
assign parityError= parityBit ^ internalIn ^ PARITY_POLARITY ^ 1'b1;
reg flagsSet;

always @(posedge clk, negedge reset) begin
	if(~reset) begin
		nextState <= #1 IDLE_STATE;
		bitCounter <= #1 0;
		parityBit <= #1 0;
		overrunErrorFlag <= #1 0;
		dataOutReadyFlag <= #1 0;
		frameErrorFlag <= #1 0;
		run <= #1 0;
	end else begin	
		if(ackFlags) begin
			//overrunErrorFlag is auto cleared at PARITY_STATE
			//meanwhile, it prevent dataOutReadyFlag to be set by the termination of the lost byte
			//VERILOG_QUESTION: is that bad to assign flags here AND in PARITY_STATE ?
			//If this is a problem, how to avoid to duplicate those assignement in all states ??
			//TODO: check what happens if ackFlags=1 while PARITY_STATE, and decide what is the spec !
			dataOutReadyFlag <= #1 0;
			frameErrorFlag <= #1 0;
		end
		flagsSet=0;
		case(nextState)
			IDLE_STATE: begin
				if(START_BIT == internalIn) begin
					if(frameErrorFlag | overrunErrorFlag) begin
						//wait clear from outside
						if(run)
							bitClocksCounter <= #1 bitClocksCounter+1'b1;
						if((clocksPerBit/2)+1 == bitClocksCounter)//TODO: make a new state to avoid the +1 in comparison
							run <= #1 0;
					end else begin
						bitClocksCounter <= #1 1;
						parityBit <= #1 0;
						run <= #1 0;
						nextState <= #1 START_STATE;
					end
				end else begin
					if(run)
						bitClocksCounter <= #1 bitClocksCounter+1'b1;
					if((clocksPerBit/2)+1 == bitClocksCounter)//TODO: make a new state to avoid the +1 in comparison
						run <= #1 0;
				end
			end
			START_STATE: begin
				if(clocksPerBit/2 == bitClocksCounter) begin
					if(START_BIT != internalIn) begin
						bitClocksCounter <= #1 bitClocksCounter+1'b1;
						nextState <= #1 IDLE_STATE;
					end else begin
						bitClocksCounter <= #1 0;
						run <= #1 1;
						nextState <= #1 DATA_STATE;
					end
				end else begin
					bitClocksCounter <= #1 bitClocksCounter+1'b1;
				end	
			end
			DATA_STATE: begin
				if(clocksPerBit == bitClocksCounter) begin
					if(dataOutReadyFlag) begin
						overrunErrorFlag <= #1 1;
						//nextState <= #1 IDLE_STATE;
					end else
						dataOut[bitCounter] <= #1 internalIn;
					
					parityBit <= #1 parityBit ^ internalIn;
					bitCounter <= #1 (bitCounter + 1'b1) & 3'b111;
					if(bitCounter == 7)
						nextState <= #1 PARITY_STATE;
					bitClocksCounter <= #1 0;
				end else begin
					bitClocksCounter <= #1 bitClocksCounter+1'b1;
				end
			end
			PARITY_STATE: begin
				if(clocksPerBit == bitClocksCounter) begin
					if(~overrunErrorFlag) begin
						frameErrorFlag <= #1 parityError;
						dataOutReadyFlag <= #1 ~parityError;
					end
					flagsSet=1;
					if(stopBit2)
						nextState <= #1 STOP1_STATE;
					else
						nextState <= #1 STOP2_STATE;
					bitClocksCounter <= #1 0;
				end else begin
					bitClocksCounter <= #1 bitClocksCounter+1'b1;
				end
			end
			STOP1_STATE: begin
				if(clocksPerBit == bitClocksCounter) begin
					if(STOP_BIT1 != internalIn) begin
						frameErrorFlag <= #1 parityError;
						flagsSet=1;
					end
					bitClocksCounter <= #1 0;
					nextState <= #1 STOP2_STATE;
				end else begin
					bitClocksCounter <= #1 bitClocksCounter+1'b1;
				end
			end
			STOP2_STATE: begin
				if(clocksPerBit == bitClocksCounter) begin
					if(STOP_BIT2 != internalIn) begin
						frameErrorFlag <= #1 1;
						flagsSet=1;
					end
					bitClocksCounter <= #1 0;
					nextState <= #1 IDLE_STATE;
				end else begin
					bitClocksCounter <= #1 bitClocksCounter+1'b1;
				end
			end
			/*END_STATE: begin
				if((clocksPerBit/2) == bitClocksCounter) begin
					nextState <= #1 IDLE_STATE;
					bitClocksCounter <= #1 1;
				end else begin
					bitClocksCounter <= #1 bitClocksCounter+1'b1;
				end
			end*/
			/*END2_STATE: begin//just wait one last cycle to get exact timing for RUN bit
					nextState <= #1 IDLE_STATE;
			end*/
			default: nextState <= #1 IDLE_STATE;
		endcase
	end

end

endmodule
