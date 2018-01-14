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


`ifdef RTL
	`timescale 1ns/10ps
	`include "ALU.v"  
	`define CYCLE_TIME 3.0  
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`include "ALU_SYN.v"
	`define CYCLE_TIME 3.0
`endif


module PATTERN(
	// Output signals
  clk,
  rst_n,
  in_valid,
  mode,
  in_number1,
  in_number2,
  in_number3,
  in_number4,
  in_number5,
  // Input signals
  out_valid,
  out_number
);

output reg clk, rst_n, in_valid;
output reg [1:0] mode;
output reg [4:0] in_number1, in_number2, in_number3, in_number4, in_number5;
input out_valid;
input [9:0] out_number;
//================================================================
// parameters & integer
//================================================================
real CYCLE = `CYCLE_TIME;
integer PATNUM = 298;
integer seed = 13;
integer patcount, total_latency;
//================================================================
// wire & registers 
//================================================================

//================================================================
// clock
//================================================================
always #(CYCLE/2.0) clk = ~clk;
initial clk = 0;
//================================================================
// initial
//================================================================
initial begin
	rst_n = 1;
	in_valid = 0;
	mode = 2'bx;
	in_number1 = 5'bx;
	in_number2 = 5'bx;
	in_number3 = 5'bx;
	in_number4 = 5'bx;
	in_number5 = 5'bx;
	force clk = 0;
	
	total_latency = 0;
	reset_signal_task; // reset signals
	
	patcount=0;
	for(patcount; patcount <= PATNUM; patcount = patcount + 1)
	begin
		input_task;
	end
	
end
//================================================================
// task
//================================================================

task reset_signal_task;
begin
	rst_n = 0; in_valid = 0;
	#(6);
	rst_n = 1;
	release clk;
end endtask



task input_task;
begin


end endtask
endmodule


