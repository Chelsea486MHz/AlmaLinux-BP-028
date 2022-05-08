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
part	/boot		--fstype=xfs	--ondisk=sda	--size=1024
part	/boot/efi       --fstype=efi	--ondisk=sda	--size=1024
part    swap 				--ondisk=sda	--size=4096
part    pv.01				--ondisk=sda	--size=1	--grow
volgroup vg_root pv.01
logvol  /               --vgname=vg_root --size=4096 --name=lv_root
logvol  /home           --vgname=vg_root --size=4096 --name=lv_home
logvol  /usr            --vgname=vg_root --size=4096 --name=lv_usr
logvol  /tmp            --vgname=vg_root --size=4096 --name=lv_tmp
logvol  /var            --vgname=vg_root --size=4096 --name=lv_var
logvol  /var/tmp        --vgname=vg_root --size=4096 --name=lv_var_tmp
logvol  /var/log        --vgname=vg_root --size=4096 --name=lv_var_log
logvol  /var/log/audit  --vgname=vg_root --size=4096 --name=lv_var_log_audit
logvol  /srv            --vgname=vg_root --size=4096 --name=lv_srv
logvol  /opt            --vgname=vg_root --size=4096 --name=lv_opt

# Locale
lang en_US.UTF-8
keyboard us
timezone Etc/UTC --isUtc

# Enable SELinux
selinux --enforcing

# Enable DHCP, set hostname
# Allow SSH and Cockpit
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=alma.lan
firewall --enabled --ssh --port=9090

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



# OpenSCAP parameters
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

# Set the banner !
echo '' > /etc/issue
echo ' '                                                      >> /etc/issue
echo '     ___    __                __    _                 ' >> /etc/issue
echo '    /   |  / /___ ___  ____ _/ /   (_)___  __  ___  __' >> /etc/issue
echo '   / /| | / / __ `__ \/ __ `/ /   / / __ \/ / / / |/_/' >> /etc/issue
echo '  / ___ |/ / / / / / / /_/ / /___/ / / / / /_/ />  <  ' >> /etc/issue
echo ' /_/  |_/_/_/ /_/ /_/\__,_/_____/_/_/ /_/\__,_/_/|_|  ' >> /etc/issue
echo '   ANSSI-BP-028 COMPLIANT'                              >> /etc/issue
echo ''                                                       >> /etc/issue

# Set it for SSH and cockpit
sed -i 's/#Banner none/Banner \/etc\/issue/g'
cp /etc/issue /etc/issue.cockpit

# ANSSI-BP-028 compliance not brought in by OpenSCAP
systemctl enable dnf-automatic.timer                                            # Addresses ANSSI-BP-028-R08
echo 'kernel.modules_disabled = 1' > /etc/sysctl.d/ANSSI-BP-028-R24.conf        # Addresses ANSSI-BP-028-R24
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/g' /etc/ssh/sshd_config # Addresses ANSSI-BP-028-R29
sed -i 's/#ClientAliveCountMax/ClientAliveCountMax/g' /etc/ssh/sshd_config      # Addresses ANSSI-BP-028-R29
chown root:wheel /usr/bin/sudo                                                  # Addresses ANSSI-BP-028-R57
setsebool -P deny_execmem off                                                   # Addresses ANSSI-BP-028-R67

# Enable the following services
systemctl enable sshd
systemctl enable cockpit

# Eject the disk
/usr/bin/eject -i 0
/usr/bin/eject -r

# Reboot
reboot

%end
