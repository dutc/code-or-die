#!/bin/bash

db_dir=${1:?usage: $0 DATABASE_DIR}
logs_dir=${2:-$db_dir/logs}

if [[ ! -e "$db_dir" ]]; then
    echo "Database directory $db_dir does not exist"
    exit 1
fi

if [[ ! -e "$logs_dir" ]]; then
    echo "Database logs directory $logs_dir does not exist"
    exit 1
fi

shutdown() {
    pg_ctl -D $db_dir stop 2>/dev/null
}

trap "trap - SIGTERM && shutdown && exit 1 && kill -- -$$" SIGINT SIGTERM exit

pg_ctl -D $db_dir -l $logs_dir/"$(date +%Y-%m-%d.%H%M%S).log" start
if [[ $? != 0 ]]; then
    echo "failed to start"
    exit $?
fi

ppid=$$

while true; do
    echo "$(date): postgresql running with PPID $ppid"
    sleep 60
done
