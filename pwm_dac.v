//
// Simple PWM DAC
//

module pwm_dac #(parameter signalwidth=16,parameter pwmwidth=6)
(
   input clk,
   input reset_n,
   input [signalwidth-1:0] d,
   output q
);

reg q_reg;
assign q=q_reg;

reg [pwmwidth-1:0] pwmcounter;

always @(posedge clk or negedge reset_n) begin
   if(!reset_n) begin
      q_reg <= 1'b0;
			pwmcounter<={pwmwidth{1'b0}};
   end else begin
			pwmcounter<=pwmcounter+1'b1;
			if(pwmcounter > d[signalwidth-1:signalwidth-pwmwidth])
				q_reg<=1'b0;
			else
				q_reg<=1'b1;
   end
end

endmodule

