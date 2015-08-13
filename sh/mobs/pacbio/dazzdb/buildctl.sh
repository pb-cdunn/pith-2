#!/bin/bash

set_globals() {
    # required globals:
    g_name="dazzdb"

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
        g_gcc_exe=$MOBS_gcc__gcc_exe
        g_gxx_exe=$MOBS_gcc__gxx_exe
        g_ar_exe=$MOBS_gcc__ar_exe
        #g_python_exe=$MOBS_python__python_exe

        eval g_srcdir_abs="\$MOBS_${g_name}__src_dir"
        eval g_outdir_abs="\$MOBS_${g_name}__output_dir"
        eval g_outdir="\$MOBS_${g_name}__output_dir"
        eval g_installbuild_dir_abs="\$MOBS_${g_name}__install_dir"
        eval g_installbuild_dir="\$MOBS_${g_name}__install_dir"
        eval g_installunittest_dir_abs="\$MOBS_${g_name}__installunittest_dir"
        eval g_installunittest_dir="\$MOBS_${g_name}__installunittest_dir"

        eval g_binwrap_build_dir="\$MOBS_${g_name}__install_binwrapbuild_dir"

        # For binwrap-build directory:
        build_topdir=$MOBS_global__build_topdir;
}

clean_cmd() {
    cmd="$g_make_exe -C $g_srcdir_abs clean"
    $cmd
}

build_cmd() {
    cmd="$g_make_exe -C $g_srcdir_abs -j4 CC=$g_gcc_exe AR=$g_ar_exe"
    $cmd
}

install_cmd() {
    mkdir -p "$g_installbuild_dir/bin"
    cmd="$g_make_exe -C $g_srcdir_abs install PREFIX=$g_installbuild_dir"
    $cmd
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
