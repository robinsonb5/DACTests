# DACTests
A collection of audio DACs and testbenches, to aid in evaluating their performance
and making improvements.

These examples are referenced in the following series of blog posts:
* http://retroramblings.net/?p=1562
* http://retroramblings.net/?p=1570
* http://retroramblings.net/?p=1578

* http://retroramblings.net/?p=1619
* http://retroramblings.net/?p=1686

## DACs

* sigma\_delta\_dac\_1storder - the classic 1st order DAC
* sigma\_delta\_dac\_2ndorder - a slightly modified version of https://github.com/hamsternz/second_order_sigma_delta_DAC/blob/master/second_order_dac.v
* sigma\_delta\_dac\_3rdorder - Borrowed from Mark Watson's Atari 800 repo - common/components/hq_dac.v
* hybrid\_pwm\_sd - The 1st order hybrid PWM / Sigma Delta DAC I wrote for Minimig back in 2012.
* hybrid\_2ndorder - A simplistic 2nd order hybrid PWM / Sigma Delta DAC
* hybrid\_2ndorder\_filtered - As above but with an extra layer of feedback with low-pass filtering.
* hybrid\_pwm\_sd_2ndorder - a more elaborate 2nd order DAC with input and feedback filtering.  More resource-hungry than the previous DAC, and it's not clear that it's any better.
* threshold_dac - Simply quantises the input to 1 or 0 (sounds awful!)
* random_dac - Adds random noise then quantises, to demonstrate that this is enough to reveal the original signal, albeit with extra noise.
* pwm_dac - simplistic pulse width modulation DAC, as a baseline comparison for the various Sigma Delta DACs.

## Tests

* sine - Creates a short sine wave at full amplitude.
* fadeout - Creates a sine wave will falling amplitude.
* asymmetric - As above, but simulates imbalance in rising and falling edges of the output driver.
* constant - Creates a low-level constant signal, to aid in checking for idle tones.
* sweep - A slow ramp from a slightly negative to slightly positive signal, to aid in checking for idle tones.
* pcm - Reads a short audio snippet and runs it through a DAC.

## Makefile
To run all tests with all DACs, simple type "make".
Alternatively, you can supply the DACS and TESTS variables to select which ones to build and run, like so:
```make DACS=hybrid_2ndorder\ random_dac TESTS=constant\ pcm```

