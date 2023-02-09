#!/bin/bash -eu

lock_file=/tmp/flock_sample.lock
text_file=/tmp/flock_sample.txt

exec {lock}<>"$lock_file"
{
    flock -x $lock
    {
        # Critical section
        echo "Hello, world!" > $text_file
        sleep 5
    }
    flock -u $lock
}
