#!/bin/bash

# Target des Host-GCCs suchen
HOST_GCC_TARGET="`LC_ALL=C gcc -v 2>&1 | grep Target: | awk '{print $2}'`"

source lbuild.conf

# Verzeichnis mit heruntergeladenen Dateien
export DISTDIR="`pwd`/distfiles"

# Verzeichnis mit unseren fertigen Binaerpaketen
export PACKSDIR="`pwd`/packages"

# Verzeichnis mit den lclasses
export CLASSDIR="`pwd`/lclasses"

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
    export PV=`expr match "${P}" '[^0-9]*\-\([0-9].*\)$'`

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
    # Das Verzeichnis mit den Patches
    export PD="`dirname ${PACKAGE_PATH}`/patches"


    export ENVDIR="${WORKDIR}/env"
    export PATH="${WORKDIR}/env/bin:$PATH"
    export LDFLAGS="-L${WORKDIR}/env/lib"
    export CPPFLAGS="-I${WORKDIR}/env/include"

    source $PACKAGE_PATH
}


# Kopiert env/ in das Arbeitsverzeichnis
internal_prepare_env() {
    lstatus "Bereite Umgebung zum Bauen vor..."
    cp -rL env ${WORKDIR}/env
    if [ "${BUILD_DEPEND}" == "" ]; then
        return
    fi

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

    # Patches und series verlinken
    if [ -d ${PD} ]; then
        ln -s ${PD} ${S}/patches
    fi

    internal_prepare_env
    return 0
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

# Prueft ob das angegebene Feature aktiviert ist
has_feature() {
    if echo ${FEATURES} | grep -s $1 > /dev/null; then
        return 0
    fi

    return 1
}

#
# Globale Hilfsfunktionen
#

include() {
    classfile="${CLASSDIR}/$1.sh"
    test -f "${classfile}" || die "lclass $1 nicht gefunden"
    source "${classfile}"
}

# Prozess Abbrechen
die() {
    echo -e "\033[01;31m*** Abgebrochen: $* ***\033[01;37m"
    exit -1
}


#
# Standardaktionen fuer nicht definierte Funktionen
#

# Quellcode entpacken
src_unpack_default() {
    include lutils
    local u
    for u in $SRC_URI; do
        lunpack "`basename ${u}`"
   done
}


# LBuild-Tools
include lutils


#
# Interne Aliase fuer die einzelnen Aktionen mit den Paketen
#

# Alle Reste von Bauen eines Paketes loeschen
internal_pkg_clean() {
    lstatus "Raeume auf..."
    rm -fr "${WORKDIR}"
}

# Alle Dateien fuer ein Paket herunterladen
internal_pkg_fetch_files() {
    local u
    lstatus "Lade Dateien herunter:"
    for u in $SRC_URI; do
        local fn="${DISTDIR}/`basename ${u}`"
        # Wenn die Datei schon exisitert, muss sie nicht erneut geladen werden
        if [ -f "${fn}" ]; then
            continue
        fi

        lstatus "    ${u}"

        wget -O ${fn} ${u}
        if [ $? -ne 0 ]; then
            die "Das Herunterladen ist fehlgeschlagen"
        fi
    done
    return 0
}

# Quellcode entpacken
internal_src_unpack() {
    cd ${S}
    lstatus "Entpacke Quelldateien..."
    call_if_exists src_unpack src_unpack_default

    # Jetzt koennen wir allfaellige Patches anwenden
    if [ -f "${S}/patches/series" ]; then
        cd "${S}" && quilt push -a -q
    fi
}

# Quellcode konfigurieren
internal_src_configure() {
    cd ${S}
    lstatus "Konfiguriere Quellcode..."
    call_if_exists src_configure
}

# Quellcode kompilieren
internal_src_compile() {
    cd ${S}
    lstatus "Kompiliere Quellcode..."
    call_if_exists src_compile
}

# Quellcode fixen
internal_src_fix() {
    cd ${S}
    lstatus "Starte Umgebung zur Fehlerkorrektur, fertigstellen mit exit"
    bash
}

# Quellcode in virtuellen Root installieren
internal_src_install() {
    cd ${S}
    lstatus "Bereite Paketinhalt vor"
    call_if_exists src_install

    lstatus "Erstelle oder erweitere postinstall-Skript"
    PIS="${D}/${R}/postinstall-bin"
    test -f "$PIS" || echo "#!file:/apps/sh" >> "$PIS"
    for b in ${D}/${R}/bin/*; do
        test -f "$b" || continue
        bin="`basename $b`"
        echo "lpt cfg-addbin file:/packages/${PN}/${PV}/bin/$bin $bin" >> "$PIS"
        lstatus "    addbin $bin"
    done
    for l in ${D}/${R}/lib/*; do
        test -f "$l" || continue
        lib="`basename $l`"
        echo "lpt cfg-addlib file:/packages/${PN}/${PV}/lib/$lib $lib" >> "$PIS"
        lstatus "    addlib $lib"
    done
    for i in ${D}/${R}/include/*; do
        test -e "$i" || continue
        hdr="`basename $i`"
        echo "lpt cfg-addinc file:/packages/${PN}/${PV}/include/$hdr $hdr" \
            >> "$PIS"
        lstatus "    addinc $hdr"
    done
    for i in ${D}/${R}/doc/*; do
        test -e "$i" || continue
        doc="`basename $i`"
        echo "lpt cfg-adddoc file:/packages/${PN}/${PV}/doc/$doc $doc" \
            >> "$PIS"
        lstatus "    adddoc $doc"
    done


    if has_feature "nostrip"; then
        lstatus "Ueberspringe das Strippen der Binaries"
    else
        lstatus "Strippe Binaries:"
        for b in ${D}/${R}/bin/*; do
            test -f "$b" || break
            lstatus "    strip $b"
            lstrip "$b"
        done
    fi
}

# Paket erstellen
internal_pack() {
    cd ${D}
    lstatus "Erstelle Paket..."
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

    configure)
        [ $# -ne 2 ] && show_help && exit -1

        [ -f "${WORKDIR}/.unpacked" ] || die "lbuild not unpacked"

        internal_src_configure

        touch "${WORKDIR}/.configured"
        ;;

    compile)
        [ $# -ne 2 ] && show_help && exit -1

        [ -f "${WORKDIR}/.configured" ] || die "lbuild not configured"

        internal_src_compile

        touch "${WORKDIR}/.compiled"
        ;;

    fix)
        [ $# -ne 2 ] && show_help && exit -1

        internal_src_fix
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
        internal_src_configure || die "configuring failed"
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
