#!/bin/bash

# Prueft ob Freepascal verfuegbar ist
fpc-available() {
    test -f ${ENVDIR}/pascal/units/prt0.o
    return $?
}
# Name des Compilers Compiler
fpc-fpc() {
    echo fpc
}

# Pfad zum Hostcompiler
fpc-hostfpc() {
    which -a fpc | grep -v ${ENVDIR} | head -n 1
}

# fpcmake aufrufen
fpc-fpcmake() {
    ${ENVDIR}/bin/fpcmake $*
    return $?
}

# Pfad zu den Units
fpc-unitpath() {
    echo ${ENVDIR}/pascal/units
}
