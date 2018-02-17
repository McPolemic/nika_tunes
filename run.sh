#!/bin/sh
docker run -dt --net=host --device=/dev/input/event0 --restart always --name=nika_tunes nika_tunes
