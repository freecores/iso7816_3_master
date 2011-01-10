`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:45:51 10/31/2010
// Design Name:   HalfDuplexUartIf
// Module Name:   tb_HalfDuplexUartIf.v
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

module tb_HalfDuplexUartIf;
parameter CLK_PERIOD = 10;//should be %2
parameter DIVIDER_WIDTH = 16;
	// Inputs
	reg nReset;
	reg clk;
	reg [DIVIDER_WIDTH-1:0] clkPerCycle;
	reg [7:0] dataIn;
	reg nWeDataIn;
	reg nCsDataOut;
	reg nCsStatusOut;
	wire serialIn;

	// Outputs
	wire [7:0] dataOut;
	wire [7:0] statusOut;
	wire serialOut;
	wire isTx;

	// Inputs
	reg [7:0] dataIn2;
	reg nWeDataIn2;
	reg nCsDataOut2;
	reg nCsStatusOut2;
	wire serialIn2;

	// Outputs
	wire [7:0] dataOut2;
	wire [7:0] statusOut2;
	wire serialOut2;
	wire isTx2;

	// Bidirs
	wire serialLine = isTx ? serialOut : isTx2 ? serialOut2 : 1'bz;
   pullup(serialLine);

	assign serialIn = serialLine;
	assign serialIn2 = serialLine;
	
	// Instantiate the Unit Under Test (UUT)
	HalfDuplexUartIf #(.DIVIDER_WIDTH(DIVIDER_WIDTH))
	uut (
		.nReset(nReset), 
		.clk(clk), 
		.clkPerCycle(clkPerCycle),
		.dataIn(dataIn), 
		.nWeDataIn(nWeDataIn), 
		.dataOut(dataOut), 
		.nCsDataOut(nCsDataOut), 
		.statusOut(statusOut), 
		.nCsStatusOut(nCsStatusOut), 
		.serialIn(serialIn),
		.serialOut(serialOut),
		.isTx(isTx)
	);
   
   HalfDuplexUartIf #(.DIVIDER_WIDTH(DIVIDER_WIDTH))
	uut2 (
		.nReset(nReset), 
		.clk(clk), 
		.clkPerCycle(clkPerCycle),
		.dataIn(dataIn2), 
		.nWeDataIn(nWeDataIn2), 
		.dataOut(dataOut2), 
		.nCsDataOut(nCsDataOut2), 
		.statusOut(statusOut2), 
		.nCsStatusOut(nCsStatusOut2), 
		.serialIn(serialIn2),
		.serialOut(serialOut2),
		.isTx(isTx2)
	);
   
integer tbErrorCnt;
wire bufferFull = statusOut[0];
wire bufferFull2 = statusOut2[0];
wire txPending = statusOut[6];
wire txPending2 = statusOut2[6];

/*//this is sensitive to glitch in combo logic so we cannot use wait(txRun == 0) or @negedge(txRun)...
wire bufferFull = statusOut[0];
wire rxRun = statusOut[5];
wire txRun = statusOut[6];

wire bufferFull2 = statusOut2[0];
wire rxRun2 = statusOut2[5];
wire txRun2 = statusOut2[6];
*/
//reg bufferFull ;//already registered
reg rxRun ;
reg txRun ;

//reg bufferFull2 ;
reg rxRun2 ;
reg txRun2 ;
always @(posedge clk) begin
   //bufferFull <= statusOut[0];
   rxRun <= statusOut[5];
   txRun <= statusOut[7];
   //bufferFull2 <= statusOut2[0];
   rxRun2 <= statusOut2[5];
   txRun2 <= statusOut2[7];
end

task sendByte;
  input [7:0] data;
  begin
      wait(bufferFull==1'b0);
      dataIn=data;
      nWeDataIn=0;
      @(posedge clk);
      dataIn=8'hxx;
      nWeDataIn=1;
      @(posedge clk);
	end
endtask

task sendByte2;
  input [7:0] data;
  begin
      wait(bufferFull2==1'b0);
      dataIn2=data;
      nWeDataIn2=0;
      @(posedge clk);
      dataIn2=8'hxx;
      nWeDataIn2=1;
      @(posedge clk);
	end
endtask

task receiveByte;
  input [7:0] data;
  begin
      wait(txPending==1'b0);//wait start of last tx if any
      wait(txRun==1'b0);//wait end of previous transmission if any
      wait(bufferFull==1'b1);//wait reception of a byte
      @(posedge clk);
      nCsDataOut=0;
      @(posedge clk);
      nCsDataOut=1;
      if(data!=dataOut) begin
         tbErrorCnt=tbErrorCnt+1;
         $display("ERROR %d: uart1 received %x instead of %x",tbErrorCnt, dataOut, data);
      end
      @(posedge clk);
	end
endtask

task receiveByte2;
  input [7:0] data;
  begin
      wait(txPending2==1'b0);//wait start of last tx if any
      wait(txRun2==1'b0);//wait end of previous transmission if any
      wait(bufferFull2==1'b1);//wait reception of a byte
      @(posedge clk);
      nCsDataOut2=0;
      @(posedge clk);
      nCsDataOut2=1;
      if(data!=dataOut2) begin
         tbErrorCnt=tbErrorCnt+1;
         $display("ERROR %d: uart2 received %x instead of %x (time=%d)",tbErrorCnt, dataOut2, data,$time);
      end else
			$display("INFO: uart2 received %x (time=%d)",dataOut2,$time);
      @(posedge clk);
	end
endtask

integer tbSequenceDone;
integer tbSequenceDone2;
	initial begin
		// Initialize Inputs
		nReset = 0;
		clk = 0;
		dataIn = 0;
		clkPerCycle = 0;
		nWeDataIn = 1;
		nCsDataOut = 1;
		nCsStatusOut = 1;
		nWeDataIn2 = 1;
		nCsDataOut2 = 1;
		nCsStatusOut2 = 1;      
      tbErrorCnt=0;
      tbSequenceDone=0;
      tbSequenceDone2=0;
		// Wait 100 ns for global reset to finish
		#(CLK_PERIOD*10); 
      #(CLK_PERIOD/2);   
      nReset = 1;
      // Add stimulus here
      @(posedge clk);
      dataIn=8'h3B;
      nWeDataIn=0;
      @(posedge clk);
      dataIn=8'h00;
      nWeDataIn=1;
      @(posedge clk);
      if(bufferFull==1'b0) begin
         tbErrorCnt=tbErrorCnt+1;
         $display("ERROR %d: bufferFull==1'b0",tbErrorCnt);
      end
      @(posedge clk);
      @(posedge clk);
      if(bufferFull==1'b1) begin
         tbErrorCnt=tbErrorCnt+1;
         $display("ERROR %d: bufferFull==1'b1",tbErrorCnt);
      end
		//sendByte(8'h3B);
		
      sendByte(8'h97);
      sendByte(8'h12);
      sendByte(8'h34);
      receiveByte(8'h55);
      sendByte(8'h56);
      sendByte(8'h78);
      tbSequenceDone=1;
	end
   
   initial begin
      receiveByte2(8'h3B);
      receiveByte2(8'h97);
      receiveByte2(8'h12);
      receiveByte2(8'h34);
      sendByte2(8'h55);
      receiveByte2(8'h56);
      receiveByte2(8'h78);
      tbSequenceDone2=1;
   end
   initial begin
		wait(tbSequenceDone & tbSequenceDone2);
      if(tbErrorCnt)
         $display("INFO: Test FAILED (%d errors)", tbErrorCnt);
      else
         $display("INFO: Test PASSED");
      #10;
		$finish;
	end   
	initial begin
		// timeout
		#10000;  
      tbErrorCnt=tbErrorCnt+1;
      $display("ERROR: timeout expired");
      #10;
		$finish;
	end
	
	always
		#(CLK_PERIOD/2) clk =  ! clk;      
      
      
      
endmodule

