# README.md for Kubernetes Node on PVE LXC Container, ZFS inside LXC

## Overview
This repository contains scripts to facilitate running Kubernetes (k8s) nodes inside Proxmox Virtual Environment (PVE) LXC containers. These scripts handle the mounting of devices, container configuration, and system initialization to ensure compatibility and functionality of Kubernetes within an LXC container.
Inspired by [Kubernetes inside Proxmox LXC](https://kevingoos.medium.com/kubernetes-inside-proxmox-lxc-cce5c9927942)

### Scripts Description and Usage

#### 1. `DeviceMountHook.sh`
- **Purpose**: This script creates a device node within the LXC container. It's used to mount devices from the host to the container.
- **Usage**: Automatically invoked by other scripts. Requires three parameters: Major device number, Minor device number, and Destination path.

#### 2. `PreStartRawPassthrough.sh`
- **Purpose**: Sets up the LXC container configuration for Kubernetes, allowing raw device passthrough and setting up necessary hooks.
- **Usage**: Configured to run before the container starts. It modifies the LXC configuration based on provided device information.

#### 3. `ContainerK8sConfigSegment.conf`
- **Purpose**: This is a segment of the LXC container configuration specific to running Kubernetes.
- **Usage**: To be added to the LXC container configuration file.

#### 4. `rc.local`
- **Container init script**: `/etc/rc.local`
- **Purpose**: Initializes the Kubernetes environment within the LXC container. It creates a symlink for `/dev/kmsg` and adjusts mount points.
- **Usage**: This script should be placed in `/etc/rc.local` inside the LXC container to run at startup.

### Detailed Instructions

1. **Setting Up Device Mount Hook**:
   - Copy `DeviceMountHook.sh` to `/var/lib/vz/snippets/`.
   - Ensure it's executable: `chmod +x /var/lib/vz/snippets/DeviceMountHook.sh`.

2. **Configuring Pre-Start Raw Passthrough**:
   - Place `PreStartRawPassthrough.sh` in `/var/lib/vz/snippets/`.
   - Update the container configuration to include `hookscript: local:snippets/PreStartRawPassthrough.sh`.

3. **Container Configuration for Kubernetes**:
   - Add the `ContainerK8sConfigSegment.conf` to your container's configuration file, typically located at `/etc/pve/lxc/<container_id>.conf`.

4. **Initializing Kubernetes in the Container**:
   - Add or replace the existing `/etc/rc.local` in the LXC container with `rc.local`.
   - Ensure the script is executable and properly configured.

### Notes
- It is crucial to follow the sequence of steps for proper setup.
- Make sure that all scripts are executable and have the correct permissions.
- To specify which device you wish to passthrough in PVE, it is necessary to include a comment section in the container configuration file. This section should be formatted as follows: ```#rawdev=<path to the raw device on the host system> <path to the raw device within the container>```. The lines for this section typically start with the # character, especially if they are at the end of the configuration file. Additionally, if you plan to create and utilize a partition on this device, you must also passthrough all associated partition devices.

## ZFS inside PVE LXC
To enable ZFS passthrough in a container, first ensure that ZFS utilities are installed. A convenient approach is to use the Debian 12 container template and add the PVE repository:

1. Copy the contents of `/etc/apt/trusted.gpg.d` and `/etc/apt/sources.list` into the corresponding paths inside the container.
2. To circumvent installing kernel packages in the container, you have two options:
   - Either copy the contents of `/usr/lib/modules/<kernel version>` into the container.
   - Or create a mount point in the container configuration like so:
     ```
     lxc.mount.entry: /usr/lib/modules/ usr/lib/modules/ none rbind,create=dir,optional 0 0
     ```
3. Execute `apt update` and install necessary ZFS packages:
```
apt install -y libzfs4linux zfs-initramfs zfs-zed zfsutils-linux
```
4. Next, disable specific units to avoid conflicts:
```
systemctl disable --now zfs-import-cache.service zfs-import.target zfs-mount.service zfs-share.service zfs-volume-wait.service zfs-volumes.target zfs.target zed.service systemd-binfmt.service zfs-volume-wait.service systemd-rfkill.socket
systemctl mask systemd-udevd systemd-udevd-control.socket systemd-udevd-kernel.socket zfs-mount.service console-setup.service
```
5. Add the following line to `/etc/rc.local` to load ZFS modules:
```
modprobe zfs
```
6. Restart the container. This step grants access to the entire ZFS pool within the container.
