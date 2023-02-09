#!/bin/bash

PREFIX_FLOCK_SAMPLE=$HOME/product/flock_sample

lock_file=$PREFIX_FLOCK_SAMPLE/.lock/mutex.lock
task_queue_file=$PREFIX_FLOCK_SAMPLE/.lock/task_queue.txt

# Append a task to the task queue
function enqueue_task() {
    task=$1
    (
        # Critical section
        # =========================
        flock -x $lock
        echo $task >> $task_queue_file
        flock -u $lock
        # =========================
    ) {lock}>$lock_file
}

# Print the head of the task queue to stdout
function dequeue_task() {
    task=$(
    (
        # Critical section
        # =========================
        flock -x $lock
        first_line=$(head -n 1 $task_queue_file)  
        tail -n +2 $task_queue_file > $task_queue_file.tmp
        mv $task_queue_file.tmp $task_queue_file
        flock -u $lock
        # =========================

        echo $first_line
    ) {lock}>$lock_file
    )
    echo $task
}
