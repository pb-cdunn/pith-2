#!/bin/bash

# ---- required subroutines
set_globals() {
    # required globals:
    g_name="libblasr"

	mobs_exe=$MOBS_EXE;
	if [[ -z "$mobs_exe" ]]; then
	    mobs_exe="$g_progdir/../../../../../build/3.x/mobs";
	fi
	eval $($mobs_exe -p "$g_name")

	g_make_exe=$MOBS_make__make_exe

	g_gxx_exe=$MOBS_gcc__gxx_exe
	g_ar_exe=$MOBS_gcc__ar_exe

	g_git_exe=$MOBS_git__git_exe

	g_boost_rootdir_abs=$MOBS_boost__root_dir
	g_zlib_rootdir_abs=$MOBS_zlib__install_dir
	g_hdf5_rootdir_abs=$MOBS_hdf5__install_dir
	g_htslib_rootdir_abs=$MOBS_htslib__install_dir
	g_pbbam_rootdir_abs=$MOBS_pbbam__install_dir
	g_libpbdata_rootdir_abs=$MOBS_libpbdata__install_dir
	g_libpbihdf_rootdir_abs=$MOBS_libpbihdf__install_dir

	# For unittest:
	g_gtest_rootdir_abs=$MOBS_gtest__root_dir
	

	eval g_srcdir_abs="\$MOBS_${g_name}__src_dir"
	eval g_outdir_abs="\$MOBS_${g_name}__output_dir"
	eval g_outdir="\$MOBS_${g_name}__output_dir"
	eval g_installbuild_dir_abs="\$MOBS_${g_name}__install_dir"
	eval g_installbuild_dir="\$MOBS_${g_name}__install_dir"
	eval g_installunittest_dir_abs="\$MOBS_${g_name}__installunittest_dir"
	eval g_installunittest_dir="\$MOBS_${g_name}__installunittest_dir"

    #TODO(CD): Build outside source tree.
	g_git_build_topdir="$g_srcdir_abs"
	g_git_build_srcdir="$g_git_build_topdir"
    g_git_unittest_srcdir="$g_git_build_srcdir/../unittest"
    g_git_unittest_outdir="$g_git_unittest_srcdir/_output"
    g_git_unittest_makefile="$g_git_unittest_srcdir/Makefile"

    g_make_cmd='
        ${g_make_exe} -C "$g_git_build_srcdir"
    '
    g_make_cmd=$(echo $g_make_cmd)

    g_conf_cmd='
	"$g_git_build_srcdir"/../configure.py
    '
    g_conf_cmd=$(echo $g_conf_cmd)

    g_unittest_make_cmd='
        ${g_make_exe} -C "$g_git_unittest_srcdir"
    '
    g_unittest_make_cmd=$(echo $g_unittest_make_cmd)
}

# ---- build targets

clean_unittest() {
    if [[ -e "$g_git_unittest_makefile" ]] ; then
	echo "Running $g_name 'clean-unittest' target..."
	eval "$g_unittest_make_cmd" \
	    OUTDIR="$g_git_unittest_outdir" \
  	         ${1+"$@"} clean
    fi
}
clean_build() {
    echo "Running $g_name 'clean-build' target..."
    # Clean the build artifacts
    # NOTE: don't need HDF5_INC/LIB for clean, supply /dev/null to inhibit
    #       errors
    #if [[ -e "$g_git_build_srcdir/makefile" ]] ; then
    #    eval "$g_make_cmd" clean \
    #    COMMON_NO_THIRD_PARTY_REQD=true \
    #    ${1+"$@"}
    #fi
    # Remove the _output directory
    rm -rf "${g_outdir}"
}
clean() {
    clean_unittest;
    clean_build;
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
    ln -s "$g_libpbihdf_rootdir_abs" "${g_outdir}/deplinks/libpbihdf"

	shared_flag="SHARED_LIB=true"
set -x
    # build
    eval "$g_conf_cmd" \
        CXX="${g_gxx_exe}" \
        AR="${g_ar_exe}" \
	"${shared_flag}" \
	BOOST_INCLUDE="${g_outdir_abs}/deplinks/boost/include" \
	HTSLIB_INCLUDE="${g_outdir_abs}/deplinks/htslib/include" \
	PBBAM_INCLUDE="${g_outdir_abs}/deplinks/pbbam/include" \
	LIBPBDATA_INCLUDE="${g_outdir_abs}/deplinks/libpbdata/include" \
	LIBPBIHDF_INCLUDE="${g_outdir_abs}/deplinks/libpbihdf/include/hdf" \
	HDF5_INCLUDE="${g_outdir_abs}/deplinks/hdf5/include" \
	HDF5_LIB="${g_outdir_abs}/deplinks/hdf5/lib/libhdf5.so" \
	ZLIB_LIB="${g_outdir_abs}/deplinks/zlib/lib/libz.so" \
	HTSLIB_LIB="${g_outdir_abs}/deplinks/htslib/lib/libhts.so" \
	PBBAM_LIB="${g_outdir_abs}/deplinks/pbbam/lib/libpbbam.so" \
	LIBPBDATA_LIB="${g_outdir_abs}/deplinks/libpbdata/lib/libpbdata.so" \
	LIBPBIHDF_LIB="${g_outdir_abs}/deplinks/libpbihdf/lib/libpbihdf.so" \
	${1+"$@"}

    eval "$g_make_cmd" \
        -j4 \
        libblasr.so
set +x
}

