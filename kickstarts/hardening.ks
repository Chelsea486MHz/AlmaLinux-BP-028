# Post-installation script
%post --erroronfail

# ANSSI-BP-028 compliance not brought in by OpenSCAP
systemctl enable dnf-automatic.timer                                            # Addresses ANSSI-BP-028-R08
echo 'kernel.modules_disabled = 1' > /etc/sysctl.d/ANSSI-BP-028-R24.conf        # Addresses ANSSI-BP-028-R24
chown root:wheel /usr/bin/sudo                                                  # Addresses ANSSI-BP-028-R57

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
grub2-mkconfig -o /boot/efi/EFI/almalinux/grub.cfg # Update the config for UEFI
grub2-mkconfig -o /boot/grub2/grub.cfg             # And for BIOS

# Addresses ANSSI-BP-028-R11
grub2-editenv - set "$(grub2-editenv - list | grep kernelopts) iommu=force"

# Addresses ANSSI-BP-028-R36
sudo chmod 0600 /etc/ssh/*_key

# Disables automounting /boot and /boot/efi
sed -i '/boot/ s/nodev/nodev,noauto/g' /etc/fstab

%end
