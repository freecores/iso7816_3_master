
//wire txRun,txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull;
//assign {txRun, txPending, rxRun, rxStartBit, isTx, overrunErrorFlag, frameErrorFlag, bufferFull} = COM_statusOut;


task sendByte;
  input [7:0] data;
  begin
      wait(bufferFull==1'b0);
      dataIn=data;
      nWeDataIn=0;
      @(posedge COM_clk);
      dataIn=8'hxx;
      nWeDataIn=1;
      @(posedge COM_clk);
	end
endtask
task sendWord;
  input [15:0] data;
  begin
      sendByte(data[15:8]);
		sendByte(data[7:0]);
	end
endtask
task waitEndOfTx;
  begin
      @(posedge COM_clk)
		wait(txPending==0);
		wait(isTx==0);
	end
endtask
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

