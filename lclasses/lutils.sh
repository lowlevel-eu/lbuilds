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
    echo make $MAKE_OPTS "$@"
    make $MAKE_OPTS "$@"
    return $?
}

# Angegebenen Patch anwenden
lpatch() {
    lstatus "Wende Patches an:"
    while [ "$1" != "" ]; do
        lstatus "    $1"

        SUCCESS=0
        if [ -f $1 ]; then
            # Patchlevel durchprobieren
            for pl in `seq 0 4`; do

                # Komprimierte Patches handhaben
                case $1 in
                    *.gz)
                        SRC="gzip -d -c $1"
                        ;;
                    *.bz2)
                        SRC="bzip2 -d -c $1"
                        ;;
                    *)
                        SRC="cat $1"
                        ;;
                esac

                if $SRC | patch -s -p$pl -f >/dev/null; then
                    # wenn es geklappt hat, kann aufgehoert werden
                    SUCCESS=1
                    break
                fi
           done
        else
            echo Patch nicht gefunden
            return -1
        fi

        if [ $SUCCESS -eq 0 ]; then
            echo Patch anwenden fehlgeschlagen
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

        *.zip)
            unzip -qo ${fn}
            ;;
    esac
    return $?
}

