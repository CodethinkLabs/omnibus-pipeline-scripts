#!/bin/sh

set -e

usage() {
  cat <<EOF
  usage: $0
  This script runs Legacy and OFC tests using runners
  provided in ./legacy-tests-runner and ./ofc-tests-runner dirs.
  The script fetches OFC tests if not present, but expects
  Legacy tests to be in place.
EOF
}

run_tests() {
  local script_dir="$( cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local tests_results_dir="$HOME/tests-results"
  mkdir -p "$tests_results_dir"

  # Run Legacy tests
  local legacy_tests_dir="$HOME/legacy-tests"

  if [ ! -d "$legacy_tests_dir" ]; then
    echo "ERROR: Legacy tests not found"
    exit 1
  fi

  local legacy_tests_runner_path="$script_dir/legacy-tests-runner/run_legacy_tests.sh"
  local legacy_tests_results_path="$tests_results_dir/legacy_tests_results"
  "$legacy_tests_runner_path" -s "$legacy_tests_dir" -o "$legacy_tests_results_path"

  # Fetch and run OFC tests
  local ofc_tests_git_src="https://github.com/CodethinkLabs/ofc-tests.git"
  local ofc_tests_dir="$HOME/ofc-tests"

  if [ ! -d "$ofc_tests_dir" ]; then
    git clone "$ofc_tests_git_src" "$ofc_tests_dir"
  fi

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
