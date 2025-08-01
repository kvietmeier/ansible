#!/bin/bash
# ====================================================================
# Elbencho Block Size Test Script
#
# Description:
#   Runs a matrix of elbencho tests across different workloads
#   (read/write, sequential/random) and block sizes.
#
# Assumes:
#   * That the elbencho server is already running and the mount points are set up.
#   * That /mount/share1/elbencho-files/ exists on all clients.
#   * Hosts are named client01, client02, ..., client0n
#
# Usage:
#   ./elbencho_test_block_sizes.sh <NUM_CLIENTS>
#
# Example:
#   ./elbencho_test_block_sizes.sh 11
#
# Notes:
#   - NUM_CLIENTS determines the client range: client01..clientNN
#   - Results are written to /tmp/results.txt and /tmp/results.csv
#
# Created By:
#  Karl Vietmeier VAST Data
#  Svenn Bruener VAST Data
#
# ====================================================================

# --------------------------
# Configuration Variables
# --------------------------
HOSTNAME="client"                      # Hostname prefix
MOUNTPOINT="/mount/share1"             # Mount point for tests
EB_FILES="elbencho-files"              # Directory for test files
THREADS=32                             # Threads per client
IODEPTH=4                              # IO depth
SIZE="100G"                            # Test file size
TIMELIMIT=3600                         # Seconds per test
RESFILE="/tmp/results.txt"             # Result text file
CSVFILE="/tmp/results.csv"             # Result CSV file


# --------------------------
# Validate Input
# --------------------------
NUM_CLIENTS=${1}
if [[ -z "$NUM_CLIENTS" || "$NUM_CLIENTS" -le 0 ]]; then
  echo "Usage: $0 <NUM_CLIENTS>"
  echo "Example: $0 11"
  exit 1
fi

# --------------------------
# Pre-Run Checks
# --------------------------

# Check first client is reachable
FIRST_CLIENT=$(printf "%s%02d" "$HOSTNAME" 1)
if ! ping -c 1 -W 2 "$FIRST_CLIENT" >/dev/null 2>&1; then
  echo "ERROR: Cannot reach $FIRST_CLIENT. Check network or inventory."
  exit 2
fi

# Check NFS mount
if ! mountpoint -q "$MOUNTPOINT"; then
  echo "ERROR: $MOUNTPOINT is not mounted. Please mount before running tests."
  exit 3
fi

# Check elbencho binary
if ! command -v elbencho >/dev/null 2>&1; then
  echo "ERROR: elbencho binary not found in PATH. Install or adjust PATH."
  exit 4
fi

# --------------------------
# Archive Old Results
# --------------------------
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
if [[ -f "$RESFILE" ]]; then
  mv "$RESFILE" "${RESFILE%.txt}_$TIMESTAMP.txt"
fi
if [[ -f "$CSVFILE" ]]; then
  mv "$CSVFILE" "${CSVFILE%.csv}_$TIMESTAMP.csv"
fi

# --------------------------
# Run Tests
# --------------------------
for TESTCASE in "--read --rand" "--read" "--write --rand" "--write"; do
  for BLOCKSIZE in 4k 8k 16k 32k 64k 128k 256k 512k 1m 2m; do
    echo "=== TESTCASE: $TESTCASE --- BLOCKSIZE: $BLOCKSIZE ==="
    elbencho --hosts ${HOSTNAME}[01-${NUM_CLIENTS}] $TESTCASE \
      --block $BLOCKSIZE --size "$SIZE" --direct \
      -t "$THREADS" --iodepth "$IODEPTH" --nofdsharing --infloop \
      --timelimit "$TIMELIMIT" --resfile "$RESFILE" --csvfile "$CSVFILE" \
      "${MOUNTPOINT}/${EB_FILES}/file[1-10]"
  done
done

### ToDo
# - Add more test cases or block sizes as needed
# - Consider adding error handling for individual test failures