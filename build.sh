#!/bin/bash

ARCH=$1
REPO=$2
EXPORT_ARGS=$3
FB_ARGS=$4
SUBJECT=${5:-"org.freedesktop.Platform.GL.nvidia `git rev-parse HEAD`"}

make ARCH="${ARCH}" REPO="${REPO}" EXPORT_ARGS="${EXPORT_ARGS}" FB_ARGS="${FB_ARGS}"
