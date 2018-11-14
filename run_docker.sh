#!/bin/bash

if [[ $* == *-d* ]]
then
    DAEMONIZE="-d"
else
    DAEMONIZE=""
fi

docker run $DAEMONIZE -p 8899:8888 -p 8080:8080 -p 7077:7077 -v /Users/armin.wasicek/Source/notebooks:/home/jupyter/notebooks hellospencer/jupyterspark23
