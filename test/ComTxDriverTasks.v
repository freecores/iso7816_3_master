`include "HexStringConversion.v"

//low level tasks
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


//Higher level tasks
task sendHexBytes;
	input [16*257:0] bytesString;
	integer i;
	reg [15:0] byteInHex;
	reg [7:0] byteToSend;
begin
	for(i=16*256;i>=0;i=i-16) begin
		byteInHex=bytesString[i+:16];
		if(16'h0!=byteInHex) begin
			byteToSend=hexString2Byte(byteInHex);
			sendByte(byteToSend);
		end
	end
end
endtask

