/*
Author: Sebastien Riou (acapola)
Creation date: 17:16:40 01/09/2011 

$LastChangedDate$
$LastChangedBy$
$LastChangedRevision$
$HeadURL$				 

This file is under the BSD licence:
Copyright (c) 2011, Sebastien Riou

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 
The names of contributors may not be used to endorse or promote products derived from this software without specific prior written permission. 
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
`default_nettype none
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

//return when the stop bit of the last byte is starting
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
	i=16*257;
	getNextHexByte(bytesString, i, byteToSend, i);
	while(i!=-1) begin
		sendByte(byteToSend);
		getNextHexByte(bytesString, i, byteToSend, i);
	end
end
endtask

