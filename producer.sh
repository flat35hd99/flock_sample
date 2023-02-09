#!/bin/bash -eu

# Input ----------------------------------
lock_file=./.lock/mutex.lock
task_queue_file=./.lock/task_queue.txt
# ----------------------------------------

for i in `seq 0 99`;do
    (
        flock -x $lock
        {
            # Critical section
            echo $i > $task_queue_file
            sleep 1
        }
        flock -u $lock
    ) {lock}>$lock_file
done
