// Hybrid PWM / Sigma Delta converter
//
// Uses 5-bit PWM, wrapped within a 10-bit Sigma Delta, with the intention of
// increasing the pulse width, since narrower pulses seem to equate to more noise
// Copyright 2012 by Alastair M. Robinson
//
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that they will
// be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>
//


module hybrid_pwm_sd
(
	input clk,
	input reset_n,
	input [15:0] d,
	output q
);

reg [4:0] pwmcounter;
reg [4:0] pwmthreshold;
reg [33:0] scaledin;
reg [15:0] sigma;
wire [15:0] sigmanext;
reg q_reg;

assign sigmanext = scaledin[31:16]+{5'b000000,sigma[10:0]};	// Will use previous iteration's scaledin value

assign q=q_reg;

always @(posedge clk, negedge reset_n) // FIXME reset logic;
begin
	if(!reset_n)
	begin
		sigma<=16'b00000100_00000000;
		pwmthreshold<=5'b10000;
	end
	else
	begin
		pwmcounter<=pwmcounter+1;

		if(pwmcounter==pwmthreshold)
			q_reg<=1'b0;

		scaledin<=33'h200000 // (1<<(16-5))<<16, offset to keep centre aligned.  (Adjusted to eliminate DC offset - PWM not centred?)
			+({1'b0,d}*16'hf000); // 30<<(16-5)-1;

		if(pwmcounter==5'b11111) // Update threshold when pwmcounter reaches zero
		begin
			// Pick a new PWM threshold using a Sigma Delta
			sigma<=sigmanext;
			pwmthreshold<=sigmanext[15:11]; // Will lag 2 cycles behind, but shouldn't matter.
			q_reg<=1'b1;
		end

	end
end

endmodule
