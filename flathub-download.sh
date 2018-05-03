#!/bin/bash

STATEDIR=$1

make org.freedesktop.Sdk.json
flatpak-builder --download-only --no-shallow-clone --allow-missing-runtimes --state-dir=$STATEDIR $STATEDIR/.builddir org.freedesktop.Sdk.json
