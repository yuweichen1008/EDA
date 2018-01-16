//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2017 ICLAB Fall Course
//   MID			
//   Author     : Yu-Wei, Chen (cosas.me01@g2.nctu.edu.tw)
//
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//   Release version : 	v1.1		5th Jan, 2018
//								v1.3		8th Jam, 2018
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL
	`timescale 1ns/10ps
	`include "CNN.v"  
	`define CYCLE_TIME 10.0  
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`include "CNN_SYN.v"
	`define CYCLE_TIME 10.0
`endif

`define NULL 0

module PATTERN(
    // Output signals
    clk,
    rst_n,
    in_valid_1,
    in_valid_2,
    in_data,
    // Input signals
    out_valid,
    number_2,
    number_4,
    number_6,
);
//================
// INPUT AND OUTPUT DECLARATION
//================                   
output reg clk; 
output reg rst_n;
output reg in_valid_1;
output reg in_valid_2;
output reg [14:0]in_data;

input out_valid;
input number_2;
input number_4;
input number_6;
//================
// REG AND PARAMETERS DECLARATION
//================
real CYCLE = `CYCLE_TIME;
reg   signed [14:0] 	weight_data[125:0], weight_buf;
reg	signed	[14:0]	image[9:0][63:0];
reg	signed [14:0]	scan_file, scan_buf;
integer count, k, index, i, total_latency, lat;
integer	image_file, model_file, cnt;
reg	[2:0]					answer[9:0], answer_buf;
reg	[3:0]		correct, wrong;
//================
// CLOCK
//================
always #(CYCLE /2.0) clk = ~clk;
initial clk = 0;
//================
// INITIAL BLOCK
//================
initial begin
	rst_n = 1;
	initial_task;
	force clk = 0;
	read_weight_task;
	read_image_task;
	reset_task;
	input_task;
	repeat(2)@(posedge clk);
	for(index = 0; index < 10; index = index +1) begin
		input_image_task;
		wait_OUTVALID_task;
		check_task;
		$display("Finish image %d", index);
	end
	success_task;
	$display("Correct is %d out of %d", correct, (correct + wrong));
	$display("Your win rate is %.1f", correct/(correct + wrong));
	repeat(10)@(posedge clk);
	$finish;
end
//================
// TASK FUNCTION BLOCK
//================
task initial_task;
begin
	in_valid_1 = 0;
	in_valid_2 = 0;
	in_data = 15'b0;
	for(i = 0; i < 126; i = i + 1)
		weight_data[i] = 15'b0;
	for(i = 0; i < 10; i = i + 1) begin
		for(k = 0; k < 64; k = k +1) begin
			image[i][k] = 0;
		end
	end
	correct = 0; wrong = 0;
end endtask
task read_weight_task;
begin
	model_file= $fopen("model_weights.txt", "r");
	if( model_file == `NULL) begin
		$display("model_weights handle was NULL");
		$finish;
	end
	i = 0;
	while(!$feof(model_file)) begin
		cnt = $fscanf(model_file, "%d\n", weight_buf);
		weight_data[i] = weight_buf;
		i = i+1;
	end
    //for (k=0; k<126; k=k+1) $display("%d",weight_data[k]);
end endtask

task read_image_task;
begin
	image_file = $fopen("input_patterns.txt", "r");
	if( image_file == `NULL) begin
		$display("image_file handle was NULL");
		$finish;
	end
	for(index = 0; index < 10; index = index + 1) begin
		for(i = 0 ; i < 64; i = i + 1) begin
			cnt = $fscanf(image_file, "%d\n", scan_buf);
			image[index][i] = scan_buf;
		end
		cnt = $fscanf(image_file, "%d\n", answer_buf);
		answer[index] = answer_buf;
		//for (k=0; k<64; k=k+1) $display("%d",weight_data[index][k]);
	end
end endtask

task input_task;
begin
	in_valid_1 = 1;
	for(k = 0; k < 126; k = k + 1) begin
		in_data = weight_data[k];
		@(posedge clk);
	end
	in_data = 0;
	in_valid_1 = 0;
end endtask

task reset_task;
begin
	#(0.5) rst_n = 0;
	#(0.5) rst_n = 1;
	if(out_valid != 0 || number_2 || number_4 || number_6) begin
		$display("You should pull down the out_valid or image_out!");
		fail_task;
		repeat(10)@(posedge clk);
		$finish;
	end
	#(3.0);
	release clk;
	@(posedge clk);
end endtask


task input_image_task;
begin
	in_valid_2 = 1;
	for(k = 0; k < 64; k = k + 1) begin
		in_data = image[index][k];
		@(posedge clk);
	end
	in_data = 0;
	in_valid_2 = 0;
end endtask

task wait_OUTVALID_task;
begin
	lat = -1;
	while(!out_valid) begin
		lat = lat + 1;
		if(lat > 5000) begin
			$display("Cycle over 5000");
			fail_task;
		end
		repeat(2)@(posedge clk);
	end
	total_latency = total_latency + lat;
end endtask

task check_task;
begin
	answer_buf = answer[index];
	case(answer_buf)
		0: begin
			if(!number_2) 
				wrong = wrong +1;
			else 
				correct = correct + 1;
		end
		1: begin
			if(!number_4) 
				wrong = wrong +1;
			else 
				correct = correct + 1;
		end
		2: begin
			if(!number_6) 
				wrong = wrong +1;
			else 
				correct = correct + 1;
		end
		default: begin
			correct = correct;
			wrong = wrong;
		end
	endcase
	$display("Your answer is %d%d%d and correct answer is %d", number_2, number_4, number_6,answer_buf);	
end endtask
//================
// Success and Failure
//================
task success_task;
begin
	$display("-------------------------------");
	$display("-----------SUCCESS---------");
	$display("-------------------------------");
	$display ("----Your execution cycles = %5d cycles----", total_latency);
	$display ("----Your clock period = %.1f ns----", CYCLE);
	$display ("----Your total latency = %.1f ns----", total_latency*CYCLE);

end endtask

task fail_task;
begin
	$display("------------------------------");
	$display("------------FAIL-------------");
	$display("------------------------------");
	$display ("----Your execution cycles = %5d cycles----", total_latency);
	$display ("----Your clock period = %.1f ns----", CYCLE);
	$display ("----Your total latency = %.1f ns----", total_latency*CYCLE);
	repeat(2)@(posedge clk);
	$finish;
end endtask

endmodule
