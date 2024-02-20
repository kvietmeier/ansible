#!/usr/bin/bash
### VoltDB Benchmark Runs
# Filename = <inc>.<start_tps>-<end_tps>-<NumCPU>.out
# Going through all of these will take 12+hrs
# Run in screen using "nohup ./runtests.sh &"


### Jumps of 10
./runbenchmark.sh 150 250 10 4000000 > 10.150-250-16.out
./runbenchmark.sh 200 300 10 4000000 > 10.200-300-16.out
./runbenchmark.sh 250 350 10 4000000 > 10.250-350-16.out
./runbenchmark.sh 300 400 10 4000000 > 10.300-400-16.out
./runbenchmark.sh 350 450 10 4000000 > 10.400-450-16.out
./runbenchmark.sh 400 500 10 4000000 > 10.400-500-16.out
./runbenchmark.sh 450 550 10 4000000 > 10.450-550-16.out
./runbenchmark.sh 500 600 10 4000000 > 10.500-600-16.out

### Jumps of 1
./runbenchmark.sh 130 150 1 4000000 > 1.130-150-16.out
./runbenchmark.sh 150 170 1 4000000 > 1.150-170-16.out
./runbenchmark.sh 160 180 1 4000000 > 1.160-180-16.out
./runbenchmark.sh 170 190 1 4000000 > 1.170-190-16.out
./runbenchmark.sh 180 200 1 4000000 > 1.180-200-16.out
./runbenchmark.sh 190 210 1 4000000 > 1.190-210-16.out

# Getting it dialed in
./runbenchmark.sh 200 220 1 4000000 > 1.200-220-16.out
./runbenchmark.sh 220 230 1 4000000 > 1.220-230-16.out
./runbenchmark.sh 220 235 1 4000000 > 1.220-235-16.out
./runbenchmark.sh 220 240 1 4000000 > 1.220-240-16.out
./runbenchmark.sh 220 245 1 4000000 > 1.220-245-16.out


## Runs out of juice
#16.200-300-10.out:2024-02-17 12:49:18:UNABLE_TO_MEET_REQUESTED_TPS
#16.230-250-1.out:2024-02-14 20:11:51:UNABLE_TO_MEET_REQUESTED_TPS
#16.240-260-1.out:2024-02-16 13:15:36:UNABLE_TO_MEET_REQUESTED_TPS
#16.245-255-1.out:2024-02-16 14:34:11:UNABLE_TO_MEET_REQUESTED_TPS


