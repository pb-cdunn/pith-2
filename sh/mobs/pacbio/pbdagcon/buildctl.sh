#!/bin/bash
# vim: set ts=4 sts=4 sw=4 noet :

# ---- required subroutines
set_globals() {
    # required globals:
set -x
    g_name="pbdagcon"

	mobs_exe=$MOBS_EXE;
	if [[ -z "$mobs_exe" ]]; then
	    mobs_exe="$g_progdir/../../../../../build/3.x/mobs";
	fi
	eval $($mobs_exe -p "$g_name")

	g_make_exe=$MOBS_make__make_exe
	g_gcc_exe=$MOBS_gcc__gcc_exe
	g_gxx_exe=$MOBS_gcc__gxx_exe
	g_python_exe=$MOBS_python__python_exe

	g_libblasr_rootdir_abs=$MOBS_libblasr__install_dir
	g_libpbihdf_rootdir_abs=$MOBS_libpbihdf__install_dir
	g_libpbdata_rootdir_abs=$MOBS_libpbdata__install_dir
	g_pbbam_rootdir_abs=$MOBS_pbbam__install_dir
	g_htslib_rootdir_abs=$MOBS_htslib__install_dir
	g_hdf5_rootdir_abs=$MOBS_hdf5__install_dir
	g_zlib_rootdir_abs=$MOBS_zlib__install_dir
	g_boost_rootdir_abs=$MOBS_boost__root_dir
        g_gcc_runtime_libdir_abs=$MOBS_gcc__runtimelib_dir

	# For unittest:
	g_gtest_rootdir_abs=$MOBS_gtest__root_dir

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
	g_gcc_deploy_runtime_libdir_reltop="thirdparty/gcc/gcc-4.9.2/lib"

	# The deploy topdir is effectively the 'private' directory
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

    g_build_srcdir="$g_srcdir_abs/src/cpp"

    g_make_cmd='
	$g_make_exe -C "${g_outdir}"/build/src/cpp
    '
    g_make_cmd=$(echo $g_make_cmd)

    g_conf_cmd='
        cd "$g_build_srcdir"/../.. && "$g_python_exe" ./configure.py --build-dir="${g_outdir}"/build
    '
    g_conf_cmd=$(echo $g_conf_cmd)

    g_unittest_srcdir="${g_outdir}"/build/test/cpp
    g_unittest_outdir="${g_outdir}"/build/test/cpp
    g_unittest_makefile="$g_unittest_srcdir/makefile"

    g_unittest_make_cmd='
        ${g_make_exe} -C "$g_unittest_srcdir"
    '
    g_unittest_make_cmd=$(echo $g_unittest_make_cmd)
    # Delete the old fetched git.
	if [ -d "${g_outdir}"/build/pbdagcon ]; then
        rm -rf "${g_outdir}"/build/pbdagcon
    fi
}

# ---- build targets

