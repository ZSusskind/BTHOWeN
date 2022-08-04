#export VCS_HOME /usr/local/packages/synopsys_2018/vcs-mx/O-2018.09-SP1

MAKO_SRC_DIR = mako_srcs
SEARCH_MAKO = $(addsuffix /*.sv.mako, $(MAKO_SRC_DIR))
MAKO_SRCS = $(wildcard $(SEARCH_MAKO))

TESTBENCHES = $(subst testbench/,,$(subst .sv,,$(wildcard testbench/*.sv)))

SV_SRC_DIR = sv_srcs
SV_SRCS = $(subst .mako,,$(subst $(MAKO_SRC_DIR),$(SV_SRC_DIR),$(MAKO_SRCS)))

MODEL ?= ../software_model/selected_models/mnist_small.pickle.lzma
HASH_UNITS ?= -1 # If -1, automatically choose the optimal value to minimize area while maintaining maximum throughput
BUS_WIDTH ?= 64

.PHONY: all
all: template compile run

.PHONY: template
template: $(MAKO_SRCS)
	python3 build/make_rtl.py $(MAKO_SRCS) --model $(MODEL) --hash_units $(HASH_UNITS) --bus_width $(BUS_WIDTH)

.PHONY: compile
compile: template
	$(VCS_HOME)/bin/vcs -full64 \
	${SV_SRCS} \
	-sverilog \
	-partcomp=modautopart \
	-notice \
	-debug_access+all \
	-timescale=1ns/1ns \
	-l compile.log 

$(TESTBENCHES): %: testbench/%.sv compile
	mkdir -p testbench_objs
	$(VCS_HOME)/bin/vcs -full64 \
	${SV_SRCS} $< \
	-o testbench_objs/$@ \
	-sverilog \
	-partcomp=modautopart \
	-notice \
	-debug_access+all \
	-timescale=1ns/1ns \
	-l compile_$@.log

.PHONY: testbenches
testbenches: $(TESTBENCHES)

.PHONY: clean
clean:
	rm sv_srcs/*.sv sv_srcs/*.svh
	rm -r testbench_objs/*

