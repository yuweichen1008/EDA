//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2017 ICLAB Fall Course
//   Lab03    : Magical Dartboard
//   Author         : Yu-Wei Chen
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : MD.v
//   Module Name : MD
//   Release version : v1.0 Oct. 13, 2017
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
module MD(

// input signals
	clk,
	rst_n,
	in_valid_1,
	in_valid_2,
	in_score,
	in_dart,
	in_rotation,
	rotate_flag,
// output signals
    out_valid,
	out_sum
);

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input					clk,rst_n, in_valid_1,	in_valid_2,rotate_flag;
input					[2:0]	in_score,in_rotation;
input					[3:0]in_dart;

output	reg			out_valid;
output reg 			[6:0]out_sum;

//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------

parameter
				ST_IDLE = 3'b000,
				ST_INPUT = 3'b001,
				ST_WAIT = 3'b010,
				ST_DART = 3'b011,
				ST_EXE = 3'b100,
				ST_OUTPUT = 3'b101;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION                             
//---------------------------------------------------------------------

reg		[2:0]cs, ns;
reg		[2:0]score[15:0];
reg		[3:0]position[1:0];	// inner and outter position( position 0 and 8)
reg		[6:0]sum;
reg		done;
reg		[2:0] step;
reg		ccw;
reg       [3:0]dart;
reg       in_valid_2_buff;
integer counter, temp;
//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------

// score reg
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		score[0] <= 3'b0;
		score[1] <= 3'b0;
		score[2] <= 3'b0;
		score[3] <= 3'b0;
		score[4] <= 3'b0;
		score[5] <= 3'b0;
		score[6] <= 3'b0;
		score[7] <= 3'b0;
		score[8] <= 3'b0;
		score[9] <= 3'b0;
		score[10] <= 3'b0;
		score[11] <= 3'b0;
		score[12] <= 3'b0;
		score[13] <= 3'b0;
		score[14] <= 3'b0;
		score[15] <= 3'b0;
	end else if(ns == ST_INPUT) begin
		// shift register
		score[15] <= in_score;
		score[14] <= score[15];
		score[13] <= score[14];
		score[12] <= score[13];
		score[11] <= score[12];
		score[10] <= score[11];
		score[9] <= score[10];
		score[8] <= score[9];
		score[7] <= score[8];
		score[6] <= score[7];
		score[5] <= score[6];
		score[4] <= score[5];
		score[3] <= score[4];
		score[2] <= score[3];
		score[1] <= score[2];
		score[0] <= score[1];
		$display ("-     %2d score is --   %4d                               -", counter, in_score);
	end else begin
		score[0] <= score[0];
		score[1] <= score[1];
		score[2] <= score[2];
		score[3] <= score[3];
		score[4] <= score[4];
		score[5] <= score[5];
		score[6] <= score[6];
		score[7] <= score[7];
		score[8] <= score[8];
		score[9] <= score[9];
		score[10] <= score[10];
		score[11] <= score[11];
		score[12] <= score[12];
		score[13] <= score[13];
		score[14] <= score[14];
		score[15] <= score[15];
	end
end

//counter
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		counter <= 0;
	else if(ns == ST_INPUT)
		counter <= counter +1;	// count until 15
	else
		counter <= counter;
end


// position reg
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		position[0] <= 4'b0000;
		position[1] <= 4'b1000;
		sum <= 7'd0;
	end else if((cs == ST_DART && in_valid_2_buff) || cs == ST_EXE) begin
		$display("inner : %4d , outer : %4d", position[0], position[1]);
		$display("dart  : %4d , step : %4d, ccw : %d", dart, step, ccw);
		$display("Score : %5d", sum);
		// $display("dart  : %4d , in_rotation : %4d, rotate_flag : %d", in_dart, in_rotation, rotate_flag);
		// in_valid_2_buff is one cycle delay from in_valid_2 !!!!!!!!
		if((dart >> 3) & 1'b1) begin
			if((position[1]  >> 3) & 1'b1) begin
				sum <= sum + score[(position[1] + dart) ^ 4'b1000];
			end else begin
				sum <= sum + score[((position[1] + dart) & 3'b111)];
			end
			// $display("Shoot : %5d", score[((position[1] + dart) ^ 4'b1000)]);
		end else begin
			if((position[0]  >> 3) & 1'b1) begin
				sum <= sum + score[((position[0] + dart) ^ 4'b1000)];
			end else begin
				sum <= sum + score[((position[0] + dart) & 3'b111)];
			end
			// $display("Shoot : %5d",score[((position[0] + dart) & 3'b111)]);
		end
		
		if(step == 0) begin
			// swap
			position[0] <= position[1];
			position[1] <= position[0];
		end else if(ccw) begin
			// ccw
			if((position[0]  >> 3) & 1'b1) begin
				position[0] <= (position[0] + step) ^ 4'b1000;
			end else begin
				position[0] <= (position[0] + step) & 3'b111;
			end
		end else begin
			// cw
			if((position[0]  >> 3) & 1'b1) begin
				position[0] <= (position[0] - step) ^ 4'b1000;
			end else begin
				position[0] <= (position[0] - step) & 3'b111;
			end
		end
	end else begin
		sum <= sum;
		position[0] <= position[0];
		position[1] <= position[1];
	end
end

// in_valid_2_buff reg
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		in_valid_2_buff <= 1'b0;
	else if(in_valid_2)
		in_valid_2_buff <= 1'b1;
	else
		in_valid_2_buff <= 1'b0;
end

// ccw reg rotate_flag
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		ccw <= 1'b0;
	else if(ns == ST_DART && in_valid_2)
		ccw <= rotate_flag;
	else
		ccw <= ccw;
end

// step reg in_rotation
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		step <= 3'd0;
	else if(ns == ST_DART && in_valid_2)
		step <= in_rotation;
	else
		step <= step;
end

// dart reg in_dart
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		dart <= 4'd0;
	else if(ns == ST_DART && in_valid_2) begin
		dart <= in_dart;
	end else
		dart <= dart;
end

// done
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		done <= 'b0;
	else if(cs == ST_EXE)
		done <= 'b1;
	else
		done <= done;
end

// out_valid
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_valid <= 'b0;
	else if(cs == ST_OUTPUT)
		out_valid <= 'b1;
	else
		out_valid <= 'b0;
end

// out_sum
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_sum <= 7'd0;
	else if(cs == ST_OUTPUT)
		out_sum <= sum;
	else
		out_sum <= 7'd0;
end

// current state and next state
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cs = ST_IDLE;
	else
		cs = ns;
end

// combinational circuit
always@(*)
begin
	case(cs)
		ST_IDLE: // 0
		begin
			if(in_valid_1) begin
				ns	= ST_INPUT;
			end else
				ns	= ST_IDLE;	
		end
		
		ST_INPUT: // 1
		begin
			if(counter == 'd16) begin
				ns = ST_WAIT;
			end else
				ns = ST_INPUT;
		end
		
		ST_WAIT: // 2
		begin
			if(in_valid_2) begin
				ns = ST_DART;
			end else
				ns = ST_WAIT;
		end
		
		ST_DART: // 3
		begin
			if(!in_valid_2_buff) begin
				ns = ST_EXE;
			end else
				ns = ST_DART;
		end
		
		ST_EXE: // 4
		begin
			if(done) begin
				ns = ST_OUTPUT;
			end else
				ns = ST_EXE;
		end
		
		ST_OUTPUT:
		begin
			if(out_valid)
				ns = ST_IDLE;
			else
				ns = ST_OUTPUT;
		end
	endcase

end

endmodule