clean() {
    echo "Running $g_name 'clean' target..."
    # Remove the _output directory
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

    ln -s "$g_libblasr_rootdir_abs" "${g_outdir}/deplinks/libblasr"
    ln -s "$g_libpbihdf_rootdir_abs" "${g_outdir}/deplinks/libpbihdf"
    ln -s "$g_libpbdata_rootdir_abs" "${g_outdir}/deplinks/libpbdata"
    ln -s "$g_pbbam_rootdir_abs" "${g_outdir}/deplinks/pbbam"
    ln -s "$g_htslib_rootdir_abs" "${g_outdir}/deplinks/htslib"
    ln -s "$g_hdf5_rootdir_abs" "${g_outdir}/deplinks/hdf5"
    ln -s "$g_zlib_rootdir_abs" "${g_outdir}/deplinks/zlib"
    ln -s "$g_boost_rootdir_abs" "${g_outdir}/deplinks/boost"

    #shared_flag=""
    #shared_libopt="-Wl,-Bstatic"
	shared_libopt="-Wl,-Bdynamic"
	shared_flag="SHARED_LIB=true"

    libblasr_includes="${g_outdir}/deplinks/libblasr/include;${g_outdir}/deplinks/libblasr/include/alignment"
    libpbdata_includes="${g_outdir}/deplinks/libpbdata/include"
    pbbam_includes="${g_outdir}/deplinks/pbbam/include"
    htslib_includes="${g_outdir}/deplinks/htslib/include"
    boost_includes="${g_outdir}/deplinks/boost/include"

    # FIXME: HACK to only provide the single include directories that blasr
    #        needs for libblasr, libpbihdf and boost.   Other things that 
    #        depend on those libraries require two versions of the include
    #        directories (probably because they inconsistently use the 
    #        directory prefix becasue they are poking into the source
    #        tree for the include files).  The makefile for blasr should
    #        probably handle multilple directories regardless, just to handle
    #        the general case, but the other builds and the include files
    #        provided to mobs should also be fixed to use just a single 
    #        directory.
    libblasr_include=${libblasr_includes#*;}
    libpbdata_include=$libpbdata_includes
    pbbam_include=$pbbam_includes
    htslib_include=$htslib_includes
    boost_include=${boost_includes}

    libblasr_libdir="${g_outdir}/deplinks/libblasr/lib"
    libpbihdf_libdir="${g_outdir}/deplinks/libpbihdf/lib"
    libpbdata_libdir="${g_outdir}/deplinks/libpbdata/lib"
    pbbam_libdir="${g_outdir}/deplinks/pbbam/lib"
    htslib_libdir="${g_outdir}/deplinks/htslib/lib"
    hdf5_libdir="${g_outdir}/deplinks/hdf5/lib"
    zlib_libdir="${g_outdir}/deplinks/zlib/lib"

    libblasr_libflags="$shared_libopt -lblasr"
    libpbihdf_libflags="$shared_libopt -lpbihdf"
    libpbdata_libflags="$shared_libopt -lpbdata"
    pbbam_libflags="$shared_libopt -lpbbam"
    htslib_libflags="$shared_libopt -lhts"
    hdf5_libflags="$shared_libopt -lhdf5_cpp $shared_libopt -lhdf5"
    zlib_libflags="$shared_libopt -lz"


set -x
    # configure
    eval "$g_conf_cmd" \
        --shared       \
	\
	CC=\"$g_gcc_exe\" \
	CXX=\"$g_gxx_exe\" \
	\
	BOOST_HEADERS=\"\" \
	"${shared_flag}" \
	\
	LIBBLASR_INCLUDE=\"$libblasr_include\" \
        LIBPBDATA_INCLUDE=\"$libpbdata_include\" \
	PBBAM_INCLUDE=\"$pbbam_include\" \
	HTSLIB_INCLUDE=\"$htslib_include\" \
	BOOST_INCLUDE=\"$boost_include\" \
	\
	LIBBLASR_LIB=\"$libblasr_libdir\" \
	LIBPBIHDF_LIB=\"$libpbihdf_libdir\" \
        LIBPBDATA_LIB=\"$libpbdata_libdir\" \
	PBBAM_LIB=\"$pbbam_libdir\" \
	HTSLIB_LIB=\"$htslib_libdir\" \
	HDF5_LIB=\"$hdf5_libdir\" \
	ZLIB_LIB=\"$zlib_libdir\" \
        GCC_LIB=\"$g_gcc_runtime_libdir_abs\" \
	\
	LIBBLASR_LIBFLAGS=\"$libblasr_libflags\" \
	LIBPBIHDF_LIBFLAGS=\"$libpbihdf_libflags\" \
        LIBPBDATA_LIBFLAGS=\"$libpbdata_libflags\" \
	PBBAM_LIBFLAGS=\"$pbbam_libflags\" \
	HTSLIB_LIBFLAGS=\"$htslib_libflags\" \
	HDF5_LIBFLAGS=\"$hdf5_libflags\" \
	ZLIB_LIBFLAGS=\"$zlib_libflags\" \
	GTEST_SRC="$g_gtest_rootdir_abs/fused-src/gtest" \
	GTEST_INCLUDE="$g_gtest_rootdir_abs/fused-src" \

    # build
    eval "$g_make_cmd" \
        -j4 \
	CC=\"$g_gcc_exe\" \
	${1+"$@"} all dazcon

set +x

}
install_build() {
set -x
    if ! $opt_no_sub_targets; then
	build;
    fi

    echo "Running $g_name 'install-build' target..."

    # clean install dir
    rm -rf "$g_installbuild_dir";
    mkdir -p "$g_installbuild_dir";

    # install bin executables
    mkdir "$g_installbuild_dir/bin"
    build_dir="${g_outdir}"/build
    cp -a "${build_dir}/src/cpp/${g_name}"  "$g_installbuild_dir/bin"
    cp -a "${build_dir}/src/cpp/dazcon"  "$g_installbuild_dir/bin"

    # Create the binwrap dir
	echo "Creating the binwrap-build wrappers..."
	rm -rf "$g_installbuild_dir/binwrap-build"
	mkdir -p "$g_installbuild_dir/binwrap-build"
	rm -rf "$g_installbuild_dir/binwrap-deploy"
	mkdir -p "$g_installbuild_dir/binwrap-deploy"

    # Create the binwrap wrappers
	binwrap_tmpl="$g_progdir/infiles/pbdagcon-binwrap.sh.tmpl"
	prognames=""
	prognames="$prognames $g_name"
	prognames="$prognames dazcon"
	for i in $prognames; do
	    # build binwrap:
	    sed \
		-e "s,%PROGNAME%,$i," \
		-e "s,%TOPDIR_RELPROG%,$g_build_topdir_relprog," \
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
unittest() {
    echo "Running $g_name 'unittest' target..."
    eval "$g_unittest_make_cmd"
    # Copy unittest xml results dir
    cp -a "$g_unittest_outdir/xml"  "$g_installunittest_dir"
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
