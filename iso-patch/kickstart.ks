###
### This kickstart configuration install a SENPAI worker node
###

# Install locally, from CLI
# (it's fast)
text
cdrom
bootloader --append="rhgb quiet crashkernel=auto"

# Automatically accept EULA
eula --agreed

# Reboot after install
# Don't go graphical
# Don't start the first-boot setup thing
reboot
skipx
firstboot --disable

# This partitioning is compliant with
# - ANSSI-BP-028-R12
# - ANSSI-BP-028-R43
# - ANSSI-BP-028-R47
zerombr
ignoredisk --only-use=sda
clearpart --all --initlabel --drives=sda
part    /boot           --fstype=ext4 --ondisk=sda --size=512
part    /boot/efi       --fstype=vfat --ondisk=sda --size=512
part	/               --fstype=ext4 --ondisk=sda --size=8192
part	/home           --fstype=ext4 --ondisk=sda --size=1024
part	/tmp            --fstype=ext4 --ondisk=sda --size=1024
part	/usr            --fstype=ext4 --ondisk=sda --size=8192
part	/var            --fstype=ext4 --ondisk=sda --size=8192
part	/var/tmp        --fstype=ext4 --ondisk=sda --size=4096
part	/var/log        --fstype=ext4 --ondisk=sda --size=4096
part	/var/log/audit  --fstype=ext4 --ondisk=sda --size=4096
part	/opt            --fstype=ext4 --ondisk=sda --size=1024
part	/srv            --fstype=ext4 --ondisk=sda --size=1 --grow

# Locale
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc

# Enable SELinux
selinux --enforcing

# Enable DHCP, set hostname
# Allow SSH and SENPAI through the firewall (SENPAI uses port 1337)
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=alma.lan
firewall --enabled --ssh --port=1337

# User config
rootpw root
user --name=admin --password=admin --groups=wheel

# Select the following packages for installation
repo --name=ondisk --baseurl=file:///run/install/sources/mount-0000-cdrom/ondisk
%packages --excludedocs
@^minimal-environment
@standard
scap-security-guide
%end

# OpenSCAP 
%addon org_fedora_oscap
    content-type = scap-security-guide
    content-path = %SCAP_CONTENT%
    datastream-id = %SCAP_ID_DATASTREAM%
    xccdf-id = %SCAP_ID_XCCDF%
    profile = %SCAP_PROFILE%
%end

# Post-installation script
%post --erroronfail
passwd --expire root
passwd --expire admin
systemctl enable dnf-automatic.timer                                            # Addresses ANSSI-BP-028-R08
echo 'vfat' > /etc/sysctl.d/vfat.conf                                           # Addresses ANSSI-BP-028-R24
echo 'kernel.modules_disabled = 1' > /etc/sysctl.d/ANSSI-BP-028-R24.conf        # Addresses ANSSI-BP-028-R24
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/g' /etc/ssh/sshd_config # Addresses ANSSI-BP-028-R29
sed -i 's/#ClientAliveCountMax/ClientAliveCountMax/g' /etc/ssh/sshd_config      # Addresses ANSSI-BP-028-R29
chown root:wheel /usr/bin/sudo                                                  # Addresses ANSSI-BP-028-R57
setsebool -P deny_execmem off                                                   # Addresses ANSSI-BP-028-R67
%end

# Enable the following services
services --enabled=sshd
