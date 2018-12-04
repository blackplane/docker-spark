#!/bin/bash

DOCKERIMAGE=hellospencer/jupyterspark23
JUPYTERPORT=8899
NOTEBOOKDIR=/Users/armin.wasicek/Source/notebooks
NOTEBOOKROOT=/home/jupyter/notebooks
DATADIR=/Users/armin.wasicek/Data
OTHERNOTEBOOK=/Users/armin.wasicek/git/mlanalysis/projects/CryptoDetection

if [[ $* == *-d* ]]
then
    DAEMONIZE="-d"
else
    DAEMONIZE=""
fi

docker run $DAEMONIZE -p $JUPYTERPORT:8888 -p 8080:8080 -p 7077:7077 -v $NOTEBOOKDIR:$NOTEBOOKROOT -v $OTHERNOTEBOOK:$NOTEBOOKROOT/other -v $DATADIR:/home/jupyter/notebooks/Data $DOCKERIMAGE

