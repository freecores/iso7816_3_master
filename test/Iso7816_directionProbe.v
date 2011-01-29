`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Sebastien Riou
// 
// Create Date:    17:14:04 01/29/2011 
// Design Name: 
// Module Name:    Iso7816_directionProbe 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: model a probe which consist only of wires. Propagation delay over the sio line
// is used to determined the direction of the communication:
// If the terminal send a start bit, the termMon output will go low before cardMon and viceversa
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Iso7816_directionProbe(
    inout wire isoSioTerm,
    inout wire isoSioCard,
    output wire termMon,
    output wire cardMon
    );

TriWirePullup sioLine(.a(isoSioTerm), .b(isoSioCard));
assign termMon = isoSioTerm;
assign cardMon = isoSioCard;

endmodule
