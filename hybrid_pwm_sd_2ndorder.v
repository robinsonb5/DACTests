// Hybrid PWM / Sigma Delta DAC
//
// Uses 5-bit PWM, wrapped within a 10-bit Sigma Delta.
// The PWM results in a near constant number of rising and falling edges within
// a given time period, resulting in much less noise from any imbalance between
// the two types of edge.
//
// 2nd order variant with low-pass input filter and high-pass feedback filter.
// Copyright 2021 by Alastair M. Robinson
//
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



module hybrid_pwm_sd_2ndorder #(parameter signalwidth=16)
(
	input clk,
	input reset_n,
	input [signalwidth-1:0] d,
	output q
);

reg q_reg;
//assign q=q_reg;

// Input filtering - a simple single-pole IIR low-pass filter.
// Runs once per PWM cycle, just to limit the maximum input energy to the sigma-detla.
// 2 bits for the coefficient. (1/4)  -  the appropriate amount of filtering will depend on the
// oversampling ratio.

wire [signalwidth-1:0] infiltered;
reg infilterena;

iirfilter # (.signalwidth(signalwidth),.cbits(2)) inputfilter
(
	.clk(clk),
	.reset_n(reset_n),
	.ena(infilterena),
	.d(d),
	.q(infiltered)
);


// Approximation of the reconstruction filter, width chosen by experimentation.
// We allow 7 bits for the coefficient (1/128) - but the appropriate amount of filtering
// will depend on the oversampling ratio.

wire [signalwidth-1:0] outfiltered;
reg outfilterena;

iirfilter # (.signalwidth(signalwidth),.cbits(7),.immediate(1)) outputfilter
(
	.clk(clk),
	.reset_n(reset_n),
	.ena(1'b1),
	.d(q_comb ? {signalwidth{1'b1}} : {signalwidth{1'b0}}),
	.q(outfiltered)
);


reg [signalwidth-1:0] inprev;
reg [signalwidth+1:0] sigma;
reg [signalwidth+1:0] sigma2;

wire [signalwidth+1:0] sigmanext;
assign sigmanext = sigma + {2'b0,infiltered} - {2'b0,outfiltered};

reg [6:0] pwmcounter;
wire [6:0] pwmthreshold;
assign pwmthreshold = sigma2[signalwidth+1:signalwidth-5];

wire q_comb;
// If the sigma-delta is saturated we pass through the MSB of the input data, unmodified.
assign q_comb = pwmthreshold[6] ? infiltered[signalwidth-1] : (pwmcounter<pwmthreshold ? 1'b1 : 1'b0);
assign q=q_comb;

always @(posedge clk,negedge reset_n)
begin
	if(!reset_n) begin
		sigma<={signalwidth+2{1'b0}};
		sigma2={signalwidth+2{1'b0}};
		pwmcounter<=7'b111110;
	end else begin
		infilterena<=1'b0;

		if(pwmcounter==pwmthreshold)
			q_reg<=1'b0;


		if(pwmcounter==7'b11111) // Update threshold when pwmcounter reaches zero
		begin
			inprev<=infiltered;
			infilterena<=1'b1;

			// PWM

			sigma<=sigmanext;
			sigma2=sigmanext+{7'b0010000,sigma2[signalwidth-6:0]};

			if(sigma2[signalwidth+1]==1'b1)
				q_reg<=1'b0;
			else
				q_reg<=1'b1;
		end

		pwmcounter[6:5]<=2'b0;
		pwmcounter[4:0]<=pwmcounter[4:0]+5'b1;
	end
end

endmodule


// Simplistic IIR low-pass filter.
// function is simply y += b * (x - y)
// where b=1/(1<<cbits)

module iirfilter # 
(
	parameter signalwidth = 16,
	parameter cbits = 5,	// Bits for coefficient (default 1/32)
	parameter immediate = 0
)
(
	input clk,
	input reset_n,
	input ena,
	input [signalwidth-1:0] d,
	output [signalwidth-1:0] q
);

reg [signalwidth+cbits-1:0] acc = {{signalwidth{1'b1}},{cbits{1'b0}}};
wire [signalwidth+cbits-1:0] acc_new;

wire [signalwidth+cbits:0] delta = {d,{cbits{1'b0}}} - acc;

assign acc_new = acc + {{cbits{delta[signalwidth+cbits]}},delta[signalwidth+cbits-1:cbits]};


always @(posedge clk, negedge reset_n)
begin
	if(!reset_n)
	begin
		acc[signalwidth+cbits-1:0]<={{signalwidth{1'b1}},{cbits{1'b0}}}; // 1'b1;
//		acc[signalwidth+cbits-2:0]<=0;
	end
	else if(ena)
		acc <= acc_new; // + {{cbits{delta[signalwidth+cbits]}},delta[signalwidth+cbits-1:cbits]};
end

assign q=immediate ? acc_new[signalwidth+cbits-1:cbits] : acc[signalwidth+cbits-1:cbits];

endmodule


