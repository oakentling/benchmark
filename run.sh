#!/usr/bin/env bash

BENCHMARK_DIR=$(pwd)
MEMPOOL_DIR=/scratch/bsc22f8/git/oswaldlo1/mempool
SNITCH_DIR=/scratch/bsc22f8/git/oswaldlo1/snitch
BANSHEE_DIR=$SNITCH_DIR/sw/banshee

make clean

### Multicore
cp -rf apps/original/* ../oswaldlo1/mempool/software/apps
##  Baseline
make config=minpool XPULP=0 simulation
##  Xpulp
make config=minpool XPULP=1 simulation

# create backup
\cp -rf . ../../benchmark-backup/

exit

### Singlecore
cp -rf apps/one-core/* ../oswaldlo1/mempool/software/apps
##  Baseline
make config=minpool XPULP=0 simulation
##  Xpulp
make config=minpool XPULP=1 simulation