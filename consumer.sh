#!/bin/bash -eu

lock_file=/tmp/flock_sample.lock
text_file=/tmp/flock_sample.txt

exec {lock}<>"$lock_file"
{
    flock -x $lock
    {
        # Critical section
        cat $text_file
    }
    flock -u $lock
}
