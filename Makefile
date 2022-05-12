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

all: 


apps: 
	echo "Generate test apps"
	config=$(config) make -C $(MEMPOOL_DIR)/software XPULPIMG=$(XPULP) apps
# copy to save location
	cp -rf $(MEMPOOL_DIR)/software/bin/* $(BENCHMARK_DIR)/$(CORES)/apps/$(MODE)

simcvcs:
	unset CC && unset CXX
	make -C $(MEMPOOL_DIR)/hardware clean
	config=$(config) make -C $(MEMPOOL_DIR)/hardware simcvcs

simulation: rtl-simulation banshee-simulation
	echo "Run benchmarks"


rtl-simulation:
	cp -rf $(BENCHMARK_DIR)/$(CORES)/apps/$(MODE)/* $(MEMPOOL_DIR)/software/bin
	app=$(TEST) config=$(config) make -C $(MEMPOOL_DIR)/hardware benchmark \
	| tee $(BENCHMARK_DIR)/$(CORES)/rtl-results/$(MODE)/$(TEST)


banshee-simulation:
	cp -rf $(BENCHMARK_DIR)/$(CORES)/apps/$(MODE)/* $(MEMPOOL_DIR)/software/bin
	cd $(BANSHEE_DIR) && \
	SNITCH_LOG=banshee::engine=TRACE cargo run -- --num-cores $(NUM_CORES) --num-clusters 1 --configuration config/mempool.yaml \
	$(MEMPOOL_DIR)/software/bin/$(TEST) --latency &> $(BENCHMARK_DIR)/$(CORES)/banshee-results/$(MODE)/$(TEST)


get-results:


clean:
# clean old results out
	rm -f {multicore,singlecore}/{apps,banshee-results,rtl-results}/{baseline,xpulp}/*
# clean Mempool
	$(MAKE) -C $(MEMPOOL_DIR)/hardware clean
	$(MAKE) -C $(MEMPOOL_DIR)/software clean