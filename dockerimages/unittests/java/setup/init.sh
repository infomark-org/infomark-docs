#!/bin/bash
set -e

# add user
adduser --uid 1901 --disabled-login --gecos 'Simple CI Runner' simple_ci_runner

cd /app/setup

# chmod -R 700 ${TEST_FILE}

mkdir /home/simple_ci_runner/java
chown simple_ci_runner:simple_ci_runner /home/simple_ci_runner/java

mkdir /home/simple_ci_runner/java/src
chown simple_ci_runner:simple_ci_runner /home/simple_ci_runner/java/src

mkdir /home/simple_ci_runner/java/lib
chown simple_ci_runner:simple_ci_runner /home/simple_ci_runner/java/lib
cp -R junit-4.12.jar 		/home/simple_ci_runner/java/lib
cp -R hamcrest-core-1.3.jar 	/home/simple_ci_runner/java/lib

#cp -R parser.jar /home/simple_ci_runner/java
#cp -R junit_xml_parser.py /home/simple_ci_runner/java
cp -R junit_xml_report_translator.py /home/simple_ci_runner/java
cp -R parse_compiler.py /home/simple_ci_runner/java

cd /home/simple_ci_runner/java/lib
chown -R simple_ci_runner:simple_ci_runner junit-4.12.jar
chown -R simple_ci_runner:simple_ci_runner hamcrest-core-1.3.jar



