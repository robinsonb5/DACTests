#include <cstdio>
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

#define SIGNALWIDTH 16

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
#define SIGNAL_HZ 200.0

#define OVERSAMPLE 128
#define OUTFILTERSHIFT 7


// Return a sample (fetched from stdin)
int sample()
{
	int c;
	int result=0;
	result=getchar();
	result|=(c=getchar())<<8;
	if(c==EOF)
		result=-1;
	return(result);
}


void run_test()
{
	int outfilter=0x8000<<OUTFILTERSHIFT;
	int outfilter2=0x8000<<OUTFILTERSHIFT;
	int out;
	int s;
	int samp=0;

	while(samp>=0)
	{
		samp=sample();
		tb->d=samp^0x8000; // Converted signed PCM data to unsigned

		for(int j=0;j<OVERSAMPLE;++j)
		{
			tick();

			s=0xffff*tb->q;
			// Single-pole approximation of the reconstruction filter
			outfilter+=((s<<OUTFILTERSHIFT)-outfilter)>>OUTFILTERSHIFT;
			outfilter2+=outfilter-(outfilter2>>OUTFILTERSHIFT);
		}

		// Output a sample in signed 16-bit little-endian
		out=(outfilter2>>(2*OUTFILTERSHIFT))-32768;
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
	trace->open("wave.vcd");
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
	delete tb;
	return(0);
}

