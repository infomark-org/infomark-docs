#!/bin/bash
set -e

HOME_DIR="/home/simple_ci_runner"
RESULT_DIR="/results"
DATA_DIR="/data"

SUBMISSION_FILE="$DATA_DIR/submission.zip"
TEST_FILE="$DATA_DIR/unittest.zip"

# unpack submission
cd ${HOME_DIR}/java/src
sudo -u simple_ci_runner -H unzip ${SUBMISSION_FILE} >/dev/null 2>&1

# consider the existance of a __unittest folder as attack!
if [ -d "${HOME_DIR}/java/src/__unittest" ]; then
  exit 200
fi

# unzip tests
cd ${HOME_DIR}/java
unzip ${TEST_FILE} >/dev/null 2>&1
chmod -R 555 ${HOME_DIR}/java/src/__unittest

# run unit tests
sudo -u simple_ci_runner -H ant junit > /tmp/compile.log || true
cat /tmp/compile.log

# run report translator
sudo chmod o+r /tmp/compile.log

echo "--- BEGIN --- INFOMARK -- WORKER"
PYTHONIOENCODING=UTF-8 python3 parse_compiler.py
PYTHONIOENCODING=UTF-8 python3 junit_xml_report_translator.py
echo "--- END --- INFOMARK -- WORKER"
