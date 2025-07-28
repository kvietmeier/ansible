#!/bin/bash
# ====================================================================
# Elbencho Prep Script
#
# Description:
#   Prepares the elbencho test environment by creating test files
#   on the shared NFS mount.
#
# Usage:
#   ./elbencho_prep.sh <NUM_CLIENTS>
#
# Example:
#   ./elbencho_prep.sh 11
#
# Notes:
#   - NUM_CLIENTS determines the client range: client01..clientNN
#   - Files will be created in /mount/share1/elbencho-files
# ====================================================================
#!/bin/bash
# ====================================================================
# Elbencho Prep Script
# Creates preallocated files for block size tests
# ====================================================================

# Parameters with defaults
NUM_CLIENTS=${1:-11}             # Number of clients (default 11)
MOUNTPOINT=${2:-/mount/share1}   # Mount location (default /mount/share1)
FILESIZE=${3:-100G}              # File size (default 100G)

# Test files directory
EB_FILES="${MOUNTPOINT}/elbencho-files"

echo "Starting elbencho prep with ${NUM_CLIENTS} clients..."
echo "Files will be created under: ${EB_FILES}, size: ${FILESIZE}"

# Check mount exists
if ! mountpoint -q "$MOUNTPOINT"; then
  echo "ERROR: $MOUNTPOINT is not mounted. Please mount first."
  exit 1
fi

# Run elbencho prep
elbencho --hosts client[01-${NUM_CLIENTS}] \
  -t 32 --iodepth 4 -b 1M --direct -s "${FILESIZE}" \
  -w "${EB_FILES}/file[1-10]" \
  --csvfile /tmp/elbenchoprep.csv > /tmp/elbencho.log 2>&1

echo "Prep complete. Log: /tmp/elbencho.log"
