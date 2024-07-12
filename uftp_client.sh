#!/bin/bash

echo "" > /opt/uftp/uftp_client.log

if ! pgrep -lf uftpd > /dev/null; then
    /opt/uftp/uftp/uftpd -p 1044 -S /opt/uftp/uftp_server.conf -E -D /opt/virt_data/images -M 224.0.0.30 -L /opt/uftp/uftp_client.log
    echo "Started."
else
    echo "Already running."
fi
