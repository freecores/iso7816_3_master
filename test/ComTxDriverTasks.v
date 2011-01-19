
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
