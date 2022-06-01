#!/usr/bin/env bash

BENCHMARK_DIR=$(pwd)
MEMPOOL_DIR=/scratch/bsc22f8/git/oswaldlo1/mempool
SNITCH_DIR=/scratch/bsc22f8/git/oswaldlo1/snitch
BANSHEE_DIR=$SNITCH_DIR/sw/banshee

### Setup ###
# clean files
# rm -f {multicore,singlecore}/{apps,banshee-results,rtl-results}/{baseline,xpulp}/*

# clean mempool
cd $MEMPOOL_DIR/software
make clean
cd ..

# exit

### Generate test apps ###
echo "Generate test apps"
# without xpulp enabled
config=minpool make XPULPIMG=0 apps
# copy to save location
cp -rf software/bin/* $BENCHMARK_DIR/multicore/apps/baseline
# with xpulp enabled
config=minpool make XPULPIMG=1 apps
# copy to save location
cp -rf software/bin/* $BENCHMARK_DIR/multicore/apps/xpulp

# exit

### Run benchmarks ###
echo "Run benchmarks"
cd $MEMPOOL_DIR/hardware
unset CC && unset CXX
# make clean #&& config=minpool make simcvcs

# without xpulp enabled
cp -rf $BENCHMARK_DIR/multicore/apps/baseline/* $MEMPOOL_DIR/software/bin
app=convolution config=minpool make benchmark | tee $BENCHMARK_DIR/multicore/rtl-results/baseline/convolution

cd $BANSHEE_DIR
SNITCH_LOG=banshee::engine=TRACE cargo run -- --num-cores 16 --num-clusters 1 --configuration config/mempool.yaml \
    $MEMPOOL_DIR/software/bin/convolution --latency &> $BENCHMARK_DIR/multicore/banshee-results/baseline/convolution

# exit

# with xpulp enabled
cp -rf $BENCHMARK_DIR/multicore/apps/xpulp/* $MEMPOOL_DIR/software/bin
app=convolution config=minpool make benchmark | tee $BENCHMARK_DIR/multicore/rtl-results/xpulp/convolution

cd $BANSHEE_DIR
SNITCH_LOG=banshee::engine=TRACE cargo run -- --num-cores 16 --num-clusters 1 --configuration config/mempool.yaml \
    $MEMPOOL_DIR/software/bin/convolution --latency &> $BENCHMARK_DIR/multicore/banshee-results/xpulp/convolution



### Extract results
grep "[DUMP].*: 0x002 =    .*" multicore/rtl-results/xpulp/convolution

grep "TRACE banshee::engine > Core .*: Write CSR Frm = 0x.*" multicore/banshee-results/xpulp/matmul_i32 | sort

grep "TRACE banshee::engine > Core \(.*\): Write CSR Frm = 0x\(.*\)" multicore/banshee-results/xpulp/matmul_i32 | sort | grep -o "[0-9]*"


grep "TRACE banshee::engine > Core \(.*\): Write CSR Frm = 0x\(.*\)" $dir/$file | sort | grep -o "[0-9]*" > $dir/res_$file


# cut only fields 6 and 11; fields separated by " "
# tr changes ":" to ","
grep "TRACE banshee::engine > Core \(.*\): Write CSR Frm = 0x\(.*\)" $dir/$file | sort | cut -d " " -f 6,11 | tr ":" "," > $dir/res_$file
