# Enable DHCP, set hostname
# Allow SSH and Cockpit
network  --bootproto=dhcp --device=enp0s3 --onboot=on --activate --hostname=alma.lan

# Enable SSH and Cockpit
firewall --enabled --service=ssh --port=9090/tcp