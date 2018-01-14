//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW02_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW01_add.v"
//synopsys translate_on

`include "../04_MEM/RA1SH.v"

module CNN(
    clk,
    rst_n,
    in_valid_1,
    in_valid_2,
    in_data,
    out_valid,
    number_2,
    number_4,
    number_6,
);

// INPUT AND OUTPUT DECLARATION                         
input clk; 
input rst_n;
input in_valid_1;
input in_valid_2;
input [14:0]in_data;

output reg out_valid;
output reg number_2;
output reg number_4;
output reg number_6;
//---------------------------------------------------------------------
// PARAMETER DECLARATION
//---------------------------------------------------------------------
integer i, counter;           
parameter   S_IDLE       = 3'b000;
parameter   S_INPUT_1 = 3'b001;
parameter   S_INPUT_2 = 3'b010;
parameter   S_CONV     = 3'b011;
parameter   S_POOL      = 3'b100;
parameter   S_AFF_1     = 3'b101;
parameter   S_AFF_2     = 3'b110;
parameter   S_OUTPUT  = 3'b111;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION                             
//---------------------------------------------------------------------

wire [14:0]     Q;
reg   [14:0]  Q_cs; // output data
reg 	[6:0]   A;  // address
reg 	[14:0]  D;  //data input
reg 	WEN; // Write Enable Negative
reg 	[2:0]       c_state, n_state;
reg 	[14:0]  image_buf[7:0][7:0];
reg 	[3:0]   column, row;
reg				done;
reg	[1:0] 		number;
// Synopsys DesignWare Tool
wire				CO[2:0];
wire [15:0] 	RESULT_1, RESULT_2, RESULT_3, RESULT_4, RESULT_5, RESULT_6;
reg 	[7:0]		m_1, m_2, m_3, weight_1, weight_2, weight_3;
reg	[15:0] 	result_1, result_2, result_3, result_4, result_5, result_6,a_1, a_2, a_3, a_4, a_5, a_6;
reg				ci[2:0], co[2:0];

//---------------------------------------------------------------------
//   Synopsys DesignWare                      
//---------------------------------------------------------------------
DW02_mult #(8,8) M_1(.A(m_1), .B(weight_1),.TC(1'b1), .PRODUCT(RESULT_1));
DW02_mult #(8,8) M_2(.A(m_2),.B(weight_2),.TC(1'b1), .PRODUCT(RESULT_2));
DW02_mult #(8,8) M_3(.A(m_3),.B(weight_3),.TC(1'b1), .PRODUCT(RESULT_3));
DW01_add #(16) A_1(.A(a_1),.B(a_2),.CI(ci[0]),.SUM(RESULT_4),.CO(CO[0]));
DW01_add #(16) A_2(.A(a_3),.B(a_4),.CI(ci[1]),.SUM(RESULT_4),.CO(CO[1]));
DW01_add #(16) A_3(.A(a_5),.B(a_6),.CI(ci[2]),.SUM(RESULT_4),.CO(CO[2]));

//---------------------------------------------------------------------
//   MEMORY                           
//---------------------------------------------------------------------
RA1SH mem(
   .Q(Q),
   .CLK(clk),
   .CEN(1'b0),
   .WEN(WEN),
   .A(A),
   .D(D),
   .OEN(1'b0)
);
//---------------------------------------------------------------------
//   Finite State Machine                                         
//---------------------------------------------------------------------
//---------------   state 
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n)
        c_state <= S_IDLE;
    else
        c_state <= n_state;
end

always@(*) begin
    case(c_state)
        S_IDLE: begin
            if(in_valid_1)
                n_state = S_INPUT_1;
            else if(in_valid_2)
                n_state = S_INPUT_2;
            else
                n_state = c_state;
        end
        S_INPUT_1: begin
            if(!in_valid_1)
                n_state = S_IDLE;
            else
                n_state = c_state;
        end
        S_INPUT_2: begin
            if(!in_valid_2)
                n_state = S_OUTPUT;
            else
                n_state = c_state;
        end
        S_CONV: begin
            if(done)
                n_state = S_OUTPUT;
        end
		S_AFF_1: begin
			if(done)
				n_state = S_AFF_2;
		end
		S_AFF_2: begin
			if(done)
				n_state = S_OUTPUT;
		end
        S_OUTPUT: begin
            n_state = S_IDLE;
        end
        default:
            n_state = c_state;
    endcase
end

//---------------------------------------------------------------------
//   Design Description                                          
//---------------------------------------------------------------------

//---------------   Data Output from memory
always@(posedge clk or negedge rst_n) begin
    Q_cs <= Q;
end

//---------------   Counter
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n)
        counter <= 7'd0;
    else if(in_valid_1 || in_valid_2)
        counter <= counter + 1;
    else if(c_state == S_CONV)
		case(counter)
			0: counter <= counter + 1'b1;
			1: counter <= counter + 1'b1;
			2: counter <= counter + 1'b1;
			3: counter <= 0;
			default: counter <= counter;
		endcase
	else
        counter <= 7'd0;
end


//   Output part                                      
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0;
    else if(c_state == S_OUTPUT)
        out_valid <= 1'b1;
    else
        out_valid <= 1'b0;
end

always@(posedge clk or negedge rst_n)   begin
    if(!rst_n) begin
        number_2 <= 1'b0;
        number_4 <= 1'b0;
        number_6 <= 1'b0;
    end else if(c_state == S_OUTPUT)    begin
        case(2)
            0: number_2 <= 1'b1;
            1: number_4 <= 1'b1;
            2: number_6 <= 1'b1;
            default: begin
                number_2 <= 1'b0;
                number_4 <= 1'b0;
                number_6 <= 1'b0;
            end
        endcase
    end
    else begin
        number_2 <= 1'b0;
        number_4 <= 1'b0;
        number_6 <= 1'b0;
    end
end

//synopsys dc_script_begin
//set_implementation pparch M_1
//set_implementation pparch M_2
//set_implementation pparch M_3
//set_implementation apparch A_1
//set_implementation apparch A_2
//set_implementation apparch A_3
//synopsys dc_script_end

endmodule
