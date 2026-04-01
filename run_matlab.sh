#!/usr/bin/env bash

set -u

# Resolve the repository root from this script's location.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_dir="$repo_root/logs"

# Keep MATLAB output for each requested script in its own log file.
mkdir -p "$log_dir"

# Require at least one MATLAB entry script name.
if [ "$#" -eq 0 ]; then
  echo "Usage: $0 run_script [more_run_scripts...]"
  echo "Example: $0 run_RI_simulator run_RI_dense_SSP_simulator"
  exit 1
fi

# Fail early if MATLAB is not available in the current shell.
if ! command -v matlab >/dev/null 2>&1; then
  echo "matlab is not on PATH"
  exit 1
fi

# Track whether any requested run fails.
overall_status=0

for script_arg in "$@"; do
  # Accept either run_name or run_name.m on the command line.
  script_base="${script_arg%.m}"
  script_file="$repo_root/${script_base}.m"
  log_file="$log_dir/${script_base}.log"

  if [ ! -f "$script_file" ]; then
    echo "Missing script: $script_file"
    overall_status=1
    continue
  fi

  # Use try/catch so MATLAB exits with a nonzero status on failure.
  matlab_cmd="run('${script_base}.m'); catch ME, disp(getReport(ME)); exit(1); end; exit(0);"

  echo "Running ${script_base}.m"
  (
    cd "$repo_root" || exit 1
    nohup matlab -nodisplay -nosplash -r "$matlab_cmd"
  ) > "$log_file" 2>&1 &
  status=$?

  if [ "$status" -ne 0 ]; then
    echo "Failed: ${script_base}.m (see $log_file)"
    overall_status=1
  else
    echo "Finished: ${script_base}.m (see $log_file)"
  fi
done

exit "$overall_status"
