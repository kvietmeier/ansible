#!/bin/bash
# ====================================================================
# Elbencho Block Size Test Script for S3
#
# Description:
#   Runs a matrix of elbencho tests across different workloads
#   (read/write, sequential/random) and block sizes.
#
# Assumes:
#   * That the elbencho server is already running and the S3 buckets are set up.
#   * Hosts are named client01, client02, ..., client0n
#
# Usage:
#   ./elbencho_s3_test_block_sizes.sh <NUM_CLIENTS>
#
# Example:
#   ./elbencho_s3_test_block_sizes.sh 11
#
# Notes:
#   - NUM_CLIENTS determines the client range: client01..clientNN
#   - Results are written to /tmp/s3_results.txt and /tmp/s3_results.csv
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
BUCKET="s3bucket1"                     # Bucket location (default s3bucket1)
EB_FILES="elbencho-files"              # Directory for test files
THREADS=32                             # Threads per client
IODEPTH=4                              # IO depth
SIZE="1G"                              # Test file size
TIMELIMIT=10                           # Seconds per test
RESFILE="/tmp/s3_results.txt"          # Result text file
CSVFILE="/tmp/s3_results.csv"          # Result CSV file

# S3 Settings
export AWS_ACCESS_KEY_ID="X772YOVETW27K34STEV3" # Access Key ID
export AWS_SECRET_ACCESS_KEY="IeWlOaYmUM2BgWGh05Uka6tq9Sg/7Um2VrGj5A3Y" # Access Key


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
# Run S3 Tests
# --------------------------
for TESTCASE in "--read --rand" "--read"; do
  for BLOCKSIZE in 4k 8k 16k 32k 64k 128k 256k 512k 1m 2m; do
    echo "=== TESTCASE: $TESTCASE --- BLOCKSIZE: $BLOCKSIZE ==="
    elbencho --hosts ${HOSTNAME}[01-${NUM_CLIENTS}] $TESTCASE \
      --s3endpoints ADD_ENDPOINTS \
      --block $BLOCKSIZE --size "$SIZE" --direct \
      -t "$THREADS" --iodepth "$IODEPTH" --nofdsharing --infloop \
      --timelimit "$TIMELIMIT" --resfile "$RESFILE" --csvfile "$CSVFILE" \
      "${BUCKET}/file[1-${NUM_CLIENTS}]"
  done
done

#elbencho --hosts client[01-${NUM_CLIENTS}] -t 32 --iodepth 4 -b 16M --direct -s "${FILESIZE}" \
#  --s3endpoints "https://33.20.1.[11-13]" -w "${BUCKET}/file[1-${NUM_CLIENTS}]" \
#  --csvfile /tmp/elbencho.s3prep.csv > /tmp/elbencho.s3.log 2>&1
#

