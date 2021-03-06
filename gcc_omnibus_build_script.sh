#!/bin/sh

set -ex

omnibus_git_name="omnibus-codethink-toolchain"
omnibus_git_source="https://github.com/CodethinkLabs/$omnibus_git_name.git"
omnibus_gcc_git_ref=""
omnibus_source_path="$HOME/$omnibus_git_name"
omnibus_results_dir="$omnibus_source_path/pkg"

build_artifacts_path="$HOME/codethink-gcc.tar.gz"

usage() {
  cat <<EOF
  usage: $0 -g OMNIBUS_GCC_GIT_REF
  This script builds Codethink's GCC using $omnibus_git_name project
  given commit/branch/tag to build.
EOF
}

build() {
  git clone "$omnibus_git_source" "$omnibus_source_path"

  pushd "$omnibus_source_path"
  OMNIBUS_GCC_GIT_REF="$omnibus_gcc_git_ref"      \
    omnibus build codethink-gcc                   \
    --log-level=unknown                           \
    --override                                    \
      base_dir:./local                            \
      workers:10                                  \
      append_timestamp:false                      \
      use_git_caching:false
  popd

  tar -czvf "$build_artifacts_path" -C "$omnibus_results_dir" .
}

main() {
  while getopts "hg:" option; do
    case "$option" in
      h)
        usage
        exit 0
        ;;
      g)
        omnibus_gcc_git_ref="$OPTARG"
        ;;
    esac
  done

  if [[ -z "$omnibus_gcc_git_ref" ]];then
    echo -e "ERROR: Passing Codethink's GCC git ref is mandatory\n"
    usage
    exit 1
  fi

  build
}

main "$@"
