module sigma_delta_dac_2ndorder(
  input clk,
  input reset_n,
  input [15:0] d, 
  output q
);

  reg this_bit;
 
  reg [19:0] DAC_acc_1st;
  reg [19:0] DAC_acc_2nd;
  reg [19:0] i_func_extended;
   
  assign q = this_bit;

  always @(*)
     i_func_extended = {{6{!d[15]}},d[14:1]};	// Truncate the lowest bit since 2+ order modulators are unstable with full scale values
    
  always @(posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          DAC_acc_1st=20'd0;
          DAC_acc_2nd=20'd0;
          this_bit = 1'b0;
        end
      else
        begin
          if(this_bit == 1'b1)
            begin
              DAC_acc_1st = DAC_acc_1st + i_func_extended - (2**15);
              DAC_acc_2nd = DAC_acc_2nd + DAC_acc_1st     - (2**15);
            end
          else
            begin
              DAC_acc_1st = DAC_acc_1st + i_func_extended + (2**15);
              DAC_acc_2nd = DAC_acc_2nd + DAC_acc_1st + (2**15);
            end
          // When the high bit is set (a negative value) we need to output a 0 and when it is clear we need to output a 1.
          this_bit = ~DAC_acc_2nd[19];
        end
    end
endmodule

