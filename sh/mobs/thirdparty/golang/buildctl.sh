#!/bin/bash

set_globals() {
    # required globals:
    g_name="golang"

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
SRCDIR=$g_srcdir
TARBALL=$g_srcdir/go1.6.2.linux-amd64.tar.gz
ROOT=/scratch/mobs/golang/go1.6.2
SYMROOT=$g_installbuild_dir

install:
	umask 000; mkdir -p \${ROOT}
	time tar -C \${ROOT} -xvzf \${TARBALL}
	chmod -R a+w \${ROOT}
	ln -sf \${ROOT}/go \${SYMROOT}/go
EOF
}

clean_cmd() {
    local cmd="rm -rf $g_outdir"
    $cmd
}

build_cmd() {
    echo "nothing to build"
}

install_cmd() {
    configure
    local cmd="$g_make_exe -C $g_builddir install"
    $cmd
}

unittest_cmd() {
    local cmd
    cmd="$g_installbuild_dir/go/bin/go env"
    $cmd
    local cmd="$g_installbuild_dir/go/bin/go version"
    $cmd
}

# ---- main

set -ex

g_prog=$(basename $0);
g_progdir=$(dirname $0);

set_globals;

for target in "$@"; do
    eval "$target"_cmd
done
