# Run benchmarks

SHELL = /usr/bin/env bash
BENCHMARK_DIR := $(shell pwd)

MEMPOOL_DIR := /scratch/bsc22f8/git/oswaldlo1/mempool
SNITCH_DIR := /scratch/bsc22f8/git/oswaldlo1/snitch
BANSHEE_DIR := $(SNITCH_DIR)/sw/banshee

XPULP ?= 0
ifndef config
  ifdef MEMPOOL_CONFIGURATION
    config := $(MEMPOOL_CONFIGURATION)
  else
    # Default configuration, if neither `config` nor `MEMPOOL_CONFIGURATION` was found
    config := minpool
  endif
endif

ifeq ($(config), minpool)
  CORES := multicore
  NUM_CORES := 16
else
  CORES := singlecore
  NUM_CORES := 1
endif

ifeq ($(XPULP), 0)
  MODE := baseline
else
  MODE := xpulp
endif

ifndef TEST
  TEST := convolution
endif

APPS_DIR := $(BENCHMARK_DIR)/multicore/apps/baseline/
APPS := $(patsubst $(APPS_DIR)%.dump,%,$(shell find $(APPS_DIR) -name "*.dump"))

TESTS := convolution matmul_i8 matmul_i16 matmul_i32

unexport CC
unexport CXX

all: all-rtl-simulation all-banshee-simulation

.PHONY: apps
apps: 
	echo "Generate test apps"
	config=$(config) make -C $(MEMPOOL_DIR)/software XPULPIMG=$(XPULP) apps
# copy to save location
	cp -rf $(MEMPOOL_DIR)/software/bin/* $(BENCHMARK_DIR)/$(CORES)/apps/$(MODE)

.PHONY: simcvcs
simcvcs:
	make -C $(MEMPOOL_DIR)/hardware clean
	config=$(config) app=hello_world make -C $(MEMPOOL_DIR)/hardware simcvcs

simulation: all-rtl-simulation all-banshee-simulation

.PHONY: all-rtl-simulation
# w/o addprefix rtl- only preprended to whole variable instead of each word in variable
all-rtl-simulation: apps simcvcs $(addprefix rtl-,$(TESTS))

$(addprefix rtl-,$(TESTS)):
	app=$(patsubst rtl-%,%,$@) config=$(config) make -C $(MEMPOOL_DIR)/hardware benchmark \
	| tee $(BENCHMARK_DIR)/$(CORES)/rtl-results/$(MODE)/$(patsubst rtl-%,%,$@)

rtl-simulation: apps simcvcs
#	cp -rf $(BENCHMARK_DIR)/$(CORES)/apps/$(MODE)/* $(MEMPOOL_DIR)/software/bin
	app=$(TEST) config=$(config) make -C $(MEMPOOL_DIR)/hardware benchmark \
	| tee $(BENCHMARK_DIR)/$(CORES)/rtl-results/$(MODE)/$(TEST)

all-banshee-simulation: apps $(addprefix banshee-,$(TESTS))

$(addprefix banshee-,$(TESTS)):
	cd $(BANSHEE_DIR) && \
	SNITCH_LOG=banshee::engine=TRACE cargo run -- \
	--num-cores $(NUM_CORES) --num-clusters 1 --configuration config/mempool.yaml \
	$(MEMPOOL_DIR)/software/bin/$(patsubst banshee-%,%,$@) --latency &> \
	$(BENCHMARK_DIR)/$(CORES)/banshee-results/$(MODE)/$(patsubst banshee-%,%,$@)


banshee-simulation: apps simcvcs
	# cp -rf $(BENCHMARK_DIR)/$(CORES)/apps/$(MODE)/* $(MEMPOOL_DIR)/software/bin
	cd $(BANSHEE_DIR) && \
	SNITCH_LOG=banshee::engine=TRACE cargo run -- \
	--num-cores $(NUM_CORES) --num-clusters 1 --configuration config/mempool.yaml \
	$(MEMPOOL_DIR)/software/bin/$(TEST) --latency &> $(BENCHMARK_DIR)/$(CORES)/banshee-results/$(MODE)/$(TEST)


get-results:

.PHONY: clean
clean:
# clean old results out
	rm -f {multicore,singlecore}/{apps,banshee-results,rtl-results}/{baseline,xpulp}/*
# clean Mempool
	$(MAKE) -C $(MEMPOOL_DIR)/hardware clean
	$(MAKE) -C $(MEMPOOL_DIR)/software clean