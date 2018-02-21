#!/bin/bash

usage() {
  cat <<EOF
  usage: $0 -s LEGACY_TESTS_REPOSITORY_DIR -o LEGACY_OUTPUT_PATH
EOF
}

compare_expected_with_actual_results() {
  if ! stderr="$(diff $1 $2)"; then
    echo -e "\nLegacy tests failed"
    echo -e "\n$stderr"
    exit 1
  fi
}

run_legacy_tests() {
  local legacy_tests_dir="$legacy_tests_repository_dir/ftests"
  local legacy_tests_runner_name="tryall"
  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local expected_results_path="$script_dir/expected_results"
  local actual_results_path="$legacy_output_path"

  echo -e "\nRun Legacy tests"

  pushd "$legacy_tests_dir" &> /dev/null
  ./$legacy_tests_runner_name &> "$actual_results_path"
  popd &> /dev/null

  echo -e "\nCompare results with the expected results"

  compare_expected_with_actual_results "$expected_results_path" "$actual_results_path"

  echo -e "\nLegacy tests passed"
  echo -e "See $actual_results_path for the results\n"
  exit 0
}

main() {
  while getopts "hs:o:" option; do
    case "$option" in
      h)
        usage
        exit 0
        ;;
      s)
        legacy_tests_repository_dir="$OPTARG"
        ;;
      o)
        legacy_output_path="$OPTARG"
        ;;
    esac
  done

  if [ -z "$legacy_tests_repository_dir" -o ! -d "$legacy_tests_repository_dir" ]; then
    echo -e "ERROR: LEGACY_TESTS_REPOSITORY_DIR is mandatory and must be a directory\n"
    usage
    exit 1
  fi

  if [ -z "$legacy_output_path" ]; then
    echo -e "ERROR: LEGACY_OUTPUT_PATH is mandatory\n"
    usage
    exit 1
  fi

  run_legacy_tests
}

main "$@"
