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
 
function [7:0] hexString2Byte;
	input [15:0] byteInHexString;
	integer i;
	reg [7:0] hexDigit;
	reg [4:0] nibble;
	begin
		//hexString2Byte=0;
		for(i=0;i<2;i=i+1) begin
			nibble=5'b10000;//invalid
			hexDigit=byteInHexString[i*8+:8];
			if(("0"<=hexDigit)&&("9">=hexDigit))
				nibble=hexDigit-"0";
			if(("a"<=hexDigit)&&("f">=hexDigit))
				nibble=10+hexDigit-"a";
			if(("A"<=hexDigit)&&("F">=hexDigit))
				nibble=10+hexDigit-"A";
			if(nibble>15) begin
				$display("Invalid input for hex conversion: '%s', hexDigit='%s' (%x), nibble=%d",byteInHexString,hexDigit,hexDigit,nibble);
				$finish;
			end
			hexString2Byte[i*4+:4]=nibble;
		end
	end
endfunction
 

