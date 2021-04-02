//
// Simple 1st order Sigma Delta DAC
//

module sigma_delta_dac_1storder
(
   input clk,
   input reset_n,
   input [15:0] d,
   output q
);

reg q_reg;
assign q=q_reg;

reg [16:0] sigma;

always @(posedge clk or negedge reset_n) begin
   if(!reset_n) begin
      sigma <= 17'h8000;
      q_reg <= 1'b0;
   end else begin
      sigma <= sigma + {1'b0,d} + {sigma[16],16'b0};
      q_reg <= sigma[16];
   end
end

endmodule

