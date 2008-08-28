#!/bin/bash

# Statusmeldung anzeigen
lstatus() {
    echo -e "\033[01;32m  * $*\033[01;37m"
}

# Warnung anzeigen
lwarn() {
    echo -e "\033[01;33m !* $*\033[01;37m"
}

# Fehlermeldung anzeigen
lerror() {
    echo -e "\033[01;31m!!* $*\033[01;37m"
}

# Make ausfuehren
lmake() {
    make $MAKE_OPTS "$@"
    return $?
}

# Angegebenen Patch anwenden
lpatch() {
    lstatus "Wende Patches an:"
    while [ "$1" != "" ]; do
        lstatus "    $1"

        if [ -f $1 ]; then
            patch -s -p0 < $1 || return -1
        else
            echo Patch nicht gefunden
            return -1
        fi
        shift
    done
}

#
lstrip() {
    strip $@
    return $?
}

# Archiv entpacken
lunpack() {
    local fn=${DISTDIR}/$1
    case $fn in
        *.tar)
            tar -xf ${fn}
            ;;

        *.tgz | *.tar.gz)
            tar -xzf ${fn}
            ;;

        *.tar.bz2)
            tar -xjf ${fn}
            ;;
    esac
    return $?
}

