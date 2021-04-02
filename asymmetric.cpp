#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <list>
#include <cmath>

#include DACHEADER

#include "verilated.h"
#include "verilated_vcd_c.h"

#undef TRACE

static VerilatedVcdC *trace;

// Declare the global testbench, of a type externally defined
typedef DAC testbench;
static testbench *tb;


// Simulate at the speed of the MiST Minimig port's SDRAM clock

#define MHz 113.44
static double timestamp = 0;

void tick() {
	tb->clk = 1;
	tb->eval();
	tb->clk = 0;
	tb->eval();
	trace->dump(timestamp);
	timestamp += 500/MHz;
}

#define SAMPLERATE 44100.0
#define SIGNAL_HZ 50.0
#define SAMPLES 32768

#define OVERSAMPLE 2048
#define PWMCYCLE 32
#define OUTFILTERSHIFT 12


// Return a sample from a sine wave
double sample(double s)
{
	double period=SAMPLERATE/SIGNAL_HZ;
	return(sin((s*2*M_PI)/period));
}


void run_test()
{
	int outfilter=0x8000<<OUTFILTERSHIFT;
	int out;
	int s;

	for(int i=0;i<SAMPLES;++i)
	{
		double scale=32768-i;
		scale=scale/32768;
		scale*=scale;
		int samp=(32767+32767*scale*sample(i));
		tb->d=samp;

		for(int j=0;j<OVERSAMPLE;++j)
		{
			tick();

			// Simulate asymmetric rising and falling edges...
			if(tb->q && s<32768) // Rising edge?
				s=0xdfff;
			else if(!tb->q && s>=32768) // Falling edge?
				s=0x5000;
			else
				s=(0xffff*tb->q);
			// Single-pole approximately of the reconstruction filter
			outfilter+=((s<<OUTFILTERSHIFT)-outfilter)>>OUTFILTERSHIFT;
		}

		// Output a sample in signed 16-bit little-endian
		out=(outfilter>>OUTFILTERSHIFT)-32768;
		putchar(out&255);
		putchar((out>>8)&255);
	}
}


int main(int argc, char **argv) {

	// Initialize Verilators variables
	Verilated::commandArgs(argc, argv);
	Verilated::traceEverOn(true);
	trace = new VerilatedVcdC;

	// Create an instance of our module under test
	tb = new testbench;
#ifdef TRACE
	tb->trace(trace, 99);
	trace->open("wave_%s.vcd","\""#DAC#"\"");
#endif

	// Reset the testbench
	tick();
	tb->reset_n = 0;
	tick();
	tick();
	tb->reset_n = 1;

	// Run the test
	run_test();

#ifdef TRACE
	trace->close();
#endif
}

