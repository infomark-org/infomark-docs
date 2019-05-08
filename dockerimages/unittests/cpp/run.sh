#!/usr/bin/env sh

#
cd /src
unzip /data/submission.zip
unzip /data/unittest.zip
chmod x+r /src/run.sh
echo "--- BEGIN --- INFOMARK -- WORKER"
/src/run.sh
echo "--- END --- INFOMARK -- WORKER"