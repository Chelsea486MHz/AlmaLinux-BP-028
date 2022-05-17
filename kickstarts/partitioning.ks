# This partitioning is compliant with
# - ANSSI-BP-028-R12
# - ANSSI-BP-028-R43
# - ANSSI-BP-028-R47
zerombr
ignoredisk --only-use=%TARGET_BLOCK_DEVICE%
clearpart --all --initlabel --drives=%TARGET_BLOCK_DEVICE%
part	/boot		--fstype=xfs	--ondisk=%TARGET_BLOCK_DEVICE%	--size=1024
part	/boot/efi       --fstype=efi	--ondisk=%TARGET_BLOCK_DEVICE%	--size=1024
part	/tmp		--fstype=tmpfs			--size=4096
part    swap 				--ondisk=%TARGET_BLOCK_DEVICE%	--size=4096
part    pv.01				--ondisk=%TARGET_BLOCK_DEVICE%	--size=1	--grow
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
