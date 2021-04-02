VERILATOR_DIR=/usr/share/verilator/include
VERILATOR_SRC = $(VERILATOR_DIR)/verilated.cpp $(VERILATOR_DIR)/verilated_vcd_c.cpp 

DACS = sigma_delta_dac_1storder hybrid_pwm_sd sigma_delta_dac_2ndorder sigma_delta_dac_3rdorder
TESTS = sine fadeout asymmetric

all:
	for DAC in $(DACS); do \
		for TEST in $(TESTS); do \
			make $${TEST}_$${DAC}.raw TEST=$$TEST DAC=$$DAC; \
		done; \
	done

clean:
	rm -rf obj_dir
	for TEST in $(TESTS); do \
		rm $${TEST}_*; \
	done;

obj_dir/V%__ALL.a: %.v
	verilator --trace --top-module $* -cc $*.v
	make -C obj_dir -f V$*.mk

$(TEST)_$(DAC): $(TEST).cpp $(VERILATOR_SRC) obj_dir/V$(DAC)__ALL.a
		g++ -DDAC=V$(DAC) -DDACHEADER=\"obj_dir/V$(DAC).h\" -I obj_dir -I$(VERILATOR_DIR) $+ -o $@

$(TEST)_$(DAC).raw: $(TEST)_$(DAC)
		./$(TEST)_$(DAC) >$(TEST)_$(DAC).raw

