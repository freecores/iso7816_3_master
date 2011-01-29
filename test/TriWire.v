`timescale 1ns / 1ps
`default_nettype none
/*****************************************************************
* module triwire: bidirectional wire bus model with delay
*
* This module models the two ends of a bidirectional bus with
* transport (not inertial) delays in each direction. The
* bus has a width of WIDTH and the delays are as follows:
* a->b has a delay of Ta_b (in `timescale units)
* b->a has a delay of Tb_a (in `timescale units)
* The two delays will typically be the same. This model
* overcomes the problem of "echoes" at the receiving end of the
* wire by ensuring that data is only transmitted down the wire
* when the received data is Z. That means that there may be
* collisions resulting in X at the local end, but X's are not
* transmitted to the other end, which is a limitation of the
* model. Another compromise made in the interest of simulation
* speed is that the bus is not treated as individual wires, so
* a Z on any single wire may prevent data from being transmitted
* on other wires.
*
* The delays are reals so that they may vary throughout the
* course of a simulation. To change the delay, use the Verilog
* force command. Here is an example instantiation template:
*
real Ta_b=1, Tb_a=1;
always(Ta_b) force triwire.Ta_b = Ta_b;
always(Tb_a) force triwire.Tb_a = Tb_a;
triwire #(.WIDTH(WIDTH)) triwire (.a(a),.b(b));

* Kevin Neilson, Xilinx, 2007
*****************************************************************/
module triwire #(parameter WIDTH=1) (inout wire [WIDTH-1:0] a, b);
	real Ta_b=1, Tb_a=1;
	reg [WIDTH-1:0] a_dly = 'bz, b_dly = 'bz;
	always @(a) a_dly <= #(Ta_b) b_dly==={WIDTH{1'bz}} ? a : 'bz;
	always @(b) b_dly <= #(Tb_a) a_dly==={WIDTH{1'bz}} ? b : 'bz;
	assign b = a_dly, a = b_dly;
endmodule 

//delay fixed at build time here
//Sebastien Riou
module TriWirePullup #(parameter UNIDELAY=1) 
							(inout wire a, b);
	reg a_dly = 'bz, b_dly = 'bz;
	always @(a) begin
		if(b_dly!==1'b0) begin
			if(a===1'b0)
				a_dly <= #(UNIDELAY) 1'b0;
			else
				a_dly <= #(UNIDELAY) 1'bz;
		end
	end
	always @(b) begin
		if(a_dly!==1'b0) begin
			if(b===1'b0)
				b_dly <= #(UNIDELAY) 1'b0;
			else
				b_dly <= #(UNIDELAY) 1'bz;
		end
	end
	assign b = a_dly, a = b_dly;
	pullup(a);
	pullup(b);
endmodule
/*module TriWireFixed #(parameter WIDTH=1) 
							(inout wire [WIDTH-1:0] a, b);
	tran (a,b);//not supported by xilinx ISE, even just in simulation :-S
	specify
		(a*>b)=(1,1);
		(b*>a)=(1,1);
	endspecify
endmodule */
