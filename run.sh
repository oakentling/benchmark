#!/usr/bin/env bash

BENCHMARK_DIR=$(pwd)
MEMPOOL_DIR=/scratch/bsc22f8/git/oswaldlo1/mempool
SNITCH_DIR=/scratch/bsc22f8/git/oswaldlo1/snitch
BANSHEE_DIR=$SNITCH_DIR/sw/banshee

make clean

### Multicore
cp -rf apps/original/* ../oswaldlo1/mempool/software/apps
##  Baseline
make config=mempool XPULP=0 simulation
##  Xpulp
make config=mempool XPULP=1 simulation

## Get results
make config=mempool XPULP=0 get-results
make config=mempool XPULP=1 get-results

## Calculate average
python3 average.py -f hardcore/

# create backup
DATETIME=`date +"%Y-%m-%d@%H-%M-%S"`
\cp -rfp . ../../benchmark-backup/${DATETIME} # p will preserve timestamps etc.

exit

### Singlecore
cp -rf apps/one-core/* ../oswaldlo1/mempool/software/apps
##  Baseline
make config=minpool single=1 XPULP=0 simulation
##  Xpulp
make config=minpool single=1 XPULP=1 simulation


### Multicore 16
cp -rf apps/original/* ../oswaldlo1/mempool/software/apps
##  Baseline
make config=minpool single=0 XPULP=0 simulation
##  Xpulp
make config=minpool single=0 XPULP=1 simulation