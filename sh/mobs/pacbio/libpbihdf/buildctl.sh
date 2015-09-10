#!/bin/bash

# ---- required subroutines
set_globals() {
    # required globals:
    g_name="libpbihdf"

	mobs_exe=$MOBS_EXE;
	if [[ -z "$mobs_exe" ]]; then
	    mobs_exe="$g_progdir/../../../../../build/3.x/mobs";
	fi
	eval $($mobs_exe -p "$g_name")

	g_make_exe=$MOBS_make__make_exe

	g_gxx_exe=$MOBS_gcc__gxx_exe
	g_ar_exe=$MOBS_gcc__ar_exe

    g_gcc_runtime_libdir_abs=$MOBS_gcc__runtimelib_dir
	g_boost_rootdir_abs=$MOBS_boost__root_dir
	g_zlib_rootdir_abs=$MOBS_zlib__install_dir
	g_hdf5_rootdir_abs=$MOBS_hdf5__install_dir
	g_htslib_rootdir_abs=$MOBS_htslib__install_dir
	g_pbbam_rootdir_abs=$MOBS_pbbam__install_dir
	g_libpbdata_rootdir_abs=$MOBS_libpbdata__install_dir


	eval g_srcdir_abs="\$MOBS_${g_name}__src_dir"
	eval g_outdir_abs="\$MOBS_${g_name}__output_dir"
	eval g_outdir="\$MOBS_${g_name}__output_dir"
	eval g_installbuild_dir_abs="\$MOBS_${g_name}__install_dir"
	eval g_installbuild_dir="\$MOBS_${g_name}__install_dir"

    g_builddir="$g_outdir/build"
    mkdir -p "$g_builddir"

    g_conf_cmd='
	"$g_srcdir_abs"/../configure.py
    '
    g_conf_cmd=$(echo $g_conf_cmd)
}

# ---- build targets


