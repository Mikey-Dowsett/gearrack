#!/usr/bin/env sh
# Wrapper to run flutter from within the Zed flatpak environment.
# The flatpak injects LD_LIBRARY_PATH with an incompatible libselinux,
# which breaks the Linux linker for Flutter builds.
# This script drops those variables and adds flutter to PATH.
exec env \
    PATH="/home/mikey/flutter/bin:${PATH}" \
    LD_LIBRARY_PATH="" \
    LD_PRELOAD="" \
    flutter "$@"
