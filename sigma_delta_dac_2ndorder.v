module sigma_delta_dac_2ndorder #(parameter signalwidth=16)
(
	input clk,
	input reset_n,
	input [signalwidth-1:0] d, 
	output q
);

	reg this_bit;
 
	reg [signalwidth+3:0] DAC_acc_1st;
	reg [signalwidth+3:0] DAC_acc_2nd;
	reg [signalwidth+3:0] i_func_extended;
	 
	assign q = this_bit;

	always @(*)
		i_func_extended = {{5{!d[signalwidth-1]}},d[signalwidth-2:0]};
		
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n)
			begin
				DAC_acc_1st=20'd0;
				DAC_acc_2nd=20'd0;
				this_bit = 1'b0;
			end
		else
			begin
				if(this_bit == 1'b1) begin
					DAC_acc_1st = DAC_acc_1st + i_func_extended - (2**signalwidth);
					DAC_acc_2nd = DAC_acc_2nd + DAC_acc_1st		 - (2**signalwidth);
				end
			else
				begin
					DAC_acc_1st = DAC_acc_1st + i_func_extended + (2**signalwidth);
					DAC_acc_2nd = DAC_acc_2nd + DAC_acc_1st + (2**signalwidth);
				end
			// When the high bit is set (a negative value) we need to output a 0 and when it is clear we need to output a 1.
			this_bit = ~DAC_acc_2nd[signalwidth+3];
		end
	end
				
endmodule


