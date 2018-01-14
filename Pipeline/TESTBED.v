//############################################################################
//   Author         : Yu-Wei Chen
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : TESTBED.v
//   Module Name : TESTBED
//   Release version : v1.0		Oct. 19, 2017
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################


`include "PATTERN.v"

module TESTBED();

wire clk, rst_n, in_valid;
wire [1:0] mode;
wire [4:0] in_number1, in_number2, in_number3, in_number4, in_number5;
wire out_valid;
wire [9:0] out_number;

initial begin
  `ifdef RTL
    $fsdbDumpfile("ALU.fsdb");
//	  $fsdbDumpvars();
	  $fsdbDumpvars(0,"+mda");
  `elsif GATE
    $fsdbDumpfile("ALU_SYN.fsdb");
	  $sdf_annotate("ALU_SYN.sdf",I_ALU);      
	  $fsdbDumpvars(0,"+mda");
//	  $fsdbDumpvars();
  `endif
end


ALU U_ALU
(
// Output signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.mode(mode),
	.in_number1(in_number1),
	.in_number2(in_number2),
	.in_number3(in_number3),
	.in_number4(in_number4),
	.in_number5(in_number5),
// Input signals
	.out_valid(out_valid),
	.out_number(out_number)
);


PATTERN U_PATTERN
(
// Output signals
	.clk(clk),
	.rst_n(rst_n),
	.in_valid(in_valid),
	.mode(mode),
	.in_number1(in_number1),
	.in_number2(in_number2),
	.in_number3(in_number3),
	.in_number4(in_number4),
	.in_number5(in_number5),
// Input signals
	.out_valid(out_valid),
	.out_number(out_number)
);

endmodule