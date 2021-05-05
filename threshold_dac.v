//
// Utterly useless demo DAC which merely applies a threshold function to an input signal.
//

module threshold_dac #(parameter signalwidth=16)
(
   input clk,
   input reset_n,
   input [signalwidth-1:0] d,
   output q
);

reg q_reg;
assign q=q_reg;

always @(posedge clk or negedge reset_n) begin
   if(!reset_n) begin
      q_reg <= 1'b0;
   end else begin
      q_reg <= d[signalwidth-1];
   end
end

endmodule

