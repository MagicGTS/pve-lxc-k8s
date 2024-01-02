#!/bin/bash
# PreStartRawPassthrough.sh
# Description: Configures LXC container for raw device passthrough before container starts.

# Enabling strict mode for better error handling
set -e -o errexit -o pipefail -o nounset

# Variables set by Proxmox when calling this script
CTID="$1"         # Container ID
runPhase="$2"     # Run phase

# Constants
REGEX_DEVICE_NUMBERS="([0-9]+), ([0-9]+)"
CUSTOM_PARAM="#rawdev="

# Function to output an error message and exit
exit_with_error() {
    echo "Error: $1" >&2
    exit $2
}

# Process based on the run phase
case "$runPhase" in
    pre-start)
        # Enable automatic device management
        echo "lxc.autodev = 1" >> "/var/lib/lxc/${CTID}/config"

        # Process each line in the container configuration
        grep -E "^${CUSTOM_PARAM}" "/etc/pve/lxc/${CTID}.conf" | while IFS='=' read -r -a line; do
            IFS=' ' read -r -a device_info < <(echo "${line[1]}" | xargs)
            [ -z "${device_info[1]}" ] && exit_with_error "Device path is missing" 2

            # Check for device major and minor numbers
            if [[ $(ls -alL "${device_info[0]}") =~ $REGEX_DEVICE_NUMBERS ]]; then
                MAJOR=${BASH_REMATCH[1]}
                MINOR=${BASH_REMATCH[2]}

                # Append device permissions and hook script to the container configuration
                echo "lxc.cgroup2.devices.allow = b ${MAJOR}:${MINOR} rwm" >> "/var/lib/lxc/${CTID}/config"
                echo "lxc.hook.autodev = /var/lib/vz/snippets/DeviceMountHook.sh ${MAJOR} ${MINOR} ${device_info[1]}" >> "/var/lib/lxc/${CTID}/config"
            else
                exit_with_error "No matching device found for ${device_info[0]}" 1
            fi
        done
        ;;
    *)
        exit_with_error "Unknown run phase '$runPhase'" 3
        ;;
esac

exit 0
