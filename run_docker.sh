#!/bin/bash

DOCKERIMAGE=hellospencer/jupyterspark23
JUPYTERPORT=8899
NOTEBOOKDIR=/Users/armin.wasicek/Source/notebooks
DATADIR=/Users/armin.wasicek/Data

if [[ $* == *-d* ]]
then
    DAEMONIZE="-d"
else
    DAEMONIZE=""
fi

docker run $DAEMONIZE -p $JUPYTERPORT:8888 -p 8080:8080 -p 7077:7077 -v $NOTEBOOKDIR:/home/jupyter/notebooks -v $DATADIR:/home/jupyter/notebooks/Data $DOCKERIMAGE

