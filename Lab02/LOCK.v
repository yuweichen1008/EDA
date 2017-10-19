module LOCK(
	input	clk,
	input	rst_n,
	input	in_valid,
	input	clock,
	input	[1:0] mode,	
	input	[4:0] in,	
	input	[4:0] in_p1,	
	
	output	reg out_valid,
	output	reg [2:0]circle,
	output	reg [7:0]value
);

parameter 	NUM_VALUE = 'd8, 
					ST_IDLE = 'd0,
					ST_INPUT = 'd1,
					ST_EXE = 'd2,
					ST_SORT = 'd3,
					ST_OUTPUTARRAY = 'd4,
					ST_OUTPUT = 'd5;
			
reg [1:0]	cs,ns;
reg [4:0]	inputArray[23:0];
reg [4:0]  time_input, time_output, cypher, count;
reg [2:0]  pin[2:0];
reg [7:0]  outputArray[7:0];
reg [1:0]  isCypher, isTuck, isSorted;
reg [1:0]  _mode;
reg [2:0]  cnt_i, cnt_j, cnt_k;

// ST_INPUT
always@(negedge clk  or negedge rst_n) begin
	if(!(rst_n))
		time_input <= 5'd0;
	else if(ns==ST_INPUT)
		time_input <= time_input +'d1;
	else
		time_input <= time_input;
end

