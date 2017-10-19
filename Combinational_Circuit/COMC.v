module COMC
(
        in_n0,
        in_n1,
        in_n2,
        in_n3,
        opt,
        out_n0,
        out_n1,
        out_n2,
        out_n3
);

input[3:0]in_n0,in_n1,in_n2,in_n3;
input[1:0]opt;
output reg[3:0]out_n0,out_n1,out_n2,out_n3;
reg[5:0] tmp;
reg[3:0] max, array [1:4];
integer i,j;

always@*
begin

array[1] = in_n0;
array[2] = in_n1;
array[3] = in_n2;
array[4] = in_n3;
//-----------------------------------//
case(opt)
  2'b00:
  begin
  //sort
    for(i=1;i < 4; i = i + 1) begin
      for(j = 1;j < 5 - i; j = j + 1) begin
        if(array[j] > array[j+1]) begin
          max = array[j];
          array[j] = array[j+1];
          array[j+1] = max;
        end
      end
    end
  //smoothing
    tmp = (array[1] + array[2] + array[3] + array[4])/4;
    array[4] = tmp;
  
  //output
    out_n0 = array[1];
    out_n1 = array[2];
    out_n2 = array[3];
    out_n3 = array[4];
  end
//-----------------------------------//
  2'b01:
  begin
  //sort
    for(i=1;i < 4; i = i +1) begin
      for(j = 1;j < 5 - i; j = j + 1) begin
        if(array[j] > array[j+1]) begin
          max = array[j];
          array[j] = array[j+1];
          array[j+1] = max;
        end
      end
    end
  //normalize
    tmp = array[1];
    array[1] = 0;
    for(i=2;i<=4; i = i+1) begin
      if(array[i] < tmp) 
        array[i] = array[i] +10 - tmp;
      else 
        array[i] = array[i] - tmp;
    end
  //output
    out_n0 = array[1];
    out_n1 = array[2];
    out_n2 = array[3];
    out_n3 = array[4];
  end
//-----------------------------------//
  2'b10:
  begin
  //inverse
    tmp = array[1];
    array[1] = array[4];
    array[4] = tmp;
    tmp = array[2];
    array[2] = array[3];
    array[3] = tmp; 
  //normalize
    tmp = array[1];
    array[1] = 0;
    for(i=2;i<=4; i = i+1) begin
      if(array[i] < tmp)
        array[i] = array[i] +10 - tmp;
      else
        array[i] = array[i] - tmp;
    end
  //output
    out_n0 = array[1];
    out_n1 = array[2];
    out_n2 = array[3];
    out_n3 = array[4];
  end
//-----------------------------------//
  2'b11:
  begin
  //smoothing
    tmp = (array[1] + array[2] + array[3] + array[4])/4;
    
    j = 0;
    max = 0;
    for(i=1;i<5;i = i+1) begin
      if(array[i] >= max) begin
        j = i;
        max = array[i];
      end
    end
    
    array[j] = tmp;
  //mirror
    for(i=1;i < 5; i = i + 1) begin
      if(array[i] == 0 || array[i] == 5)
        array[i] = array[i];
      else
        array[i] = 10 - array[i];
    end
  //output
    out_n0 = array[1];
    out_n1 = array[2];
    out_n2 = array[3];
    out_n3 = array[4];
  end
//-----------------------------------//
  default: 
  begin
    out_n0 = 4'bx;
    out_n1 = 4'bx;
    out_n2 = 4'bx;
    out_n3 = 4'bx;
  end
endcase

end

endmodule
