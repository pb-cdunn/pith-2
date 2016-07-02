#!/bin/bash

set_globals() {
    # required globals:
    g_name="hgapg"

        mobs_exe=$MOBS_EXE;
        if [[ -z "$mobs_exe" ]]; then
            mobs_exe="$g_progdir/../../../../../../../../build/3.x/mobs";
        fi
    if [[ -e "mobs.mk" ]]; then
        eval $(cat mobs.mk)
    else
        allvars=$($mobs_exe -p "$g_name")
        #echo $allvars >| mobs.mk  # THIS LINE SHOULD NOT BE IN PROD CODE!!!
        eval $allvars
    fi

        g_make_exe=$MOBS_make__make_exe

        eval g_srcdir="\$MOBS_${g_name}__src_dir"
        eval g_outdir="\$MOBS_${g_name}__output_dir"
        eval g_installbuild_dir="\$MOBS_${g_name}__install_dir"
        eval g_installunittest_dir="\$MOBS_${g_name}__installunittest_dir"

        eval g_binwrap_build_dir="\$MOBS_${g_name}__install_binwrapbuild_dir"

        # For binwrap-build directory:
        build_topdir=$MOBS_global__build_topdir;

        g_builddir="$g_outdir"/build
        mkdir -p "$g_builddir"
}

configure() {
    cat << EOF > $g_builddir/makefile
#GOROOT=/home/UNIXHOME/cdunn/repo/pb/smrtanalysis-client/smrtanalysis/_output/modulebuilds/bioinformatics/ext/pi/golang/_output/install/go
GOROOT=$MOBS_golang__install_dir/go
PATH:=\${GOROOT}/bin:\${PATH}
GOPATH:=\$(shell pwd)
export GOROOT
export GOPATH
export PATH

install:
	mkdir -p src
	ln -sf $g_srcdir src/
	go install hgapg/mains/hello
EOF
}

clean_cmd() {
    # For now, clean original srcdir too, since people might still have objs there.
    cmd="$g_make_exe -C $g_srcdir clean"
    $cmd
    cmd="rm -rf $g_outdir"
    $cmd
}

build_cmd() {
    configure
    cmd="$g_make_exe -C $g_builddir -j4"
    $cmd
}

install_cmd() {
    echo "nothing to install"
    #mkdir -p "$g_installbuild_dir/bin"
    #mkdir -p "$g_installbuild_dir/lib"
    #cmd="$g_make_exe -C $g_builddir install"
    #$cmd
}

unittest_cmd() {
    echo "no unittests"
}

# ---- main

set -ex

g_prog=$(basename $0);
g_progdir=$(dirname $0);

set_globals;

for target in "$@"; do
    eval "$target"_cmd
done