// ST_INPUT
always@(negedge clk or negedge rst_n)	begin
	if(!rst_n) begin
		for(cnt_i = 0; cnt_i <= 'd23; cnt_i = cnt_i +1)
			inputArray[cnt_i] <= 5'd0;
	end else if(ns==ST_INPUT)
		inputArray[time_input]<= in;
	else
		inputArray[0] <= inputArray[0];
end

// ST_INPUT
always@(negedge clk or negedge rst_n)	begin
	if(!rst_n)
		cypher<= 5'b0;
	else if(ns==ST_INPUT && count == 'd1)
		cypher <= in_p1;
	else
		cypher <= cypher;
end

// ST_INPUT
always@(posedge clk or posedge rst_n)	begin
	if(!rst_n)
		_mode <= 'd0;
	else if(ns==ST_INPUT && count == 'd1)
		_mode <= mode;
	else
		_mode <= _mode;
end

// ST_INPUT
always@(negedge clk or negedge rst_n)	begin
	if(!rst_n)
		count <= 'd1;
	else if((ns==ST_INPUT && count == 'd1) || (time_input == 'd22)) // change on Oct. 2
		count <= count+'d1;	// turn 1 to 2 and turn 2 to 3
	else
		count <= count;
end

// ST_EXE
always@(negedge clk or negedge rst_n)	begin
	if(!rst_n)
		isCypher <= 2'b0;
	else if(cs == ST_EXE) begin // which better?  get ns == ST_EXE
		if(_mode == 2'b00) begin
			//only find the pin value
			for(cnt_i =0; cnt_i <NUM_VALUE; cnt_i = cnt_i +1) begin
				if(inputArray[cnt_i] == cypher) begin
					for(cnt_j=0; cnt_j < NUM_VALUE; cnt_j = cnt_j +1) begin
						if(inputArray[cnt_j + 'd8] == cypher) begin
							for(cnt_k =0; cnt_k < NUM_VALUE; cnt_k = cnt_k + 1) begin
								if(inputArray[cnt_k + 'd16] == cypher) begin
									pin[0] <= cnt_i;
									pin[1] <= cnt_j;
									pin[2] <= cnt_k;
									cnt_i <= NUM_VALUE;
									cnt_j <= NUM_VALUE;
									cnt_k <= NUM_VALUE;
									isCypher <= 'b1;
								end
							end
						end
					end
				end
			end
		end else if(_mode == 2'b01) begin
			// find two value
			for(cnt_i =0; cnt_i <NUM_VALUE; cnt_i = cnt_i +1) begin
				if(inputArray[cnt_i] == cypher) begin
					for(cnt_j=0; cnt_j < NUM_VALUE; cnt_j = cnt_j +1) begin
						if(inputArray[cnt_j + 'd8] == cypher && inputArray[(cnt_j+ 'd4)%8 + 'd8] == inputArray[(cnt_i + 'd4)%8]) begin
							for(cnt_k =0; cnt_k < NUM_VALUE; cnt_k = cnt_k + 1) begin
								if(inputArray[cnt_k + 'd16] == cypher && inputArray[(cnt_k + 'd4)%8 + 'd16] == inputArray[(cnt_i + 'd4)%8] ) begin
									pin[0] <= cnt_i;
									pin[1] <= cnt_j;
									pin[2] <= cnt_k;
									cnt_i <= NUM_VALUE;
									cnt_j <= NUM_VALUE;
									cnt_k <= NUM_VALUE;
									isCypher <= 'b1;
								end
							end
						end
					end
				end
			end
		end else begin
			// find quadra value
			for(cnt_i =0; cnt_i <NUM_VALUE; cnt_i = cnt_i +1) begin
				if(inputArray[cnt_i] == cypher) begin
					for(cnt_j=0; cnt_j < NUM_VALUE; cnt_j = cnt_j +1) begin
						if(inputArray[cnt_j + 'd8] == cypher && inputArray[(cnt_j+ 'd4)%8 + 'd8] == inputArray[(cnt_i + 'd4)%8] && (inputArray[(cnt_j+ 'd2)%8 + 'd8] == inputArray[(cnt_i + 'd2)%8]  && inputArray[(cnt_j+ 'd6)%8 + 'd8] == inputArray[(cnt_i + 'd6)%8])) begin
							for(cnt_k =0; cnt_k < NUM_VALUE; cnt_k = cnt_k + 1) begin
								if(inputArray[cnt_k + 'd16] == cypher && inputArray[(cnt_k + 'd4)%8 + 'd16] == inputArray[(cnt_i + 'd4)%8] &&(inputArray[(cnt_k + 'd2)%8 + 'd16] == inputArray[(cnt_i + 'd2)%8] && inputArray[(cnt_k + 'd6)%8 + 'd16] == inputArray[(cnt_i + 'd6)%8]) ) begin
									pin[0] <= cnt_i;
									pin[1] <= cnt_j;
									pin[2] <= cnt_k;
									cnt_i <= NUM_VALUE;
									cnt_j <= NUM_VALUE;
									cnt_k <= NUM_VALUE;
									isCypher <= 'b1;
								end
							end
						end
					end
				end
			end		
		end
	end else
		isCypher <= isCypher;
end

// ST_OUTPUTARRAY
always@(negedge clk or negedge rst_n) begin
	if(!rst_n) begin
		isTuck <= 'b0;
		for(cnt_j =0; cnt_j < NUM_VALUE; cnt_j = cnt_j +1)
			outputArray[cnt_j] <= 5'd0;
	end else if(cs == ST_OUTPUTARRAY) begin // which better? === get ns == ST_OUTPUTARRAY
		for(cnt_k =0; cnt_k < NUM_VALUE; cnt_k = cnt_k +1) begin
			outputArray[cnt_k] <= inputArray[(pin[0] + cnt_k)%8] + (inputArray[(pin[1] + cnt_k)%8 + 'd8] + inputArray[(pin[2] + cnt_k)%8 + 'd16]);
		end
		isTuck <= 'b1;
	end else begin
		for(cnt_i =0; cnt_i < NUM_VALUE; cnt_i = cnt_i +1)
			outputArray[cnt_i] <= outputArray[cnt_i];
		isTuck <= isTuck;
	end
end

// ST_SORT
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		isSorted <= 0;
	else if(cs == ST_SORT) begin
		//sorting outputArray here
		for(cnt_i = 7; cnt_i > 0; cnt_i = cnt_i -1) begin
			for(cnt_j = 1; cnt_j <= cnt_i;cnt_j = cnt_j+1) begin
				if(outputArray[cnt_j] > outputArray[cnt_j +1]) begin
					outputArray[cnt_j] <= outputArray[cnt_j+1]; //swap
					outputArray[cnt_j+1] <= outputArray[cnt_j]; //swap
				end
			end
		end
		isSorted <= 'b1;
	end else
		isSorted <= isSorted;
end

// ST_OUTPUT
always@(negedge clk or negedge rst_n)	begin
	if(!rst_n) begin
		value <= 8'd0;
	end else if(cs==ST_OUTPUT) begin
		value <= outputArray[time_output +'d1];
	end else
		value <= 8'd0;
end

// ST_OUTPUT
always@(negedge clk or negedge rst_n) begin
	if(!rst_n)
		circle <= 3'd0;
	else if(cs==ST_OUTPUT && time_output < 3) begin
		circle <= pin[time_output];
	end else
		circle <= 3'd0;
end

// ST_OUTPUT
always@(negedge clk or negedge rst_n)	begin
	if(!rst_n)
		out_valid <= 'b0;
	else if(cs==ST_OUTPUT)
		out_valid <= 'b1;
	else
		out_valid <= 'b0;
end

// ST_OUTPUT
always@(negedge clk or negedge rst_n) begin
	if(!rst_n)
		time_output <= 5'd0;
	else if(cs==ST_OUTPUT)
		time_output <= time_output + 'd1;
	else
		time_output <= time_output;
end

always@(negedge	clk or negedge rst_n)	begin
	if(!rst_n)
		cs <= ST_IDLE;
	else
		cs <= ns;
end

always@(*)	begin
	case(cs)
		ST_IDLE: begin
			if(in_valid)
				ns	= ST_INPUT;
			else
				ns	= ST_IDLE;
		end
		
		ST_INPUT: begin
			if(count=='d3)
				ns	= ST_EXE;
			else
				ns	= ST_INPUT;
		end
		
		ST_EXE: begin
			if(isCypher)
				ns	= ST_OUTPUTARRAY;
			else
				ns	= ST_EXE;
		end
		
		ST_OUTPUTARRAY: begin
			if(isTuck)
				ns	= ST_SORT;
			else
				ns	= ST_OUTPUTARRAY;
		end

		ST_SORT: begin
			if(isSorted)
				ns	= ST_OUTPUT;
			else
				ns	= ST_SORT;
		end
		
		ST_OUTPUT: begin
			if(time_output=='d6) // change from 'd7 to 'd6 here Oct 2
				ns	=	ST_IDLE;
			else
				ns = ST_OUTPUT;
		end
		
		default:
			out_valid = 'd0;
	endcase
end

endmodule
