
//wire txRun,txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull;
//assign {txRun, txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull} = COM_statusOut;


task privateTaskReceiveByteCore;
  begin
      wait(txPending==1'b0);//wait start of last tx if any
      wait(txRun==1'b0);//wait end of previous transmission if any
      wait(bufferFull==1'b1);//wait reception of a byte
      @(posedge COM_clk);
      nCsDataOut=0;
      @(posedge COM_clk);
      nCsDataOut=1;
	end
endtask
task receiveByte;
output reg [7:0] rxData;
	begin
		privateTaskReceiveByteCore;
		rxData=dataOut;
      @(posedge COM_clk);
	end
endtask
task receiveAndCheckByte;
  input [7:0] data;
  begin
      privateTaskReceiveByteCore;
      if(data!=dataOut) begin
         COM_errorCnt=COM_errorCnt+1;
         $display("ERROR %d: Received %x instead of %x",COM_errorCnt, dataOut, data);
      end
		@(posedge COM_clk);
	end
endtask

