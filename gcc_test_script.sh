#!/bin/bash

set -e

usage() {
  cat <<EOF
  usage: $0
  This script fetches and runs available test suites using runners
  provided in ./*-tests-runner directories.
EOF
}

run_tests() {
  local script_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local tests_results_dir="$HOME/tests-results"
  mkdir -p "$tests_results_dir"

  # Fetch and run OFC tests
  local ofc_tests_git_src="https://github.com/CodethinkLabs/ofc-tests.git"
  local ofc_tests_dir="$HOME/ofc-tests"

  if [ -d "$ofc_tests_dir" ]; then
    rm -rf "$ofc_tests_dir"
  fi
  git clone "$ofc_tests_git_src" "$ofc_tests_dir"

  local ofc_tests_runner_path="$script_dir/ofc-tests-runner/run_ofc_tests.sh"
  local ofc_tests_results_path="$tests_results_dir/ofc-tests-results"
  "$ofc_tests_runner_path" -s "$ofc_tests_dir" -o "$ofc_tests_results_path"

  echo -e "\n\nAll test passed"
  exit 0
}

main() {
  while getopts "h" option; do
    case "$option" in
      h)
        usage
        exit 0
        ;;
    esac
  done

  run_tests
}

main "$@"
