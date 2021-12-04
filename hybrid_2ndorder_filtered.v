// Simplistic 2nd order Sigma Delta DAC with 5-bit PWM as an output stage
// and an IIR low pass filter added to the feedback loop.
// Copyright (c) 2022 by Alastair M. Robinson
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


module hybrid_2ndorder_filtered #(parameter signalwidth=16)
(
	input clk,
	input reset_n,
	input [signalwidth-1:0] d, // Unsigned in
	output q
);

	reg newval;
 
	reg [signalwidth-1:0] outfiltered;
	reg [signalwidth+3:0] acc1;
	reg [signalwidth+3:0] acc2;

	reg [4:0] pwmthreshold;
	reg [signalwidth+1:0] d_offset;
	reg [signalwidth+3:0] d_ext;
	
	always @(posedge clk) begin
		// Convert unsigned to signed
		d_offset <= {{2{!d[signalwidth-1]}},d[signalwidth-2:0]}
			- {{2{!outfiltered[signalwidth-1]}},outfiltered[signalwidth-2:0]} // Subtract low-frequency components of quantised signal
			- {7'h1,{signalwidth-5{1'b0}}}; // Offset to correct for slight asymmetry in PWM
		d_ext <= {{4{d_offset[signalwidth]}},d_offset[signalwidth-1:0]}; // Sign extend
	end
			
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			acc1={signalwidth+4{1'b0}};
			acc2={signalwidth+4{1'b0}};
		end	else begin
			if(newval) begin
				acc1 = acc1 + d_ext - {{3{pwmthreshold[4]}},pwmthreshold[3:0],{signalwidth-3{1'b0}}};
				acc2 = acc2 + acc1		 - {{3{pwmthreshold[4]}},pwmthreshold[3:0],{signalwidth-3{1'b0}}};

				pwmthreshold <= acc2[signalwidth+3:signalwidth-1];
			end
		end
	end
		
	reg q_i;
	reg [4:0] pwmcounter;
	wire [4:0] pwmt;
	
	assign pwmt = {!pwmthreshold[4],pwmthreshold[3:0]}; // Convert back to signed

	always @(posedge clk or negedge reset_n) begin
		if(!reset_n)
			pwmcounter<=5'b0;
		else begin
			newval <= 1'b0;

			pwmcounter<=pwmcounter+1;

			if(pwmcounter==5'h1e) begin
				newval<=1'b1;
			end
			if(&pwmcounter) begin
				q_i <= |pwmt;
			end
			if(pwmcounter==pwmt)
				q_i<=1'b0;
			
		end			
	end

	assign q=q_i;

	// Approximation of the reconstruction filter, width chosen by experimentation.
	// We allow 6 bits for the coefficient (1/64) - but the appropriate amount of filtering
	// will depend on the oversampling ratio.

	wire [signalwidth-1:0] temp1;

	iirfilter # (.signalwidth(signalwidth),.cbits(6),.immediate(0)) outputfilter
	(
		.clk(clk),
		.reset_n(reset_n),
		.ena(1'b1),
		.d(q_i ? {signalwidth{1'b0}} : {signalwidth{1'b1}}),
		.q(temp1)
	);

	always @(posedge clk)
		outfiltered <= temp1;

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
		acc[signalwidth+cbits-1:0]<={{signalwidth{1'b1}},{cbits{1'b0}}};
	end
	else if(ena)
		acc <= acc_new;
end

assign q=immediate ? acc_new[signalwidth+cbits-1:cbits] : acc[signalwidth+cbits-1:cbits];

endmodule