clean() {
    echo "Running $g_name 'clean' target..."
    ${g_make_exe} -C "${g_srcdir_abs}" clean
    rm -rf "${g_outdir}"
}
cleanall() {
    echo "Running $g_name 'cleanall' target..."
    clean;
}
build() {
    echo "Running $g_name 'build' target..."

    # Create dependency links
    rm -rf "${g_outdir}/deplinks"
    mkdir -p "${g_outdir}/deplinks"

    ln -s "$g_boost_rootdir_abs" "${g_outdir}/deplinks/boost"
    ln -s "$g_hdf5_rootdir_abs" "${g_outdir}/deplinks/hdf5"
    ln -s "$g_zlib_rootdir_abs" "${g_outdir}/deplinks/zlib"
    ln -s "$g_htslib_rootdir_abs" "${g_outdir}/deplinks/htslib"
    ln -s "$g_pbbam_rootdir_abs" "${g_outdir}/deplinks/pbbam"
    ln -s "$g_libpbdata_rootdir_abs" "${g_outdir}/deplinks/libpbdata"

	shared_flag="SHARED_LIB=true"
set -x
    # build
    cd "$g_builddir"
    ln -sf "$g_srcdir_abs"/makefile makefile
    eval "$g_conf_cmd" \
        CXX="${g_gxx_exe}" \
        AR="${g_ar_exe}" \
	"${shared_flag}" \
	BOOST_INC="${g_outdir}/deplinks/boost/include" \
	HTSLIB_INC="${g_outdir}/deplinks/htslib/include" \
	PBBAM_INC="${g_outdir}/deplinks/pbbam/include" \
	LIBPBDATA_INC="${g_outdir}/deplinks/libpbdata/include" \
	HDF5_INC="${g_outdir}/deplinks/hdf5/include" \
    GCC_LIB=\"$g_gcc_runtime_libdir_abs\" \
	HDF5_LIB="${g_outdir}/deplinks/hdf5/lib" \
	ZLIB_LIB="${g_outdir}/deplinks/zlib/lib" \
	HTSLIB_LIB="${g_outdir}/deplinks/htslib/lib" \
	PBBAM_LIB="${g_outdir}/deplinks/pbbam/lib" \
	LIBPBDATA_LIB="${g_outdir}/deplinks/libpbdata/lib" \
	${1+"$@"}

    eval "$g_make_exe" -C "$g_builddir" \
        -j4 \
        libpbihdf.so	
set +x
}
install_build() {
    if ! $opt_no_sub_targets; then
	build;
    fi

    echo "Running $g_name 'install-build' target..."

    # clean install dir
    rm -rf "$g_installbuild_dir";
    mkdir -p "$g_installbuild_dir";

    # install libs
    mkdir "$g_installbuild_dir/lib"
	cp -a "${g_builddir}/${g_name}.so"  "$g_installbuild_dir/lib"

    # install includes
    mkdir -p "$g_installbuild_dir/include"
    for i in . ; do
	mkdir -p "$g_installbuild_dir/include/hdf/$i"
	cp -a "${g_srcdir_abs}/$i"/*.hpp "$g_installbuild_dir/include/hdf/$i"
    done

}
install_prod() {
    echo "Running $g_name 'install-prod' target..."
}
publish_build() {
    if ! $opt_no_sub_targets; then
	install_build;
    fi

    echo "Running $g_name 'publish-build' target..."

}
publish_prod() {
    if ! $opt_no_sub_targets; then
	install_prod;
    fi
    echo "Running $g_name 'cleanall' target..."

}


# ---- End of Module-specific code
# Common code from here on out, do not modify...

# ---- error handling
set -o errexit;
set -o posix;
set -o pipefail;
set -o errtrace;
unexpected_error() {
    local errstat=$?
    echo "${g_prog:-$(basename $0)}: Error! Encountered unexpected error at 'line $(caller)', bailing out..." 1>&2
    exit $errstat;
}
trap unexpected_error ERR;


g_prog=$(basename $0);
g_progdir=$(dirname $0);

# ---- usage

usage() {
  local exitstat=2;
  if [[ ! -z "$2" ]] ; then
      exitstat=$2;
  fi

  # Only redirect to stderr on non-zero exit status
  if [[ $exitstat -ne 0 ]] ; then
      exec 1>&2;
  fi

  if [[ ! -z "$1" ]] ; then
      echo "$g_prog: Error! $1" 1>&2;
  fi

  echo "Usage: $g_prog [--help] \\"
#  echo "              -t|--target buildtarget";
#  echo "         -t|--target     -- chef target to build (e.g. 'cookbookname::build')";
  echo "         --help          -- print this usage";
  echo "";

  # bash only:
  if [[ $exitstat -ne 0 ]] ; then
      echo "  at: $(caller)";
  fi
  exit $exitstat;
}

# ---- argument parsing

# Save off the original args, use as "${g_origargs[@]}" (with double quotes)
declare -a g_origargs;
g_origargs=( ${1+"$@"} )

opt_target_exist_check=false;
opt_no_sub_targets=false;
opt_process_all_deps=false;
opt_mobs=false;
opt_shared=false;
declare -a opt_additional_options;
declare -a opt_targets;
while [[ $# != 0 ]]; do
    opt="$1"; shift;
    case "$opt" in
	# Flag with no argument example:
	#   --flag|--fla|--fl|--f)
	#     opt_flag=true;;
	# Option with argument example:
	#   --arg|--ar|--a)
	#     [[ $# -eq 0 ]] && usage;
	#     opt_somearg=$1; shift;;
	-e|--exists|--exist-check|--target-exist-check) opt_target_exist_check=true;;
	-s|--no-sub|--no-subs|--no-sub-targets|--single) opt_no_sub_targets=true;;
	-d|--deps|--process-all-deps|--all-deps|-all) opt_process_all_deps=true;;
	--mobs) opt_mobs=true;;
	--shared) opt_shared=true;;
	-o) 
	    [[ $# -eq 0 ]] && usage;
	    opt_additional_options=( "${opt_additional_options[@]}" "$1" );
	    shift;;
	-h|-help|--help|--hel|--he|--h) usage "" 0;;
	--*) opt_targets=( "${opt_targets[@]}" "$opt" );;
	-*) usage "Unrecognized option: $opt";;
	*)  usage "Extra trailing arguments: $opt $@";;
    esac
done

# ---- error functions
merror() {
    echo "$g_prog: Error! ""$@" 1>&2;
    exit 1;
}
minterror() {
    echo "$g_prog: Internal Error! ""$@" 1>&2;
    exit 1;
}
mwarn() {
    echo "$g_prog: Warning! ""$@" 1>&2;
}

# ---- globals

# ---- subroutines

munge_target() {
    local target=$1; shift;
    local mtarget=$target;
    
    mtarget=${mtarget#--}
    mtarget=${mtarget//-/_}
    echo "$mtarget"
}

# ---- main

set_globals;

warnings=false;
for target in "${opt_targets[@]}"; do
    mtarget=$(munge_target "$target");
    if ! declare -f -F "$mtarget" > /dev/null; then
	if $opt_strict; then
	    mwarn "target '$target' does not exist"
	    warnings=true;
	else
	    echo "$g_prog: target '$target' does not exist"
	fi
    fi
done
if $warnings; then
    merror "Detected warnings, bailing out..."
fi	

if ! $opt_target_exist_check; then
    for target in "${opt_targets[@]}"; do
	mtarget=$(munge_target "$target");
	eval "$mtarget" "${opt_additional_options[@]}"
    done
fi

exit 0;
