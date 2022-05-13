# Select the following packages for installation
repo --name=ondisk --baseurl=file:///run/install/sources/mount-0000-cdrom/ondisk
%packages --excludedocs
@^minimal-environment
@standard
%PACKAGES_TO_ADD%
%end
