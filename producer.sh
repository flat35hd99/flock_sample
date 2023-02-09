#!/bin/bash -eu

source ./lib/task_queue.sh

for i in `seq 0 99`;do
    enqueue_task $i
done