unittest() {
    echo "Running $g_name 'unittest' target..."
    
set -x
    eval "$g_unittest_make_cmd" \
        CXX="${g_gxx_exe}" \
	OUTDIR="$g_git_unittest_outdir" \
	GTEST_SRCDIR="$g_gtest_rootdir_abs/fused-src" \
	LIBBLASR_INCLUDE="${g_installbuild_dir}/include/alignment" \
	LIBPBIHDF_INCLUDE="${g_outdir_abs}/deplinks/libpbihdf/include/hdf" \
	LIBPBDATA_INCLUDE="${g_outdir_abs}/deplinks/libpbdata/include" \
	PBBAM_INCLUDE="${g_outdir_abs}/deplinks/pbbam/include" \
	HTSLIB_INCLUDE="${g_outdir_abs}/deplinks/htslib/include" \
	HDF5_INCLUDE="${g_outdir_abs}/deplinks/hdf5/include" \
	BOOST_INCLUDE="${g_outdir_abs}/deplinks/boost/include" \
	GTEST_INCLUDE="$g_gtest_rootdir_abs/fused-src" \
	LIBBLASR_LIB="${g_installbuild_dir}/lib/libblasr.so" \
	LIBPBIHDF_LIB="${g_outdir_abs}/deplinks/libpbihdf/lib/libpbihdf.so" \
	LIBPBDATA_LIB="${g_outdir_abs}/deplinks/libpbdata/lib/libpbdata.so" \
	PBBAM_LIB="${g_outdir_abs}/deplinks/pbbam/lib/libpbbam.so" \
	HTSLIB_LIB="${g_outdir_abs}/deplinks/htslib/lib/libhts.so" \
	HDF5_LIB="${g_outdir_abs}/deplinks/hdf5/lib/libhdf5.so" \
	HDF5_CPP_LIB="${g_outdir_abs}/deplinks/hdf5/lib/libhdf5_cpp.so" \
	ZLIB_LIB="${g_outdir_abs}/deplinks/zlib/lib/libz.so" \
	V=1 \
	${1+"$@"} gtest
set +x

    # clean installunittest dir
    rm -rf "$g_installunittest_dir";
    mkdir -p "$g_installunittest_dir";

    # Copy unittest xml results dir
    cp -a "$g_git_unittest_outdir/xml"  "$g_installunittest_dir"
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
	cp -a "${g_git_build_srcdir}/${g_name}.so"  "$g_installbuild_dir/lib"

    # install includes
    mkdir -p "$g_installbuild_dir/include"        
    # FIXME: Is there a better way to specify all the include headers that
    #        we need to export to other programs that depend on libblasr??
    for i in . utils statistics tuples format files suffixarray ipc bwt datastructures/anchoring datastructures/alignment datastructures/alignmentset algorithms/alignment algorithms/compare algorithms/sorting algorithms/alignment/sdp algorithms/anchoring; do
	mkdir -p "$g_installbuild_dir/include/alignment/$i"
	cp -a "${g_git_build_srcdir}/$i"/*.hpp "$g_installbuild_dir/include/alignment/$i"
    done
    for i in tuples datastructures/alignment; do
	mkdir -p "$g_installbuild_dir/include/alignment/$i"
	cp -a "${g_git_build_srcdir}/$i"/*.h "$g_installbuild_dir/include/alignment/$i"
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