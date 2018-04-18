#!/usr/bin/env bash

# pass in the PORT for dev as $1
# pass in the sname for dev as 2!
# ex: ./scripts/dev/sh 4000 foo

rm -rf /tmp/sync_dir/*
PORT=$1 iex --sname $2 --cookie wowwowow -S mix phx.server
