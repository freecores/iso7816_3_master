 
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
 

