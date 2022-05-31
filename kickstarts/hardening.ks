# Post-installation script
%post --erroronfail

# Mount the EFI partition
mount /boot/efi

# ANSSI-BP-028 compliance not brought in by OpenSCAP
systemctl enable dnf-automatic.timer                                            # Addresses ANSSI-BP-028-R08
echo 'kernel.modules_disabled = 1' > /etc/sysctl.d/ANSSI-BP-028-R24.conf        # Addresses ANSSI-BP-028-R24

# Addresses ANSSI-BP-028-R57
groupadd wheel
chown root:wheel /usr/bin/sudo

# Addresses ANSSI-BP-028-R67
setsebool -P deny_execmem=on
setsebool -P allow_execheap=off
setsebool -P allow_execmem=off
setsebool -P allow_execstack=off
setsebool -P secure_mode_insmod=on
setsebool -P ssh_sysadm_login=off

# I can't believe this one-liner is making it in prod
# Addresses ANSSI-BP-028-R17
{python3 -c 'print("password_pbkdf2 root")' &  python3 -c 'import string as s; import secrets as x; a=s.ascii_letters+s.digits; p="".join(x.choice(a) for i in range(64)); print(p + "\n" + p)' | grub2-mkpasswd-pbkdf2 | cut -d ' ' -f 7 | sed -r '/^\s*$/d'} | cat | tr '\n' ' ' >> /etc/grub.d/01_users
grub2-mkconfig -o /boot/grub2/grub.cfg

# Addresses ANSSI-BP-028-R11
grub2-editenv - set "$(grub2-editenv - list | grep kernelopts) iommu=force"

# Addresses ANSSI-BP-028-R36
ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
ssh-keygen -q -N "" -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
ssh-keygen -q -N "" -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key
chmod 0600 /etc/ssh/ssh_host_ecdsa_key
chmod 0600 /etc/ssh/ssh_host_ed25519_key
chmod 0600 /etc/ssh/ssh_host_rsa_key

# Disables automounting /boot/efi
sed -i '/efi/ s/nodev/nodev,noauto/g' /etc/fstab

# Addresses ANSSI-BP-028-R39
mkdir -p /etc/tmpfiles.d
echo 'd       /tmp/tmp-inst 0000 root root - -' > /etc/tmpfiles.d/anssi-bp-028-r39.conf
echo '/tmp     /tmp/tmp-inst/            level      root,adm' >> /etc/security/namespace.conf

# Addresses ANSSI-BP-028-R18
sed -i '/rounds=65536/ s/$/ remember=2/' /etc/pam.d/system-auth

# Extra remediation
oscap xccdf eval --remediate --results res.xml --profile %SCAP_PROFILE% %SCAP_CONTENT%
rm res.xml

%end
