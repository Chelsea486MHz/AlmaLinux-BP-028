# Install locally, from CLI
# (it's fast)
text
cdrom

# GRUB2 configuration
bootloader --boot-drive=%TARGET_BLOCK_DEVICE% --timeout=0 --append="rhgb quiet crashkernel=256M"

# Automatically accept EULA
eula --agreed

# Reboot after install
# Don't go graphical
# Don't start the first-boot setup thing
reboot
skipx
firstboot --disable

# Locale
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc

# Enable SELinux
selinux --enforcing

# Configure kdump
%addon com_redhat_kdump --enable --reserve-mb=auto
%end

# Enable DHCP, set hostname
# Allow SSH and Cockpit
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=alma.lan
firewall --enabled --ssh --port=9090

# Set up the partitions
%include /mnt/install/repo/partitioning.ks

# User config
%include /mnt/install/repo/users.ks

# Package selection
%include /mnt/install/repo/packages.ks

# OpenSCAP hardening
%include /mnt/install/repo/openscap.ks

# Hardening post-install script
%include /mnt/install/repo/hardening.ks

# General post-install script
%include /mnt/install/repo/post.ks
