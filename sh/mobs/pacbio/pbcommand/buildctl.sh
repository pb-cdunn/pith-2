#!/bin/bash

# ---- required subroutines
set_globals() {
    # required globals:
    g_name="pbcommand"

    # FIXME: unused for now...
    # # other globals:
    # g_outdir_name="_output";
    # g_outdir_abs="$(readlink -m "$g_progdir/../$g_outdir_name")"
    # g_outdir=$g_outdir_abs;
    # g_installbuild_dir_abs="${g_outdir}/install-build"
    # g_installbuild_dir="${g_installbuild_dir_abs}"

    g_rootdir_reltop="bioinformatics/lib/python/pbcommand";

    g_topdir="$g_progdir/../../../../.."
    g_topdir_abs=$(readlink -f "$g_topdir");

    g_outdirtop_abs="$g_topdir_abs/_output/modulebuilds"
	
    g_srcdir_abs="$g_topdir_abs/$g_rootdir_reltop"
    g_outdir_abs="$g_outdirtop_abs/$g_rootdir_reltop/_output"

    g_git_rootdir="$g_outdirtop_abs/prebuilt.tmpout/git/git_2.4.5/libc-2.5/gcc-4.9.2/_output/install"
    g_git_exe="${g_git_rootdir}/binwrap-build/git"

    g_git_remote_url=$(bash -c '. "'"$g_srcdir_abs/${g_name}"'.github.ish"; echo "$URL"')
    g_git_ref=$(bash -c '. "'"$g_srcdir_abs/${g_name}"'.github.ish"; echo "$REF"')

    local git_dirname=$(basename "$g_git_remote_url" .git)
    g_git_fetch_dir="$g_outdir_abs/build"
    g_git_build_topdir="$g_git_fetch_dir/$git_dirname"
    g_git_build_srcdir="$g_git_build_topdir"
}

# ---- build targets

fetch_gitsrc() {
    local git_home=$g_git_fetch_dir;
    local git_destdir="$g_git_build_topdir"

    local remoteinfo;
    local mustclone=false;
    local stat;
    stat=0;
    if [[ ! -e "$git_destdir/.git" ]] ; then
	mustclone=true;
    else
	remoteinfo=$(HOME="$git_home" "$g_git_exe" -C "$git_destdir" remote show origin) || stat=$?
	if [[ $stat -eq 0 ]] ; then
	    local fetchurl;
	    fetchurl=$(echo "$remoteinfo" | sed -ne 's/^[[:space:]]*Fetch URL:[[:space:]]*//p')
	    if [[ x"$fetchurl" != x"$g_git_remote_url" ]] ; then
		mustclone=true;
	    fi
	elif [[ $stat -eq 1 ]] ; then
	    mustclone=true;
	else
	    merror "Unexpected error (1) when running git command (exitstat: $stat)"
	fi
    fi

    if $mustclone; then
	echo "Cloning $g_name sources from git..."
	rm -rf "$git_home"
	mkdir -p "$git_home"
	HOME="$git_home" "$g_git_exe" clone "$g_git_remote_url" "$git_destdir"
    fi

    local mustfetch=false;
    # This will check to see if the reference is actually a valid git commint
    # sha hash in the local repository.  If so, we don't need to go out and 
    # fetch the latest from the remote repository.  For any other ref type
    # (e.g. HEAD, tag, branch,...) we cannot be guaranteed that it didnt't 
    # change on the remote side, so we need to fetch anyway.  If it not a 
    # reference listed by 'show-ref', but it is a git commit sha hash listed 
    # with parse-rev, but it not in the local repository, we also need
    # to fetch the latest.  This rev-parse command should handle all the cases
    # (no need to fetch if exits with zero status, fetch otherwise).
    # See this link for more info on testing refs:
    #    http://stackoverflow.com/questions/18222634/given-a-git-refname-can-i-detect-whether-its-a-hash-tag-or-branch
    stat=0
    HOME="$git_home" "$g_git_exe" -C "$git_destdir" show-ref "${g_git_ref}" > /dev/null 2>&1 || stat=$?
    if [[ $stat -eq 0 ]] ; then    
	# This is a HEAD, tag, branch, remote reference.  We will need to 
	# fetch (since it is a pointer that may have been updated in the
	# remote repository.
	mustfetch=true;
    elif [[ $stat -eq 1 ]] ; then
	stat=0
	HOME="$git_home" "$g_git_exe" -C "$git_destdir" rev-parse "${g_git_ref}^{commit}" > /dev/null 2>&1 || stat=$?
	if [[ $stat -ne 0 ]] ; then
	    # This is either not a valid sha hash, or it is one that our 
	    # local repository does not know about yet.  In either case
	    # fetch it from the remote repository.
	    mustfetch=true;
	fi
    else
	merror "Unexpected error (2) when running git command (exitstat: $stat)"
    fi

    if $mustfetch; then
	echo "Fetching (updating) $g_name sources from git..."
	HOME="$git_home" "$g_git_exe" -C "$git_destdir" fetch
    else
	echo "Git sources for $g_name already up to date..."
    fi

    # Now do a sanity check to make sure we actually have the ref in question
    # in our local repository
    stat=0
    HOME="$git_home" "$g_git_exe" -C "$git_destdir" rev-parse "${g_git_ref}^{commit}" > /dev/null 2>&1 || stat=$?
    if [[ $stat -ne 0 ]] ; then
	merror "Could not find the git reference '$g_git_ref' after updating the local repository"
    fi

    # Now update to the specified reference or sha hash
    # FIXME: temporary hack to avoid reset if this file exists.  Not a good
    #        long term solution (since developers could lose edits and 
    #        cannot easily test equivalent of nightly build).  See bug 26971.
    if [[ ! -e "$g_srcdir_abs/no-git-reset.txt" ]] ; then
	HOME="$git_home" "$g_git_exe" -C "$git_destdir" reset --hard "$g_git_ref"
    fi

    # At this point we should have the expected code in $git_destdir
}

clean() {
    echo "Running $g_name 'clean' target..."
    bash ${g_progdir}/pkgbuild.sh --clean
}
cleanall() {
    echo "Running $g_name 'cleanall' target..."
    clean;
}
build() {
    fetch_gitsrc;

    echo "Running $g_name 'build' target..."
    bash ${g_progdir}/pkgbuild.sh --build
}
install_build() {
    if ! $opt_no_sub_targets; then
	build;
    fi

    echo "Running $g_name 'install-build' target..."
    bash ${g_progdir}/pkgbuild.sh --install
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
