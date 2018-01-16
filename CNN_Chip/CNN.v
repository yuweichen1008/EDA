//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW02_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW01_add.v"
`include "../04_MEM/RA1SH.v"
//synopsys translate_on

module CNN(
    clk,
    rst_n,
    in_valid_1,
    in_valid_2,
    in_data,
    out_valid,
    number_2,
    number_4,
    number_6
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
integer i, j, k, counter;           
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

wire [3:0]  Q;
reg   [3:0]  Q_cs; 	// output data
reg 	[6:0]   	A;  		// address
reg 	[3:0]  D;  			//data input
reg 				WEN; // Write Enable Negative
reg 	[2:0]    c_state, n_state;
reg 	[7:0]  image_buf[7:0][7:0];
reg 	[3:0]   	column, row;
reg	[3:0] 	weight_buf[11:0];
reg				done, flag_FC;
reg	[1:0] 	number;
// Synopsys DesignWare Tool
wire				CO[2:0];
wire [11:0] 	RESULT_1, RESULT_2, RESULT_3;
wire	[12:0]	 RESULT_4, RESULT_5;
wire	[13:0]	RESULT_6;
reg	[7:0]	m_1, m_2, m_3;
reg 	[3:0]	weight_1, weight_2, weight_3;
reg	[11:0] 	result_1, result_2, result_3;
reg	[12:0]	result_4, result_5, a_1, a_2, a_3, a_4;
reg	[13:0]	result_6, a_5, a_6;
reg				co[2:0];
reg 	[1:0]	inner_cont;
reg 	[9:0]  	convolution_buf[8:0];
reg 	[7:0]   conimg_buf[5:0][5:0][2:0];
// pooling layer
reg	[7:0]	pooling_buf[26:0];
reg	[7:0]	stage_1_buf[5:0];
reg	[7:0]	stage_2_buf[2:0];
reg	[3:0]	pool_cnt;
// fully connected layer
reg	[7:0] 	fc_buf[2:0], outcome[2:0];
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
//---------------   Data Output from memory
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
		Q_cs <= 0;
	else
		Q_cs <= Q;
end

//--------------- Weight Input for memory
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        A <= 0;
        D <= 0;
        WEN <= 1;
    end else if(in_valid_1) begin
        A <= counter;
        D <= in_data >> 11;
        WEN <= 0;
    end else case(c_state)
		S_INPUT_2: begin
			D <= 0;
			WEN <= 1;
			case(counter)
				3,4,5,6,7,8,16,17,18,24,25,26: begin
					A <= counter+3;
					WEN <= 1;
				end
				default: begin
					A <= 0;
					WEN <= 1;
				end
			endcase
		end
		S_AFF_2: begin
			D <= 0;
			WEN <= 1;
			case(counter)
				 0, 1, 2, 3, 4, 5, 6, 7, 8: A <= counter + 30;
				 //9:  A <= 113;
				 14, 15, 16, 17, 18, 19, 20, 21, 22: A <= counter + 25;
				 //23:  A <= 114;
				 28, 29, 30, 31, 32, 33, 34, 35, 36: A <= counter + 20;
				 //37:  A <= 115;
				 44, 45, 46, 47, 48, 49, 50, 51, 52, 53: A <= counter + 70;
				default:	A <= 0;
			endcase
		end
		default: begin
			D <= 0;
			A <= 0;
			WEN <= 1;
		end
	endcase
end
//---------------------------------------------------------------------
//   Synopsys DesignWare                      
//---------------------------------------------------------------------
DW02_mult #(8,4) M_1(.A(m_1), .B(weight_1),.TC(1'b1), .PRODUCT(RESULT_1));
DW02_mult #(8,4) M_2(.A(m_2),.B(weight_2),.TC(1'b1), .PRODUCT(RESULT_2));
DW02_mult #(8,4) M_3(.A(m_3),.B(weight_3),.TC(1'b1), .PRODUCT(RESULT_3));
DW01_add #(13) A_1(.A(a_1),.B(a_2),.CI(1'b0),.SUM(RESULT_4),.CO(CO[0]));
DW01_add #(13) A_2(.A(a_3),.B(a_4),.CI(1'b0),.SUM(RESULT_5),.CO(CO[1]));
DW01_add #(14) A_3(.A(a_5),.B(a_6),.CI(1'b0),.SUM(RESULT_6),.CO(CO[2]));

// carry out buffer
always@(*) begin
	co[0] = CO[0];
	co[1] = CO[1];
	co[2] = CO[2];
end
// result_1 to result_6 buffer
always@(*) begin
	result_1 = RESULT_1;
	result_2 = RESULT_2;
	result_3 = RESULT_3;
	result_4 = RESULT_4;
	result_5 = RESULT_5;
	result_6 = RESULT_6; // need to modify
end
//---------------------------------------------------------------------
// PIPELINE MULTI AND ADD
//---------------------------------------------------------------------
// weight_1 weight_2 weight_3
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		weight_1 <= 4'b0;
		weight_2 <= 4'b0;
		weight_3 <= 4'b0;
	end else case(c_state)
		S_CONV: begin
			case(inner_cont)
				1: begin
					weight_1 <= weight_buf[0];
					weight_2 <= weight_buf[1];
					weight_3 <= weight_buf[2];
				end
				2: begin
					weight_1 <= weight_buf[3];
					weight_2 <= weight_buf[4];
					weight_3 <= weight_buf[5];
				end
				0: begin
					weight_1 <= weight_buf[6];
					weight_2 <= weight_buf[7];
					weight_3 <= weight_buf[8];
				end
			endcase
		end
		S_AFF_2: begin
			case(counter)
				11, 25, 39, 55: begin
					weight_1 <= weight_buf[0];
					weight_2 <= weight_buf[1];
					weight_3 <= weight_buf[2];
				end
				12, 26, 40, 56: begin
					weight_1 <= weight_buf[3];
					weight_2 <= weight_buf[4];
					weight_3 <= weight_buf[5];
				end
				13, 27, 41, 57: begin
					weight_1 <= weight_buf[6];
					weight_2 <= weight_buf[7];
					weight_3 <= weight_buf[8];
				end
				default: begin
					weight_1 <= weight_1;
					weight_2 <= weight_2;
					weight_3 <= weight_3;
				end
			endcase
		end
		default: begin
			weight_1 <= weight_1;
			weight_2 <= weight_2;
			weight_3 <= weight_3;
		end
	endcase
end
// m_1 m_2 m_3 buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		m_1 <= 8'b0;
		m_2 <= 8'b0;
		m_3 <= 8'b0;
	end else case(c_state)
		S_CONV: begin
			case(inner_cont)
				1: begin
					m_1 <= convolution_buf[0];
					m_2 <= convolution_buf[1];
					m_3 <= convolution_buf[2];
				end
				2: begin
					m_1 <= convolution_buf[3];
					m_2 <= convolution_buf[4];
					m_3 <= convolution_buf[5];
				end
				0: begin
					m_1 <= convolution_buf[6];
					m_2 <= convolution_buf[7];
					m_3 <= convolution_buf[8];
				end
				default: begin
					m_1 <= m_1;
					m_2 <= m_2;
					m_3 <= m_3;
				end
			endcase
		end
		S_AFF_2: begin
			case(counter)
				11, 25, 39: begin
					m_1 <= pooling_buf[0][7:0];
					m_2 <= pooling_buf[10][7:0];
					m_3 <= pooling_buf[20][7:0];
				end
				12, 26, 40: begin
					m_1 <= pooling_buf[21][7:0];
					m_2 <= pooling_buf[13][7:0];
					m_3 <= pooling_buf[5][7:0];
				end
				13, 27, 41: begin
					m_1 <= pooling_buf[6][7:0];
					m_2 <= pooling_buf[16][7:0];
					m_3 <= pooling_buf[26][7:0];
				end
				55, 56, 57: begin
					m_1 <= fc_buf[0];
					m_2 <= fc_buf[1];
					m_3 <= fc_buf[2];
				end
				default: begin
					m_1 <= m_1;
					m_2 <= m_2;
					m_3 <= m_3;
				end
			endcase
		end
		default: begin
			m_1 <= m_1;
			m_2 <= m_2;
			m_3 <= m_3;
		end
	endcase
end
// a_1 a_2 a_3 a_4 a_5 a_6 buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		a_1 <= 12'b0;
		a_2 <= 12'b0;
		a_3 <= 12'b0;
		a_4 <= 12'b0;
		a_5 <= 13'b0;
		a_6 <= 13'b0;
	end else case(c_state)
		S_CONV: begin
			a_1 <= result_1;
			a_2 <= result_2;
			a_3 <= result_3;
			case(inner_cont)
				2:	a_4 <= weight_buf[9]   << 8;	// 12 bits
				0:	a_4 <= weight_buf[10] << 8;
				1: a_4 <= weight_buf[11] << 8;
				default:a_4 <= a_4;
			endcase
			a_5<= {co[0] ,result_4};
			a_6 <= {co[1] ,result_5};
		end
		S_AFF_2: begin
			a_1 <= result_1;
			a_2 <= result_2;
			a_3 <= result_3;
			// not finish here
			a_4 <= stage_1_buf[1] << 5;
			a_5<= {co[0] ,result_4};	// 13 bits
			a_6 <= {co[1] ,result_5}; // 13 bits
		end
		default: begin
			a_1 <= a_1;
			a_2 <= a_2;
			a_3 <= a_3;
			a_4 <= a_4;
			a_5 <= a_5;
			a_6 <= a_6;
		end
	endcase
end

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
                n_state = S_CONV;
            else
                n_state = c_state;
        end
        S_CONV: begin
            if(done)
                n_state = S_AFF_1;
        end
		S_AFF_1: begin
			if(flag_FC)
				n_state = S_AFF_2;
			else
				n_state = S_POOL;
		end
		S_POOL: begin
			if(done)
				n_state = S_AFF_1;
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
// weight_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 12; i= i + 1)
			weight_buf[i] <= 4'b0;
	end else if(in_valid_2) begin
		case(counter)
			6:   weight_buf[0] <=   Q_cs;
			7:   weight_buf[1] <=   Q_cs;
			8:   weight_buf[2] <=   Q_cs;
			9:   weight_buf[3] <=   Q_cs;
			10: weight_buf[4] <=   Q_cs;
			11: weight_buf[5] <=   Q_cs;
			19: weight_buf[6] <=   Q_cs;
			20: weight_buf[7] <=   Q_cs;
			21: weight_buf[8] <=   Q_cs;
			27: weight_buf[9] <=   Q_cs;
			28: weight_buf[10] <= Q_cs;
			29: weight_buf[11] <= Q_cs;
			default: begin
				for(i = 0; i < 12; i= i + 1)
					weight_buf[i] <= weight_buf[i];
			end
		endcase
	end else if(c_state == S_AFF_2) begin
		case(counter)
			 3  , 17, 31, 47: weight_buf[0] <= Q_cs;
			 4  , 18, 32, 48: weight_buf[1] <= Q_cs;
			 5  , 19, 33, 49: weight_buf[2] <= Q_cs;
			 6  , 20, 34, 50: weight_buf[3] <= Q_cs;
			 7  , 21, 35, 51: weight_buf[4] <= Q_cs;
			 8  , 22, 36, 52: weight_buf[5] <= Q_cs;
			 9  , 23, 37, 53: weight_buf[6] <= Q_cs;
			 10, 24, 38, 54: weight_buf[7] <= Q_cs;
			 11, 25, 39, 55: weight_buf[8] <= Q_cs;
			 12, 26, 40, 56: weight_buf[9] <= Q_cs;
			default: begin
				for(i = 0; i < 12; i= i + 1)
					weight_buf[i] <= weight_buf[i];
			end
		endcase
	end else begin
		for(i = 0; i < 9; i= i + 1)
			weight_buf[i] <= weight_buf[i];
	end
end

//--------------- Data input for image
// image_buf
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i = 0;  i< 8; i = i+1) begin
			for(j = 0; j< 8; j = j+1)
				image_buf[i][j] <= 8'b0;
		end
    end else if(in_valid_2) begin
        if(counter < 8)
            image_buf[0][counter      ] <= in_data >> 7;
        else if(counter < 16)
            image_buf[1][counter-   8] <= in_data >> 7;
        else if(counter < 24)
            image_buf[2][counter- 16] <= in_data >> 7;
        else if(counter < 32)
            image_buf[3][counter- 24] <= in_data >> 7;
        else if(counter < 40)
            image_buf[4][counter- 32] <= in_data >> 7;
        else if(counter < 48)
            image_buf[5][counter- 40] <= in_data >> 7;
        else if(counter < 56)
            image_buf[6][counter- 48] <= in_data >> 7;
        else if(counter < 64)
            image_buf[7][counter- 56] <= in_data >> 7;
    end
end

//---------------   Counter
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n)
        counter <= 7'd0;
    else if(in_valid_1 || in_valid_2)
        counter <= counter + 1;
    else case(c_state)
		S_CONV, S_POOL, S_AFF_2:
			counter <= counter + 1;
		S_AFF_1:
			counter <= 7'b0;
		S_OUTPUT, S_IDLE:
			counter <= 7'b0;
		default:
			counter <= counter;
	endcase
end

//---------------   Inner_cont
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		inner_cont <= 2'b0;
	else case(c_state)
		S_CONV: begin
			case(inner_cont)
				0: inner_cont <= 1;
				1: inner_cont <= 2;
				2: inner_cont <= 0;
				default: inner_cont <= inner_cont;
			endcase
		end
		S_AFF_1, S_OUTPUT:
			inner_cont <= 0;
		default:
			inner_cont <= inner_cont;
	endcase
end

//-------------- Done Flag 
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		done <= 0;
	else case(c_state)
		S_CONV: begin
			if(counter ==108)
				done <= 1;
			else
				done <= done;
		end
		S_POOL: begin
			if(counter == 11) done <= 1;
			else done <= done;
		end
		S_AFF_1, S_OUTPUT:
			done <= 0;
		S_AFF_2: begin
			if(counter == 61) done <= 1;
			else done <= done;
		end
		default:
			done <= done;
	endcase
end

//--------------- Flag FC
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		flag_FC <= 1'b0;
	else if(c_state == S_AFF_1)
		flag_FC <= ~flag_FC;	//0 -> 1 1->0
end

// column
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		column <= 0;
	end else case(c_state)
		S_CONV: begin
			if(inner_cont == 2)
				column <= column + 1;
			else if(column == 5 && row < 5)
				column <= 0;
			else
				column <= column;
		end
		S_AFF_1:
			column <= 1;
		S_POOL:
			case(column)
				1:	column <= 3;
				3: column <= 5;
				5: column <= 1;
				default: column <= column;
			endcase
		S_OUTPUT:
			column <= 0;
		default:
			column <= column;
	endcase
end

// row
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		row <= 0;
	else case(c_state)
		S_CONV: begin
			if(column == 5 && row < 5)
				row <= row + 1;
			else
				row <= row;
		end
		S_AFF_1:
			row <= 1;
		S_POOL:
			if(column == 5) begin
				case(row)
					1:	row <= 3;
					3: row <= 5;
					5: row <= 5;
					default: row <= row;
				endcase
			end
		S_OUTPUT:
			row <= 0;
		default:
			row <= row;
	endcase
end

//---------------------------------------------------------------------
//  Convolutional Layer
//---------------------------------------------------------------------

// convolution_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 9; i  = i + 1) begin
			convolution_buf[i] <= 8'b0;
		end
	end else if(c_state == S_CONV) begin
		convolution_buf[0]	<= image_buf[row+2][column]     >> 7;
		convolution_buf[1]	<= image_buf[row+2][column+1] >> 7;
		convolution_buf[2]	<= image_buf[row+2][column+2] >> 7;
		convolution_buf[3]	<= image_buf[row][column]         >> 7;
		convolution_buf[4]	<= image_buf[row][column+1]     >> 7;
		convolution_buf[5]	<= image_buf[row][column+2]     >> 7;
		convolution_buf[6]	<= image_buf[row+1][column]     >> 7;
		convolution_buf[7]	<= image_buf[row][column+1]     >> 7;
		convolution_buf[8]	<= image_buf[row][column+2]     >> 7;
	end else begin
		for(i = 0; i < 9; i  = i + 1) begin
			convolution_buf[i] <= convolution_buf[i];
		end
	end
end
// conimg_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 6; i = i + 1) begin
			for(j= 0 ; j <6; j = j + 1) begin
				for(k = 0; k < 3; k = k + 1) begin
					conimg_buf[i][j][k] <= 8'b0;
				end
			end
		end
	end else if(c_state == S_CONV) begin
		case(counter)
			3:			conimg_buf[row][column][0] <= result_6     >> 6;
			106:		conimg_buf[5][5][0] <= {{co[2]},result_6} >> 6;
			107:		conimg_buf[5][5][1] <= {{co[2]},result_6} >> 6;
			108:		conimg_buf[5][5][2] <= {{co[2]},result_6} >> 6;
			default: begin
			case(inner_cont)
				0:conimg_buf[row][column][0]        <= {{co[2]},result_6} >> 6;
				1:conimg_buf[row-1][column-1][1]  <= {{co[2]},result_6} >> 6;
				2:conimg_buf[row-1][column-1][2]  <= {{co[2]},result_6} >> 6;
			endcase
			end
		endcase
	end
end

//---------------------------------------------------------------------
//  Pooling Layer
//---------------------------------------------------------------------

// stage_1_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 6; i = i + 1)
			stage_1_buf[i] <= 8'b0;
	end else if(c_state == S_POOL) begin
		for(j = 0; j < 3; j = j + 1) begin
			if(conimg_buf[row -1][column-1][j] > conimg_buf[row -1][column][j])
				stage_1_buf[0 + j*2]  <= conimg_buf[row -1][column-1][j];
			else
				stage_1_buf[0 + j*2]  <= conimg_buf[row -1][column][j];
			if(conimg_buf[row][column-1][j] > conimg_buf[row][column][j])
				stage_1_buf[1 + j*2] <= conimg_buf[row][column-1][j];
			else
				stage_1_buf[1 + j*2] <= conimg_buf[row][column][j];
		end
	end else if(c_state == S_AFF_2) begin
		stage_1_buf[0] <= {co[0],result_4} >> 5;
		stage_1_buf[1] <= result_3 >> 4;
		stage_1_buf[2] <= {co[2],result_6} >> 6;
		stage_1_buf[3] <= stage_1_buf[0] + stage_1_buf[2];
		stage_1_buf[4] <= result_3 >> 8 + stage_1_buf[1];
		stage_1_buf[5] <= stage_1_buf[5];
	end else begin
		for(i = 0; i < 6; i = i + 1)
			stage_1_buf[i] <= stage_1_buf[i];
	end
end
// stage_2_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 3; i = i + 1)
			stage_2_buf[i] <= 8'b0;
	end else if(c_state == S_POOL) begin
		// filter 1
		if(stage_1_buf[0] > stage_1_buf[1])
			stage_2_buf[0]  <= stage_1_buf[0];
		else
			stage_2_buf[0]  <= stage_1_buf[1];
		// filter 2
		if(stage_1_buf[2] > stage_1_buf[3])
			stage_2_buf[1]  <= stage_1_buf[2];
		else
			stage_2_buf[1]  <= stage_1_buf[3];
		// filter 3
		if(stage_1_buf[4] > stage_1_buf[5])
			stage_2_buf[2]  <= stage_1_buf[4];
		else
			stage_2_buf[2]  <= stage_1_buf[5];
	end else if(c_state == S_AFF_2) begin
		if(outcome[0] > outcome[1])
			stage_2_buf[0] <= 0;
		else
			stage_2_buf[0] <= 1;
		if(outcome[0] > outcome[2])
			stage_2_buf[1] <= 0;
		else
			stage_2_buf[1] <= 2;
	end else begin
		for(i = 0; i < 3; i = i + 1)
			stage_2_buf[i] <= stage_2_buf[i] ;
	end
end
// pooling_buf		// this is mostly 0 ?
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 27; i = i + 1)
			pooling_buf[i] <= 8'b0;
		pool_cnt <= 4'b0;
	end else if(c_state == S_POOL && counter > 2) begin
		pooling_buf[0 + pool_cnt]   <= stage_2_buf[0];
		pooling_buf[9 + pool_cnt]   <= stage_2_buf[1];
		pooling_buf[18+pool_cnt]   <= stage_2_buf[2];
		pool_cnt <= pool_cnt + 1;
	end else begin
		for(i = 0; i < 27; i = i + 1)
			pooling_buf[i] <= pooling_buf[i];
		pool_cnt <= 4'b0;
	end
end

//---------------------------------------------------------------------
//  Fully Connected Layer
//---------------------------------------------------------------------

// fc_buf
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		fc_buf[0] <= 8'b0;
		fc_buf[1] <= 8'b0;
		fc_buf[2] <= 8'b0;
	end else if(c_state == S_AFF_2) begin
		case(counter)
			15: fc_buf[0] <= stage_1_buf[3];
			29: fc_buf[1] <= stage_1_buf[3];
			43: fc_buf[2] <= stage_1_buf[3];
			default: begin
				fc_buf[0] <= fc_buf[0];
				fc_buf[1] <= fc_buf[1];
				fc_buf[2] <= fc_buf[2];
			end
		endcase
	end else begin
		fc_buf[0] <= fc_buf[0];
		fc_buf[1] <= fc_buf[1];
		fc_buf[2] <= fc_buf[2];
	end
end
// outcome
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		outcome[0] <= 8'b0;
		outcome[1] <= 8'b0;
		outcome[2] <= 8'b0;
	end else if(c_state == S_AFF_2) begin
		case(counter)
			57: outcome[0] <= stage_1_buf[4];
			58: outcome[1] <= stage_1_buf[4];
			59: outcome[2] <= stage_1_buf[4];
			default: begin
				outcome[0] <= outcome[0];
				outcome[1] <= outcome[1];
				outcome[2] <= outcome[2];
			end
		endcase
	end else begin
		outcome[0] <= outcome[0];
		outcome[1] <= outcome[1];
		outcome[2] <= outcome[2];
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		number <= 2'b00;
	else if(c_state == S_AFF_2) begin
		case(stage_2_buf[1])
			0: begin
				if(outcome[0] > outcome[1])
					number <= 2'b00;
				else
					number <= 2'b01;
			end
			2: begin
				if(outcome[2] > outcome[1])
					number <= 2'b10;
				else
					number <= 2'b01;
			end
			default:
				number <= number;
		endcase
	end else begin
		number <= number;
	end
end
//---------------------------------------------------------------------
//  Output Section
//---------------------------------------------------------------------

//   Output part                                      
always@(posedge clk or negedge rst_n) begin
    if(!rst_n)
        out_valid <= 1'b0;
    else if(c_state == S_OUTPUT)
        out_valid <= 1'b1;
    else
        out_valid <= 1'b0;
end

// number
always@(posedge clk or negedge rst_n)   begin
    if(!rst_n) begin
        number_2 <= 1'b0;
        number_4 <= 1'b0;
        number_6 <= 1'b0;
    end else if(c_state == S_OUTPUT)    begin
        case(number)
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
