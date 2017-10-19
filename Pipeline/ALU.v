module ALU(
  // Input signals
  clk,
  rst_n,
  in_valid,
  mode,
  in_number1,
  in_number2,
  in_number3,
  in_number4,
  in_number5,
  // Output signals
  out_valid,
  out_number
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input 				        clk, rst_n, in_valid;
input		        [1:0]   mode;
input signed		[4:0]   in_number1, in_number2, in_number3, in_number4, in_number5;
output reg			        out_valid;
output reg	signed  [9:0]	out_number;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION                             
//---------------------------------------------------------------------
reg [1:0] cs, ns;

parameter ST_IDLE = 2'b00;
parameter ST_INPUT = 2'b01;
parameter ST_SORT = 2'b11;
parameter ST_OUTPUT = 2'b10;
//---------------------------------------------------------------------
//   Finite-State Machine                                          
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cs = ST_IDLE;
	else
		cs = ns;
end


always@(posedge clk or negedge rst_n) begin
	case(cs)
		ST_IDLE:
		begin
			if(in_valid)
				ns = ST_INPUT;
			else
				ns = ST_IDLE;
		end
		ST_INPUT:
		begin
			if(!in_valid)
				ns = ST_SORT;
			else
				ns = ST_INPUT;
		end
		ST_SORT:
		begin
			if(count)
				ns = ST_OUTPUT;
			else
				ns = ST_SORT;
		end
		ST_OUTPUT:
			if(count)
				ns = ST_IDLE;
			else
				ns = ST_OUTPUT;
	endcase
end


//---------------------------------------------------------------------
//   Design Description                                          
//---------------------------------------------------------------------


endmodule
