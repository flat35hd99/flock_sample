#!/bin/bash -eu

# Known issues
# - If the consumer try to acquire the lock when the walltime is close,
#   and it cannot acquire the lock immediately, the got task will be lost.

# Input ----------------------------------
lock_file=./.lock/mutex.lock
task_queue_file=./.lock/task_queue.txt

job_time_in_seconds=86400 # 24 hours
job_time_for_extra=7200 # 2 hours

simultaneous_bg_jobs_limit=10
try_limit=5

time_to_wait_for_bg_jobs_in_seconds=10
time_to_wait_for_task=5

output_date_format="--rfc-3339=seconds"
# ----------------------------------------

job_start_time_in_seconds=$(date +%s)
try_number=0

while [ $(( $(date +%s) - $job_start_time_in_seconds )) -lt $(($job_time_in_seconds - $job_time_for_extra)) ]; do
    # Check the number of background jobs and if it is less than the limit,
    # Try to get a task from the task queue
    if [ $(jobs -r | wc -l) -gt $simultaneous_bg_jobs_limit ]; then
        echo `date $output_date_format`"; Waiting for background job pool to free up"
        sleep $time_to_wait_for_bg_jobs_in_seconds
        continue
    fi

    # Check if the try limit is reached
    # If it is reached, there are no more tasks in the task queue
    if [ $try_number -gt $try_limit ]; then
        echo `date $output_date_format`"; Try limit reached"
        break
    fi
    try_number=$(( $try_number + 1 ))

    # Get task from the task queue
    task=$(
    (
        # Critical section
        # 1. Acquire mutual exclusion lock
        # 2. Dequeue a task
        # 3. Release the lock
        #=====================================
        flock -x $lock

        first_line=$(head -n 1 $task_queue_file)  
        tail -n +2 $task_queue_file > $task_queue_file.tmp
        mv $task_queue_file.tmp $task_queue_file

        flock -u $lock
        #=====================================

        # Return result to the caller
        echo -n $first_line
    ) {lock}>$lock_file)

    if [ ! -n "$task" ]; then
        echo `date $output_date_format`"; No task"
        sleep $time_to_wait_for_task
        continue
    fi

    echo `date $output_date_format`"; Got task: $task"
    # Reset try counter
    try_number=0

    # Start calculation in the background
    (
        sleep 20
        touch output/$task.txt
    ) &
done

# Wait for all background jobs to finish
echo `date $output_date_format`"; Waiting for all background jobs to finish"
wait

echo `date $output_date_format`"; Done"
