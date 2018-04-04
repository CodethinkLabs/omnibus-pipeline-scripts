#!/bin/bash

usage() {
  cat <<EOF
  usage: $0 -s OFC_TESTS_DIR -o OFC_OUTPUT_DIR
EOF
}

compile() {
  local src_path="$1"
  local src_name="$(basename $src_path)"
  local src_dir="$(dirname $src_path)"
  local inc_dir="$src_dir/include/"
  local stdin_name="$src_dir/stdin/$src_name"

  local output_path="$2"
  local output_name="$(basename $output_path)"
  local output_dir="$(dirname $output_path)"
  local stderr_path="$output_path.stderr"

  local compiler="$3"
  local compiler_args="$4"

  echo -e "--Compile"

  # Prepare isolated environment
  if [ -f "$(which mktemp)" ]; then
    mktemp="mktemp -p"
    isolate="$(mktemp -d)"
  else
    mktemp="tempfile -d"
    isolate="$(tempfile)"
    rm "$isolate"
    mkdir -p "$isolate"
  fi

  # Compile
  binary="$isolate/a.out"
  if [ -d "$inc_dir" ]; then
    stderr="$($compiler $compiler_args -I $inc_dir -x f77 $src_path -o $binary 2>&1)"
  else
    stderr="$($compiler $compiler_args -x f77 $src_path -o $binary 2>&1)"
  fi

  # Run
  if [ $? -eq 0 ]; then
    $mktemp $isolate &> /dev/null
    pushd "$isolate" &> /dev/null
    if [ -f "$stdin_name" ]; then
      cat "$stdin_name" | "$binary" > "$output_name"
    else
      "$binary" > "$output_name"
    fi
    popd &> /dev/null
    mv "$isolate/$output_name" "$output_path"
    rm -rf "$isolate" &> /dev/null
  else
    echo "$src_name failed to compile." > "$output_path"
    echo "$stderr" > "$stderr_path"
  fi
}

generate_actual() {
  echo -e "-Generate actual"
  local src_path="$1"
  local output_path="$2"
  local compiler="/opt/codethink-gcc/bin/gfortran"
  local compiler_args="-fdec -std=extra-legacy -frecursive -fno-automatic"
  compile "$src_path" "$output_path" "$compiler" "$compiler_args"
}

generate_expected() {
  echo -e "-Generate expected"
  local src_path="$1"
  local output_path="$2"

  local src_name="$(basename $src_path)"
  local src_dir="$(dirname $src_path)"
  local stdout_path="$src_dir/stdout/$src_name"

  ## Copy .expected file if exists, otherwise compile
  if [ -f "$stdout_path" ]; then
    echo -e "--Copy"
    cp "$stdout_path" "$output_path"
  else
    local compiler="gfortran"
    local compiler_args="-fdec -frecursive -fno-automatic"
    compile "$src_path" "$output_path" "$compiler" "$compiler_args"
  fi
}

compare_actual_with_expected() {
  if $(diff "$1" "$2" &> "$3"); then
    echo "pass"
  else
    echo "fail"
  fi
}

run_tests() {
  local source_paths="$1"
  local output_dir="$2"
  local actual_results_name="$3"

  local output_generated_dir="$output_dir/generated"
  local actual_results_path="$output_dir/$actual_results_name"

  mkdir -p "$output_generated_dir"

  local actual_results=''
  for test_src_path in $source_paths; do
    local test_src_abs_path="$(readlink -e $test_src_path)"
    local test_name="$(basename $test_src_abs_path)"
    local output_core_path="$output_generated_dir/$test_name"

    echo -e "\n$test_name"
    generate_expected "$test_src_abs_path" "$output_core_path.expected"
    generate_actual "$test_src_abs_path" "$output_core_path.actual"
    local test_result="$(compare_actual_with_expected "$output_core_path.actual" "$output_core_path.expected" "$output_core_path.diff")"
    local test_line="$test_name:$test_result"
    echo -e "-Result: $test_result"

    actual_results="$actual_results$test_line\n"
  done
  echo -e "$actual_results" > "$actual_results_path"
}

compare_expected_with_actual_results() {
  if ! stderr="$(diff $1 $2)"; then
    echo -e "\nOFC tests failed"
    echo "$stderr"
    exit 1
  fi
}

run_ofc_tests() {
  local ofc_tests_programs_dir="$ofc_tests_dir/programs"
  local ofc_tests_nist_dir="$ofc_tests_programs_dir/nist"

  local ofc_output_programs_dir="$ofc_output_dir/programs"
  local ofc_output_nist_dir="$ofc_output_dir/nist"

  local actual_results_programs_name="programs_actual_results"
  local actual_results_programs_path="$ofc_output_programs_dir/$actual_results_programs_name"
  local actual_results_nist_name="nist_actual_results"
  local actual_results_nist_path="$ofc_output_nist_dir/$actual_results_nist_name"

  local script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local expected_results_dir="$script_dir/expected_test_results"
  local expected_results_programs_path="$expected_results_dir/programs_expected_results"
  local expected_results_nist_path="$expected_results_dir/nist_expected_results"

  # Run "Programs"
  run_tests "$ofc_tests_programs_dir/*.f" "$ofc_output_programs_dir" "$actual_results_programs_name"
  compare_expected_with_actual_results "$expected_results_programs_path" "$actual_results_programs_path"

  # Run "NIST"
  run_tests "$ofc_tests_nist_dir/*.FOR" "$ofc_output_nist_dir" "$actual_results_nist_name"
  compare_expected_with_actual_results "$expected_results_nist_path" "$actual_results_nist_path"

  echo -e "\nOFC tests passed"
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
        ofc_tests_dir="$OPTARG"
        ;;
      o)
        ofc_output_dir="$OPTARG"
        ;;
    esac
  done

  if [ -z "$ofc_tests_dir" -o ! -d "$ofc_tests_dir" ]; then
    echo -e "ERROR: OFC_TESTS_DIR is mandatory and must be a directory\n"
    usage
    exit 1
  fi

  if [ -z "$ofc_output_dir" ]; then
    echo -e "ERROR: OFC_OUTPUT_DIR is mandatory\n"
    usage
    exit 1
  fi

  run_ofc_tests
}

main "$@"
