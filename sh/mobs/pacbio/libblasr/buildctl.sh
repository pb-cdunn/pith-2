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

    g_gcc_runtime_libdir_abs=$MOBS_gcc__runtimelib_dir
	g_boost_rootdir_abs=$MOBS_boost__root_dir
	g_zlib_rootdir_abs=$MOBS_zlib__install_dir
	g_hdf5_rootdir_abs=$MOBS_hdf5__install_dir
	g_htslib_rootdir_abs=$MOBS_htslib__install_dir
	g_pbbam_rootdir_abs=$MOBS_pbbam__install_dir
	g_libpbdata_rootdir_abs=$MOBS_libpbdata__install_dir
	g_libpbihdf_rootdir_abs=$MOBS_libpbihdf__install_dir

	# For unittest:
	g_gtest_rootdir_abs=$MOBS_gtest__root_dir
	

	eval g_srcdir="\$MOBS_${g_name}__src_dir"
	eval g_outdir_abs="\$MOBS_${g_name}__output_dir"
	eval g_outdir="\$MOBS_${g_name}__output_dir"
	eval g_installbuild_dir_abs="\$MOBS_${g_name}__install_dir"
	eval g_installbuild_dir="\$MOBS_${g_name}__install_dir"
	eval g_installunittest_dir_abs="\$MOBS_${g_name}__installunittest_dir"
	eval g_installunittest_dir="\$MOBS_${g_name}__installunittest_dir"

    ### bincrapper
    ###
	eval g_binwrap_build_dir="\$MOBS_${g_name}__install_binwrapbuild_dir"

	# For binwrap-build directory:
	build_topdir=$MOBS_global__build_topdir;

	# Compute the path to the dependency lib dirs, relative to the top
	# of the build tree
	g_libblasr_build_runtime_libdir_reltop=${MOBS_libblasr__runtimelib_dir#$build_topdir/}
	g_libpbihdf_build_runtime_libdir_reltop=${MOBS_libpbihdf__runtimelib_dir#$build_topdir/}
	g_libpbdata_build_runtime_libdir_reltop=${MOBS_libpbdata__runtimelib_dir#$build_topdir/}
	g_pbbam_build_runtime_libdir_reltop=${MOBS_pbbam__runtimelib_dir#$build_topdir/}
	g_htslib_build_runtime_libdir_reltop=${MOBS_htslib__runtimelib_dir#$build_topdir/}
	g_hdf5_build_runtime_libdir_reltop=${MOBS_hdf5__runtimelib_dir#$build_topdir/}
	g_zlib_build_runtime_libdir_reltop=${MOBS_zlib__runtimelib_dir#$build_topdir/}
	g_gcc_build_runtime_libdir_reltop=${MOBS_gcc__runtimelib_dir#$build_topdir/}

	# For binwrap-deploy directory:
	g_libblasr_deploy_runtime_libdir_reltop="pacbio/libblasr/lib"
	g_libpbihdf_deploy_runtime_libdir_reltop="pacbio/libpbihdf/lib"
	g_libpbdata_deploy_runtime_libdir_reltop="pacbio/libpbdata/lib"
	g_pbbam_deploy_runtime_libdir_reltop="pacbio/pbbam/lib"
	g_htslib_deploy_runtime_libdir_reltop="pacbio/htslib/lib"
	g_hdf5_deploy_runtime_libdir_reltop="thirdparty/hdf5/hdf5-1.8.12/lib"
	g_zlib_deploy_runtime_libdir_reltop="thirdparty/zlib/zlib_1.2.8/lib"
	g_gcc_deploy_runtime_libdir_reltop="thirdparty/gcc/gcc-4.8.4/lib"

	# The deploy topdir is effectively the 'private' directory
    # TODO(CD): Should this have more dot-dots?
	g_deploy_topdir_relprog="../../.."


	echo "Computing reltop..."
	binwrap_reltop=${g_binwrap_build_dir#$build_topdir/}
	top_relbinwrap=""
	if [[ $binwrap_reltop =~ ^/ ]]; then
	    merror "Could not compute topdir (binwrap not under topdir)"
	fi

	while [[ x"$binwrap_reltop" != x"." ]] ; do
	    if [[ x"$binwrap_reltop" == x"/" ]] ; then
		minterror "Error in computing topdir."
	    fi
	    top_relbinwrap="$top_relbinwrap/..";
	    binwrap_reltop=$(dirname "$binwrap_reltop");
	done
	top_relbinwrap=${top_relbinwrap#/};
	g_build_topdir_relprog="$top_relbinwrap"
    ###

    g_builddir="$g_outdir"/build
    mkdir -p "$g_builddir"
    g_unittest_outdir="$g_outdir"/unittest
    mkdir -p "$g_unittest_outdir"

    g_conf_cmd='
	"$g_srcdir"/../configure.py
    '
    g_conf_cmd=$(echo $g_conf_cmd)
}

# ---- build targets

clean_unittest() {
    rm -rf "${g_unittest_outdir}"
}
clean_build() {
    echo "Running $g_name 'clean-build' target..."
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
    cd "$g_builddir"
    ln -sf "$g_srcdir"/makefile makefile
    # build
    eval "$g_conf_cmd" \
        CXX="${g_gxx_exe}" \
        AR="${g_ar_exe}" \
	"${shared_flag}" \
    GCC_LIB=\"$g_gcc_runtime_libdir_abs\" \
	BOOST_INC="${g_outdir_abs}/deplinks/boost/include" \
	HTSLIB_INC="${g_outdir_abs}/deplinks/htslib/include" \
	PBBAM_INC="${g_outdir_abs}/deplinks/pbbam/include" \
	LIBPBDATA_INC="${g_outdir_abs}/deplinks/libpbdata/include" \
	LIBPBIHDF_INC="${g_outdir_abs}/deplinks/libpbihdf/include/hdf" \
	HDF5_INC="${g_outdir_abs}/deplinks/hdf5/include" \
	HDF5_LIB="${g_outdir_abs}/deplinks/hdf5/lib/" \
	ZLIB_LIB="${g_outdir_abs}/deplinks/zlib/lib/" \
	HTSLIB_LIB="${g_outdir_abs}/deplinks/htslib/lib/" \
	PBBAM_LIB="${g_outdir_abs}/deplinks/pbbam/lib/" \
	LIBPBDATA_LIB="${g_outdir_abs}/deplinks/libpbdata/lib/" \
	LIBPBIHDF_LIB="${g_outdir_abs}/deplinks/libpbihdf/lib/" \
	${1+"$@"}

    eval "$g_make_exe" -C "$g_builddir" \
        -j4 \
        libblasr.so
set +x
    build_unittest
}

build_unittest() {
    echo "Running $g_name 'unittest' target..."
    
	shared_flag="SHARED_LIB=true"
set -x
    cd "$g_unittest_outdir"
    ln -sf "$g_srcdir"/../unittest/makefile makefile
    eval "$g_conf_cmd" \
        CXX="${g_gxx_exe}" \
        AR="${g_ar_exe}" \
	"${shared_flag}" \
	GTEST_SRCDIR="$g_gtest_rootdir_abs/fused-src" \
	GTEST_INC="$g_gtest_rootdir_abs/fused-src" \
    GCC_LIB=\"$g_gcc_runtime_libdir_abs\" \
	BOOST_INC="${g_outdir_abs}/deplinks/boost/include" \
	HTSLIB_INC="${g_outdir_abs}/deplinks/htslib/include" \
	PBBAM_INC="${g_outdir_abs}/deplinks/pbbam/include" \
	LIBPBDATA_INC="${g_outdir_abs}/deplinks/libpbdata/include" \
	LIBPBIHDF_INC="${g_outdir_abs}/deplinks/libpbihdf/include/hdf" \
	LIBBLASR_INC="${g_srcdir}" \
	HDF5_INC="${g_outdir_abs}/deplinks/hdf5/include" \
	HDF5_LIB="${g_outdir_abs}/deplinks/hdf5/lib/" \
	ZLIB_LIB="${g_outdir_abs}/deplinks/zlib/lib/" \
	HTSLIB_LIB="${g_outdir_abs}/deplinks/htslib/lib/" \
	PBBAM_LIB="${g_outdir_abs}/deplinks/pbbam/lib/" \
	LIBPBDATA_LIB="${g_outdir_abs}/deplinks/libpbdata/lib/" \
	LIBPBIHDF_LIB="${g_outdir_abs}/deplinks/libpbihdf/lib/" \
	LIBBLASR_LIB="${g_builddir}/" \
	${1+"$@"}

    eval "$g_make_exe" -C "$g_unittest_outdir" \
        -j4 \
        all
set +x

    # clean installunittest dir ~hm
    # why? it seems to be the same as g_unittest_outdir! ~cd
    #rm -rf "$g_installunittest_dir";
    mkdir -p "$g_installunittest_dir";

    # Copy unittest xml results dir ~hm
    # but they are the same file! ~cd
    #cp -a "$g_unittest_outdir/xml"  "$g_installunittest_dir"
}
unittest() {
    build_unittest
set -x
    eval "$g_make_exe" -C "$g_unittest_outdir" \
        gtest
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
    # FIXME: Is there a better way to specify all the include headers that
    #        we need to export to other programs that depend on libblasr??
    for i in . utils statistics tuples format files suffixarray ipc bwt datastructures/anchoring datastructures/alignment datastructures/alignmentset algorithms/alignment algorithms/compare algorithms/sorting algorithms/alignment/sdp algorithms/anchoring simulator; do
	mkdir -p "$g_installbuild_dir/include/alignment/$i"
	cp -a "${g_srcdir}/$i"/*.hpp "$g_installbuild_dir/include/alignment/$i"
    done

    mkdir -p "$g_installbuild_dir/include/alignment/query"
    cp -a "${g_srcdir}/query"/*.h "$g_installbuild_dir/include/alignment/query"

    for i in tuples datastructures/alignment; do
	mkdir -p "$g_installbuild_dir/include/alignment/$i"
	cp -a "${g_srcdir}/$i"/*.h "$g_installbuild_dir/include/alignment/$i"
    done

    # (The following is basically copied from blasr/build.ctl.)

    # install bin executables
    mkdir "$g_installbuild_dir/bin"
    #build_dir="${g_outdir}"/build
    unittest_dir="${g_outdir}"/unittest
    cp -a "${unittest_dir}/libblasr-test-runner"  "$g_installbuild_dir/bin"


    # Create the binwrap dir
	echo "Creating the binwrap-build wrappers..."
	rm -rf "$g_installbuild_dir/binwrap-build"
	mkdir -p "$g_installbuild_dir/binwrap-build"
    rm -rf "$g_installbuild_dir/binwrap-deploy"
    mkdir -p "$g_installbuild_dir/binwrap-deploy"

    # Create the binwrap wrappers (using the blasr template)
	binwrap_tmpl="$g_progdir/../blasr/infiles/blasr-binwrap.sh.tmpl"
	prognames=""
	prognames="$prognames libblasr-test-runner"
	for i in $prognames; do
	    # build binwrap:
	    sed \
		-e "s,%PROGNAME%,$i," \
		-e "s,%TOPDIR_RELPROG%,$g_build_topdir_relprog/../../../../../../../../..," \
		-e "s,%LIBBLASR_RUNTIMELIB_RELTOP%,$g_libblasr_build_runtime_libdir_reltop," \
		-e "s,%LIBPBIHDF_RUNTIMELIB_RELTOP%,$g_libpbihdf_build_runtime_libdir_reltop," \
		-e "s,%LIBPBDATA_RUNTIMELIB_RELTOP%,$g_libpbdata_build_runtime_libdir_reltop," \
		-e "s,%PBBAM_RUNTIMELIB_RELTOP%,$g_pbbam_build_runtime_libdir_reltop," \
		-e "s,%HTSLIB_RUNTIMELIB_RELTOP%,$g_htslib_build_runtime_libdir_reltop," \
		-e "s,%HDF5_RUNTIMELIB_RELTOP%,$g_hdf5_build_runtime_libdir_reltop," \
		-e "s,%ZLIB_RUNTIMELIB_RELTOP%,$g_zlib_build_runtime_libdir_reltop," \
		-e "s,%GCC_RUNTIMELIB_RELTOP%,$g_gcc_build_runtime_libdir_reltop," \
		"$binwrap_tmpl" > "$g_installbuild_dir/binwrap-build/$i"
	    chmod a+x "$g_installbuild_dir/binwrap-build/$i"

	    # deploy binwrap:
		sed \
		    -e "s,%PROGNAME%,$i," \
		    -e "s,%TOPDIR_RELPROG%,$g_deploy_topdir_relprog," \
		    -e "s,%LIBBLASR_RUNTIMELIB_RELTOP%,$g_libblasr_deploy_runtime_libdir_reltop," \
		    -e "s,%LIBPBIHDF_RUNTIMELIB_RELTOP%,$g_libpbihdf_deploy_runtime_libdir_reltop," \
		    -e "s,%LIBPBDATA_RUNTIMELIB_RELTOP%,$g_libpbdata_deploy_runtime_libdir_reltop," \
		    -e "s,%PBBAM_RUNTIMELIB_RELTOP%,$g_pbbam_deploy_runtime_libdir_reltop," \
		    -e "s,%HTSLIB_RUNTIMELIB_RELTOP%,$g_htslib_deploy_runtime_libdir_reltop," \
		    -e "s,%HDF5_RUNTIMELIB_RELTOP%,$g_hdf5_deploy_runtime_libdir_reltop," \
		    -e "s,%ZLIB_RUNTIMELIB_RELTOP%,$g_zlib_deploy_runtime_libdir_reltop," \
		    -e "s,%GCC_RUNTIMELIB_RELTOP%,$g_gcc_deploy_runtime_libdir_reltop," \
		    "$binwrap_tmpl" > "$g_installbuild_dir/binwrap-deploy/$i"
		chmod a+x "$g_installbuild_dir/binwrap-deploy/$i"
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
