#!/bin/bash
# DeviceMountHook.sh
# Description: Creates a device node within the LXC container for device mounting.

# Enabling strict mode for better error handling
set -e -o errexit -o pipefail -o nounset

# Extracting and validating input parameters
MAJOR=${1:-}
MINOR=${2:-}
DST=${3:-}
LXC_ROOTFS_MOUNT=${LXC_ROOTFS_MOUNT:-}

# Function to display error message and exit
exit_with_error() {
    echo "Error: $1" >&2
    exit $2
}

# Validating inputs
[ -z "${MAJOR}" ] && exit_with_error "Missing major device number" 1
[ -z "${MINOR}" ] && exit_with_error "Missing minor device number" 2
[ -z "${DST}" ] && exit_with_error "Missing destination path" 3

# Create the device node
mknod -m 777 "${LXC_ROOTFS_MOUNT}${DST}" b "${MAJOR}" "${MINOR}"