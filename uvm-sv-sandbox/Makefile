# SPDX-License-Identifier: Apache-2.0
# Short names for the scripts in scripts/.  Run: make help
# Example: make run SIM=xsim TEST=add_corner_test SEED=7

SIM       ?= verilator
TEST      ?= add_test
SEED      ?= 1
VERBOSITY ?= UVM_LOW
BUG       ?= 0
WAVES     ?= 0
EXP       ?=

RUN_FLAGS := -s $(SIM) -t $(TEST) -r $(SEED) -v $(VERBOSITY) $(if $(filter 1,$(BUG)),-b) $(if $(filter 1,$(WAVES)),-w)

.PHONY: help setup verilator-build run verilator xsim regress try-sv2023 playground clean distclean

help:
	@echo "Targets (things in [ ] are optional):"
	@echo "  make setup             download the public UVM library; list the simulators found"
	@echo "  make verilator-build   build the latest Verilator into third_party/ (one time)"
	@echo "  make run               [SIM=verilator|xsim] [TEST=add_test|add_corner_test] [SEED=1] [BUG=1] [WAVES=1]"
	@echo "  make verilator         same as: make run SIM=verilator"
	@echo "  make xsim              same as: make run SIM=xsim"
	@echo "  make regress           [SIM=...] two tests that must pass + one bug that must be caught"
	@echo "  make try-sv2023        [SIM=...] [EXP=array_map] which SystemVerilog 2023 features work"
	@echo "  make playground        write build/playground/design.sv and testbench.sv"
	@echo "  make clean             delete build/ (keeps third_party/)"
	@echo "  make distclean         delete build/ and third_party/"

setup:
	bash scripts/setup.sh

verilator-build:
	bash scripts/setup.sh --build-verilator

run:
	bash scripts/run.sh $(RUN_FLAGS)

verilator:
	@$(MAKE) --no-print-directory run SIM=verilator

xsim:
	@$(MAKE) --no-print-directory run SIM=xsim

regress:
	bash scripts/regress.sh -s $(SIM) -r $(SEED)

try-sv2023:
	bash scripts/try_sv2023.sh -s $(SIM) $(EXP)

playground:
	bash scripts/make_playground.sh

clean:
	rm -rf build

distclean: clean
	rm -rf third_party
