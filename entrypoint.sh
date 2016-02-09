#!/bin/bash

if [ -z ${HOST+x} ]; then
  export LIBPROCESS_IP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)
else
  export LIBPROCESS_IP=$HOST
fi

/apps/livy/bin/livy-server $@