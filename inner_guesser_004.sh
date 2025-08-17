#!/bin/bash

# set your own drpool accountname
accountname="mustfun.g004"

pids=$(ps -ef | grep dr_neptune_prover | grep -v grep | awk '{print $2}')
if [ -n "$pids" ]; then
    echo "$pids" | xargs kill
    sleep 5
fi

while true; do
    target=$(ps aux | grep dr_neptune_prover | grep -v grep)
    if [ -z "$target" ]; then
        ./dr_neptune_prover --pool stratum+tcp://neptune.drpool.io:30127 --worker $accountname
        sleep 5
    fi
    sleep 60
done
