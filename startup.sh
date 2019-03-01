#!/bin/bash

export PATH=$SPARK_HOME/bin:$PATH

$SPARK_HOME/sbin/start-master.sh

jupyter notebook --ip=0.0.0.0 --NotebookApp.token='' --no-browser

