#!/bin/bash

docker run -p 8899:8888 -p 8080:8080 -p 7077:7077 -v /Users/armin/Source/notebooks/obdexplore:/home/jupyter/notebooks hellospencer/spark23
