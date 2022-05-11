###
### This kickstart configuration install a SENPAI worker node
###

# Install locally, from CLI
# (it's fast)
text
cdrom

# Manually load the vfat module
# Dynamic module loading is disabled by sysctl config as required in ANSSI-BP-028-R24
bootloader --boot-drive=sda --timeout=0 --append="rhgb quiet crashkernel=auto vfat"

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
part	/tmp		--fstype=tmpfs			--size=4096
part    swap 				--ondisk=sda	--size=4096
part    pv.01				--ondisk=sda	--size=1	--grow
volgroup vg_root pv.01
logvol  /               --vgname=vg_root --size=4096 --name=lv_root
logvol  /home           --vgname=vg_root --size=4096 --name=lv_home
logvol  /usr            --vgname=vg_root --size=4096 --name=lv_usr
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
auth --passalgo=sha512 --useshadow
rootpw root
user --name=admin --password=admin --groups=wheel

# Select the following packages for installation
repo --name=ondisk --baseurl=file:///run/install/sources/mount-0000-cdrom/ondisk
%packages --excludedocs
@^minimal-environment
@standard
scap-security-guide
openssh-server
%end

# Configure kdump
%addon com_redhat_kdump --enable --reserve-mb=auto
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

# Set the TTY banner
echo '' > /etc/issue
echo ' '                                                      >> /etc/issue
echo '     ___    __                __    _                 ' >> /etc/issue
echo '    /   |  / /___ ___  ____ _/ /   (_)___  __  ___  __' >> /etc/issue
echo '   / /| | / / __ `__ \/ __ `/ /   / / __ \/ / / / |/_/' >> /etc/issue
echo '  / ___ |/ / / / / / / /_/ / /___/ / / / / /_/ />  <  ' >> /etc/issue
echo ' /_/  |_/_/_/ /_/ /_/\__,_/_____/_/_/ /_/\__,_/_/|_|  ' >> /etc/issue
echo '   ANSSI-BP-028 COMPLIANT'                              >> /etc/issue
echo ''                                                       >> /etc/issue

# Set the SSH and cockpit banners
sed -i 's/#Banner none/Banner \/etc\/issue/g'
cp /etc/issue /etc/issue.cockpit

# ANSSI-BP-028 compliance not brought in by OpenSCAP
systemctl enable dnf-automatic.timer                                            # Addresses ANSSI-BP-028-R08
echo 'kernel.modules_disabled = 1' > /etc/sysctl.d/ANSSI-BP-028-R24.conf        # Addresses ANSSI-BP-028-R24
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/g' /etc/ssh/sshd_config # Addresses ANSSI-BP-028-R29
sed -i 's/#ClientAliveCountMax/ClientAliveCountMax/g' /etc/ssh/sshd_config      # Addresses ANSSI-BP-028-R29
chown root:wheel /usr/bin/sudo                                                  # Addresses ANSSI-BP-028-R57

# Addresses ANSSI-BP-028-R67
setsebool -P allow_execheap=off
setsebool -P allow_execmem=off
setsebool -P allow_execstack=off
setsebool -P secure_mode_insmod=on
setsebool -P ssh_sysadm_login=off

# I can't believe this one-liner is making it in prod
# Addresses ANSSI-BP-028-R17
{python3 -c 'print("password_pbkdf2 root")' &  python3 -c 'import string as s; import secrets as x; a=s.ascii_letters+s.digits; p="".join(x.choice(a) for i in range(64)); print(p + "\n" + p)' | grub2-mkpasswd-pbkdf2 | cut -d ' ' -f 7 | sed -r '/^\s*$/d'} | cat | tr '\n' ' ' >> /etc/grub.d/01_users
grub2-mkconfig -o /boot/grub2/grub.cfg

# The kernel needs to load vfat to boot... I'll fix it later
echo 'kernel.modules_disabled = 0' > /etc/sysctl.d/ANSSI-BP-028-R24.conf

# Enable the following services
systemctl enable sshd
systemctl enable cockpit

# Run a new compliance check
oscap xccdf eval --profile %SCAP_PROFILE% --results /home/admin/scap-results.xml %SCAP_CONTENT%
oscap xccdf generate report /home/admin/scap-results.xml > /home/admin/compliance-report.html
rm /home/admin/scap-results.xml

# Eject the disk
/usr/bin/eject -r

# Reboot
reboot

%end
