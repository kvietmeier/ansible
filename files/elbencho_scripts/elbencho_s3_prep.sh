#!/bin/bash
# ====================================================================
# Elbencho Prep Script for S3
#
# Description:
#   Prepares the elbencho test environment by creating test files
#   in the provided S3 bucket.
#
# Usage:
#   ./elbencho_s3_prep.sh <NUM_CLIENTS>
#
# Example:
#   ./elbencho_s3_prep.sh 11
#
# Notes:
#   - NUM_CLIENTS determines the client range: client01..clientNN
#   - Files will be created in https://<bucket>/file1, file2, ..., fileN
#   - Results are written to /tmp/elbencho.s3prep.csv and /tmp/elbencho.s3.log
#
# Created By:
#  Karl Vietmeier VAST Data
#  Sven Bruener VAST Data
# ====================================================================

# Parameters with defaults
NUM_CLIENTS=${1:-11}               # Number of clients (default 11)
BUCKET=${2:-s3bucket1}             # Bucket location (default s3bucket1)
FILESIZE=${3:-1G}                  # File size (default 100G)

# S3 Settings - save as ENV variables
export AWS_ACCESS_KEY_ID="X772YOVETW27K34STEV3"                         # Access Key ID
export AWS_SECRET_ACCESS_KEY="IeWlOaYmUM2BgWGh05Uka6tq9Sg/7Um2VrGj5A3Y" # Access Key


echo "Starting elbencho prep with ${NUM_CLIENTS} clients..."
echo "Files will be created in : ${BUCKET}, size: ${FILESIZE}"

# Check bucket exists
#if ! mountpoint -q "$BUCKET"; then
#  echo "ERROR: $BUCKET is not mounted. Please mount first."
#  exit 1
#fi

# Run elbencho prep
elbencho --hosts client[01-${NUM_CLIENTS}] -t 32 --iodepth 4 -b 16M --direct -s "${FILESIZE}" \
  --s3endpoints "https://33.20.1.[11-13]" -w "${BUCKET}/file[1-${NUM_CLIENTS}]" \
  --csvfile /tmp/elbencho.s3prep.csv > /tmp/elbencho.s3.log 2>&1

echo "Prep complete. Log: /tmp/elbencho.s3.log"
