#!/bin/bash

# Build ausfindig machen
tc-build() {
    echo $HOST_GCC_TARGET
}

# Host ausfindig machen
tc-host() {
    echo $TARGET_GCC_TARGET
}

tc-cc() {
    echo `tc-host`-gcc
}

tc-cxx() {
    echo `tc-host`-g++
}

# Verzeichnis mit libs
tc-libdir() {
    echo ${ENVDIR}/lib
}

# Verzeichnis mit includes
tc-incdir() {
    echo ${ENVDIR}/include
}

