#!/usr/bin/env bash

for i in {1..100};
do
    (time SNITCH_LOG=info cargo run -- --num-cores 256 --num-clusters 1 \
    --configuration config/mempool.yaml \
    /scratch/bsc22f8/git/oswaldlo1/mempool/software/bin/convolution) >> time_conv 2>&1
done

grep -E "real" time_conv | cut -f 2  > time_conv_real
grep -E "Retired" time_conv | cut -d " " -f 11,12 > time_conv_ret
