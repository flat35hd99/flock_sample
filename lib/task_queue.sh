#!/bin/bash

# Append a task to the task queue
function enqueue_task() {
    lock_file=$PREFIX_FLOCK_SAMPLE/.lock/task_mutex.lock
    queue_file=$PREFIX_FLOCK_SAMPLE/.lock/task_queue.txt

    task=$1
    (
        # Critical section
        # =========================
        flock -x $lock
        echo $task >> $queue_file
        flock -u $lock
        # =========================
    ) {lock}>$lock_file
}

# Print the head of the task queue to stdout
function dequeue_task() {
    lock_file=$PREFIX_FLOCK_SAMPLE/.lock/task_mutex.lock
    queue_file=$PREFIX_FLOCK_SAMPLE/.lock/task_queue.txt

    task=$(
    (
        # Critical section
        # =========================
        flock -x $lock
        first_line=$(head -n 1 $queue_file)  
        tail -n +2 $queue_file > $queue_file.tmp
        mv $queue_file.tmp $queue_file
        flock -u $lock
        # =========================

        echo -n $first_line
    ) {lock}>$lock_file
    )
    echo -n $task
}
