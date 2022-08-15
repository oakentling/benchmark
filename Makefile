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

ifndef single
  single := 0
endif

ifeq ($(config), minpool)
  ifeq ($(single), 1)
    CORES := singlecore
    NUM_CORES := 1
  endif
  CORES := multicore
  NUM_CORES := 16
else 
  CORES := hardcore
  NUM_CORES := 256
endif

ifeq ($(XPULP), 0)
  MODE := baseline
else
  MODE := xpulp
endif

ifndef app
  app := convolution
endif

# APPS_DIR := $(BENCHMARK_DIR)/multicore/apps/baseline/
# APPS := $(patsubst $(APPS_DIR)%.dump,%,$(shell find $(APPS_DIR) -name "*.dump"))

TESTS := convolution matmul_i8 matmul_i16 matmul_i32 conv2d_i8

rtl_dir := $(BENCHMARK_DIR)/$(CORES)/rtl-results/$(MODE)
banshee_dir := $(BENCHMARK_DIR)/$(CORES)/banshee-results/$(MODE)

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
	config=$(config) app=quick_start make -C $(MEMPOOL_DIR)/hardware simcvcs

simulation: all-rtl-simulation all-banshee-simulation

.PHONY: all-rtl-simulation
# w/o addprefix rtl- only preprended to whole variable instead of each word in variable
all-rtl-simulation: apps simcvcs $(addprefix rtl-,$(TESTS))

$(addprefix rtl-,$(TESTS)):
	app=$(patsubst rtl-%,%,$@) config=$(config) make -C $(MEMPOOL_DIR)/hardware benchmark \
	| tee $(rtl_dir)/$(patsubst rtl-%,%,$@)
#	extract data
	cp $(MEMPOOL_DIR)/hardware/build/traces/results.csv $(rtl_dir)/results_$(patsubst rtl-%,%,$@).csv
	cp $(MEMPOOL_DIR)/hardware/build/average $(rtl_dir)/avg_$(patsubst rtl-%,%,$@)


rtl-simulation: apps
	make rtl-$(app)

all-banshee-simulation: apps $(addprefix banshee-,$(TESTS))

$(addprefix banshee-,$(TESTS)):
	cd $(BANSHEE_DIR) && \
	SNITCH_LOG=banshee::engine=TRACE cargo run -- \
	--num-cores $(NUM_CORES) --num-clusters 1 --configuration config/mempool.yaml \
	$(MEMPOOL_DIR)/software/bin/$(patsubst banshee-%,%,$@) --latency &> \
	$(banshee_dir)/$(patsubst banshee-%,%,$@)


all-banshee-post-simulation: apps $(addprefix banshee-post-,$(TESTS))

$(addprefix banshee-post-,$(TESTS)):
	cd $(BANSHEE_DIR) && \
	SNITCH_LOG=banshee::engine=TRACE cargo run -- \
	--num-cores $(NUM_CORES) --num-clusters 1 --configuration config/mempool.yaml \
	$(MEMPOOL_DIR)/software/bin/$(patsubst banshee-post-%,%,$@) --latency &> \
	$(banshee_dir)/$(patsubst banshee-%,%,$@)

banshee-simulation: apps
	make banshee-$(app)

$(addprefix get-cycle-,$(TESTS)):
#	extract data
	grep "[DUMP].*: 0x002 =    .*" $(rtl_dir)/$(patsubst get-cycle-%,%,$@) \
	| tr -s " :" "," | cut -d "," -f 2,5 | sort -n > \
	$(rtl_dir)/res-cycle-$(patsubst get-cycle-%,%,$@).csv
	grep "TRACE banshee::engine > Core .*: Write CSR Frm = .*" \
	$(banshee_dir)/$(patsubst get-cycle-%,%,$@) \
	| sort | cut -d " " -f 6,11 | tr ":" "," > \
	$(banshee_dir)/res-cycle-$(patsubst get-cycle-%,%,$@).csv

$(addprefix get-instret-,$(TESTS)):
#	extract data
	grep "[DUMP].*: 0x003 =    .*" $(rtl_dir)/$(patsubst get-instret-%,%,$@) \
	| tr -s " :" "," | cut -d "," -f 2,5 | sort -n > \
	$(rtl_dir)/res-instret-$(patsubst get-instret-%,%,$@).csv
	grep "TRACE banshee::engine > Core .*: Write CSR Fcsr = .*" \
	$(banshee_dir)/$(patsubst get-instret-%,%,$@) \
	| sort | cut -d " " -f 6,11 | tr ":" "," > \
	$(banshee_dir)/res-instret-$(patsubst get-instret-%,%,$@).csv

get-cycle-results: $(addprefix get-cycle-,$(TESTS))

get-instret-results: $(addprefix get-instret-,$(TESTS))

get-results: get-cycle-results get-instret-results


$(addprefix get-cycle-post-,$(TESTS)):
#	extract data
	grep "TRACE banshee::engine > Core .*: Write CSR Frm = .*" \
	$(banshee_dir)/$(patsubst get-cycle-%,%,$@) \
	| sort | cut -d " " -f 6,11 | tr ":" "," > \
	$(banshee_dir)/res-cycle-$(patsubst get-cycle-post-%,%,$@)-post.csv

$(addprefix get-instret-post-,$(TESTS)):
#	extract data
	grep "TRACE banshee::engine > Core .*: Write CSR Fcsr = .*" \
	$(banshee_dir)/$(patsubst get-instret-%,%,$@) \
	| sort | cut -d " " -f 6,11 | tr ":" "," > \
	$(banshee_dir)/res-instret-$(patsubst get-instret-post-%,%,$@)-post.csv

get-cycle-results-post: $(addprefix get-cycle-post-,$(TESTS))

get-instret-results-post: $(addprefix get-instret-post-,$(TESTS))

get-results-post: get-cycle-results-post get-instret-results-post


.PHONY: clean
clean:
# clean old results out
	rm -f {hardcore,multicore,singlecore}/{apps,banshee-results,rtl-results}/{baseline,xpulp}/*
# clean Mempool
	$(MAKE) -C $(MEMPOOL_DIR)/hardware clean
	$(MAKE) -C $(MEMPOOL_DIR)/software clean