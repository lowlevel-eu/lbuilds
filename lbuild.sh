#!/bin/bash

source lbuild.conf
# Verzeichnis mit heruntergeladenen Dateien
export DISTDIR="`pwd`/distfiles"

# Verzeichnis mit unseren fertigen Binaerpaketen
export PACKSDIR="`pwd`/packages"

# Verzeichnis mit der Crosstoolchain
#export ENVDIR="`pwd`/env"


# In diesem Verzeichnis wird beim bauen eines lbuilds fuer jedes ein
# Verzeichnis erstellt, indem es kompiliert wird.
WORKDIR_BASE="`pwd`/work"

EXTENSION=".lbuild"

show_help() {
    echo "usage lbuilds <action> <lbuild> [arguments]"
}

absolute_path() {
    if [ "${1:0:1}" == "/" ]; then
        echo $1
    else
        echo `pwd`/$1
    fi
}

init_env() {
    PACKAGE_PATH=`absolute_path $1`
    # Voller Paketname, mit Version
    export P=`basename ${PACKAGE_PATH} ${EXTENSION}`
    # Nur Paketname ohne Version
    export PN=`expr match "${P}" '^\([^\-]*\)-.*$'`
    # Paketversion
    export PV=`expr match "${P}" '[^\-]*\-\(.*\)$'`

    # Das Arbeitsverzeichnis wird nach Kategorien und Paketen unterteilt
    export WORKDIR="${WORKDIR_BASE}/${P}"
    # Quellcodeverzeichnis fuer das Packet
    export S="${WORKDIR}/src"
    # Verzeichnis fuer temporaere Daten
    export T="${WORKDIR}/tmp"
    # Virtuelles Rootverzeichnis fuer das Paket
    export D="${WORKDIR}/root"
    # Verzeichnis in das das Programm installiert wird (hier wird das virtuelle
    # Root-Verzeichnis reinkopiert)
    export R="/packages/${PN}/${PV}/"
    # Das Verzeichnis mit Dateien zu diesem Paket
    export F="`dirname ${PACKAGE_PATH}`/files"

    source $PACKAGE_PATH
}


# Kopiert env/ in das Arbeitsverzeichnis
internal_prepare_env() {
    export ENVDIR="${WORKDIR}/env"
    cp -rL env ${WORKDIR}/env
    export PATH="${WORKDIR}/env/bin:$PATH"

    # Buildtime-Dependencies abarbeiten
    for dep in ${BUILD_DEPEND}; do
        pack="${PACKSDIR}/${dep:1}.tar"
        tar -C "${WORKDIR}/env" -xf "${pack}"
    done

    cp -rf ${WORKDIR}/env/packages/*/*/* ${WORKDIR}/env/
}

internal_prepare_dirs() {
    mkdir -p ${WORKDIR}
    mkdir -p ${S}
    mkdir -p ${T}
    mkdir -p ${D}

    internal_prepare_env

}

#
# Interne Hilfsfunktionen
#

# Ruft die mit dem ersten Parameter angegebene Funktion auf falls sie
# existiert, sonst die 2.
call_if_exists() {
    if declare -f "$1" > /dev/null ; then
        $1
        return $?
    elif [ -n $2 ]; then
        $2
        return $?
    fi
    return 0
}


#
# Globale Hilfsfunktionen
#

# Build ausfindig machen
tc-build() {
    echo $CBUILD
}

# Host ausfindig machen
tc-host() {
    echo $CHOST
}

tc-cc() {
    echo $CHOST-gcc
}

# Verzeichnis mit libs
tc-libdir() {
    echo ${ENVDIR}/lib
}

# Verzeichnis mit includes
tc-incdir() {
    echo ${ENVDIR}/include
}


# Prozess Abbrechen
die() {
    echo "$1"
    exit -1
}

# Make ausfuehren
lmake() {
    make $MAKE_OPTS "$@"
    return $?
}

# Angegebenen Patch anwenden
lpatch() {
    while [ "$1" != "" ]; do
        echo Wende Patch $1 an

        if [ -f $1 ]; then
            patch -p0 < $1 || return -1
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
unpack() {
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
 

#
# Standardaktionen fuer nicht definierte Funktionen
#

# Quellcode entpacken
src_unpack_default() {
    local u
    for u in $SRC_URI; do
        unpack "${DISTDIR}/`basename ${u}`"
   done
}



#
# Interne Aliase fuer die einzelnen Aktionen mit den Paketen
#

# Alle Reste von Bauen eines Paketes loeschen
internal_pkg_clean() {
    rm -fr "${WORKDIR}"
}

# Alle Dateien fuer ein Paket herunterladen
internal_pkg_fetch_files() {
    local u
    for u in $SRC_URI; do
        local fn="${DISTDIR}/`basename ${u}`"
        # Wenn die Datei schon exisitert, muss sie nicht erneut geladen werden
        if [ -f "${fn}" ]; then
            continue
        fi

        wget -O ${fn} ${u}
        if [ $? -ne 0 ]; then
            return -1
        fi
    done
    return 0
}

# Quellcode entpacken
internal_src_unpack() {
    cd ${S}
    call_if_exists src_unpack src_unpack_default
}

# Quellcode kompilieren
internal_src_compile() {
    cd ${S}
    call_if_exists src_compile
}

# Quellcode in virtuellen Root installieren
internal_src_install() {
    cd ${S}
    call_if_exists src_install
}

# Paket erstellen
internal_pack() {
    cd ${D}
    tar -cf "${PACKSDIR}/${P}.tar" *
}


if [ $# -le 1 ]; then
    show_help
    exit -1
fi

LBUILD_PATH=$2
[ -f $LBUILD_PATH ] || die "lbuild $2 not found"
init_env $LBUILD_PATH

case $1 in
    unpack)
        [ $# -ne 2 ] && show_help && exit -1

        internal_pkg_clean
        internal_prepare_dirs
        internal_pkg_fetch_files
        internal_src_unpack

        touch "${WORKDIR}/.unpacked"
        ;;

    compile)
        [ $# -ne 2 ] && show_help && exit -1

        [ -f "${WORKDIR}/.unpacked" ] || die "lbuild not unpacked"

        internal_src_compile

        touch "${WORKDIR}/.compiled"
        ;;

    install)
        [ $# -ne 2 ] && show_help && exit -1

        [ -f "${WORKDIR}/.compiled" ] || die "lbuild not compiled"

        internal_src_install

        touch "${WORKDIR}/.installed"
        ;;

    pack)
        [ $# -ne 2 ] && show_help && exit -1

        [ -f "${WORKDIR}/.installed" ] || die "lbuild not installed"

        internal_pack

        ;;

    clean)
        [ $# -ne 2 ] && show_help && exit -1

        internal_pkg_clean
        ;;

    build)
        [ $# -ne 2 ] && show_help && exit -1

        internal_pkg_clean || die "cleaning failed"
        internal_prepare_dirs || die "preparing dirs failed"
        internal_pkg_fetch_files || die "fetching files failed"
        internal_src_unpack || die "unpacking source failed"
        internal_src_compile || die "compiling source failed"
        internal_src_install || die "installing source failed"
        internal_pack || die "packing failed"
        internal_pkg_clean || die "cleaning failed"
        ;;

    *)
        show_help
        ;;
esac
exit 0
