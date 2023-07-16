# Post-installation script
%post --erroronfail

##
## Due to an upstream issue related to TPM binding for LUKS decryption,
## the commands removing the temporary password have been commented out.
##

## Use TPM for LUKS2
clevis luks bind -d /dev/%TARGET_BLOCK_DEVICE%3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"0,1,7"}' <<< "temppass"
clevis luks bind -d /dev/%TARGET_BLOCK_DEVICE%4 tpm2 '{"pcr_bank":"sha256","pcr_ids":"0,1,7"}' <<< "temppass"
#cryptsetup luksRemoveKey /dev/%TARGET_BLOCK_DEVICE%3 <<< "temppass"
#cryptsetup luksRemoveKey /dev/%TARGET_BLOCK_DEVICE%4 <<< "temppass"
systemctl enable clevis-luks-askpass.path
dracut -fv --regenerate-all

# Addresses ANSSI-BP-028-R08
systemctl enable dnf-automatic.timer

# I can't believe this one-liner is making it in prod
# Addresses ANSSI-BP-028-R17
{python3 -c 'print("password_pbkdf2 root")' &  python3 -c 'import string as s; import secrets as x; a=s.ascii_letters+s.digits; p="".join(x.choice(a) for i in range(64)); print(p + "\n" + p)' | grub2-mkpasswd-pbkdf2 | cut -d ' ' -f 7 | sed -r '/^\s*$/d'} | cat | tr '\n' ' ' >> /etc/grub.d/01_users
grub2-mkconfig -o /boot/grub2/grub.cfg

# Addresses ANSSI-BP-028-R18
sed -i '/rounds=65536/ s/$/ remember=2/' /etc/pam.d/system-auth

# Addresses ANSSI-BP-028-R24
echo 'kernel.modules_disabled = 1' > /etc/sysctl.d/ANSSI-BP-028-R24.conf

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

# Extra remediation
oscap xccdf eval --remediate --results res.xml --profile %SCAP_PROFILE% %SCAP_CONTENT%
rm res.xml

%end
