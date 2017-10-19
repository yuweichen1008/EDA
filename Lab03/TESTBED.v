//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2017 ICLAB Fall Course
//   Lab03	    : Magical Dartboard
//   Author         : Yu-Wei Chen
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0		Oct. 13, 2017
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`include "PATTERN.v"


module TESTBED();

wire clk, rst_n, in_valid_1, in_valid_2, rotate_flag;
wire[2:0] in_score, in_rotation;
wire[3:0] in_dart;

wire out_valid;
wire[6:0] out_sum;

initial begin
  `ifdef RTL
    $fsdbDumpfile("MD.fsdb");
//	  $fsdbDumpvars();
	  $fsdbDumpvars(0,"+mda");
  `elsif GATE
    $fsdbDumpfile("MD_SYN.fsdb");
	  $sdf_annotate("MD_SYN.sdf",I_MD);      
	  $fsdbDumpvars(0,"+mda");
//	  $fsdbDumpvars();
  `endif
end

MD I_MD(
//  input signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid_1(in_valid_1),
	.in_valid_2(in_valid_2),
	.in_score(in_score),
	.in_dart(in_dart),
	.in_rotation(in_rotation),
	.rotate_flag(rotate_flag),
//  output signals
	.out_valid(out_valid),
	.out_sum(out_sum)
);

PATTERN I_PATTERN(
//  input signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid_1(in_valid_1),
	.in_valid_2(in_valid_2),
	.in_score(in_score),
	.in_dart(in_dart),
	.in_rotation(in_rotation),
	.rotate_flag(rotate_flag),
//  output signals
	.out_valid(out_valid),
	.out_sum(out_sum)
);

endmodule
