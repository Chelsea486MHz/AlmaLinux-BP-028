# Post-installation script
%post --erroronfail

# Set the TTY banner
echo '' > /etc/issue
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

# Remove the cockpit message
rm -f /etc/motd.d/cockpit
rm -f /etc/issue.d/cockpit

# Enable the following services
systemctl enable sshd
systemctl enable cockpit.socket

%end
