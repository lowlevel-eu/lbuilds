#!/bin/bash

if [ ! -d packages ] || [ ! -f scripts/mklptrepo.sh ]; then
    echo "Dieses Skript muss im lbuilds-Wurzelverzeichnis ausgeführt werden"
    exit
fi

lptrepo="$1"
if [ -z lptrepo ] || [ $# != 1 ]; then
    echo "Aufruf: $0 <Pfad zum lpt-Repository>"
    exit
fi

rm -f $lptrepo/packages.i386
rm -f $lptrepo/*.tar

ln -sf $(pwd)/packages/*.tar $lptrepo/
cd $lptrepo/


for i in *.tar; do
    SIZE=$(stat -c%s "$i")

    if [[ "$i" =~ ^(.*)-lib-([^-]*)-i386\.tar$ ]]; then
        is_lib=1
    else
        is_lib=0
        [[ "$i" =~ ^(.*)-([^-]*)\.tar$ ]]

    fi

    echo $i -- ${BASH_REMATCH[1]} -- ${BASH_REMATCH[2]}

    for j in $(seq 1 5); do
        unset "info[$j]"
    done
    readarray -tO1 info < <(tar --wildcards -xOf $i packages/${BASH_REMATCH[1]}/${BASH_REMATCH[2]}/packageinfo-*)
    name=${info[1]:-"${BASH_REMATCH[1]}"}
    version=${info[2]:-"${BASH_REMATCH[2]}"}
    section=${info[3]:-bin}
    arch=${info[4]:-i386}
    desc=${info[5]:-"Keine Beschreibung"}

    cat <<EOF >> packages.i386
P ${BASH_REMATCH[1]}
D $desc
S $section
V ${BASH_REMATCH[2]}
s ${SIZE}
EOF

    if [ "$is_lib" == "0" ]; then
        mv $i ${BASH_REMATCH[1]}-$section-${BASH_REMATCH[2]}-$arch.tar
    fi

done
