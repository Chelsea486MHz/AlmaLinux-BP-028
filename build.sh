#!/bin/bash

# Resets the line
LINE_RESET='\e[2K\r'

# Terminal escape codes to color text
TEXT_GREEN='\e[032m'
TEXT_YELLOW='\e[33m'
TEXT_RED='\e[31m'
TEXT_RESET='\e[0m'

# Logs like systemd on startup, it's pretty
TEXT_INFO="[${TEXT_YELLOW}i${TEXT_RESET}]"
TEXT_FAIL="[${TEXT_RED}-${TEXT_RESET}]"
TEXT_SUCC="[${TEXT_GREEN}+${TEXT_RESET}]"



####
#### VARIABLES
####



# Information regarding the upstream AlmaLinux ISO
ALMA_MIRROR="http://mirror.rackspeed.de" #Set it to whichever you want
ALMA_RELEASE="9.2"
ALMA_ARCH="x86_64"
ALMA_FLAVOR="minimal" #Can be either "minimal", "dvd", or "boot"
ALMA_URL="${ALMA_MIRROR}/almalinux/${ALMA_RELEASE}/isos/${ALMA_ARCH}/AlmaLinux-${ALMA_RELEASE}-${ALMA_ARCH}-${ALMA_FLAVOR}.iso"

# Build information
WORKING_DIR=`pwd`
LOGFILE="${WORKING_DIR}/buildlog.txt"     # Where this script will log stuff
TMPDIR=`mktemp -d`                        # The temporary work directory
NEW_ISO_ROOT="${TMPDIR}/isoroot"          # The root of the new ISO to build. Subdir of TMPDIR
ISO_PATCH_PATH="${WORKING_DIR}/iso-patch" # The content of the directory will be copied to the root of the ISO before building

# Information regarding the local AlmaLinux ISO
ALMA_LOCAL_DIR="${WORKING_DIR}/AlmaLinux"
ALMA_LOCAL_NAME="AlmaLinux-${ALMA_RELEASE}-${ALMA_ARCH}-${ALMA_FLAVOR}.iso"
ALMA_LOCAL="${ALMA_LOCAL_DIR}/${ALMA_LOCAL_NAME}"

# Information regarding the ISO patch to apply
PATH_KICKSTARTS="${WORKING_DIR}/kickstarts"
PATH_KICKSTART_MAIN="${NEW_ISO_ROOT}/kickstart.ks"
PATH_KICKSTART_HARD="${NEW_ISO_ROOT}/hardening.ks"
PATH_KICKSTART_SCAP="${NEW_ISO_ROOT}/openscap.ks"
PATH_KICKSTART_PACK="${NEW_ISO_ROOT}/packages.ks"
PATH_KICKSTART_PART="${NEW_ISO_ROOT}/partitioning.ks"
PATH_KICKSTART_POST="${NEW_ISO_ROOT}/post.ks"
PATH_KICKSTART_USER="${NEW_ISO_ROOT}/users.ks"
PATH_REPO="${NEW_ISO_ROOT}/ondisk"
PACKAGES_TO_ADD=`cat packages-to-add.txt`
TARGET_BLOCK_DEVICE="vda" # Use vda if you're deploying on a VM with virtio storage

# OpenSCAP / Compliance As Code (CAC) profile to apply
SCAP_CONTENT="/usr/share/xml/scap/ssg/content/ssg-almalinux9-ds.xml"
SCAP_ID_DATASTREAM="scap_org.open-scap_datastream_from_xccdf_ssg-almalinux9-xccdf.xml"
SCAP_ID_XCCDF="scap_org.open-scap_cref_ssg-almalinux9-xccdf.xml"
SCAP_PROFILE="xccdf_org.ssgproject.content_profile_anssi_bp28_enhanced"

# Information regarding the to-be-built ISO
NEW_ISO_VERSION="${ALMA_RELEASE}"
NEW_ISO_RELEASE="1"
NEW_ISO_ARCH="x86_64"
NEW_ISO_LABEL="AlmaLinux-ANSSI-BP-028"
NEW_ISO_NAME="${NEW_ISO_LABEL}-${NEW_ISO_VERSION}-${NEW_ISO_RELEASE}-${NEW_ISO_ARCH}.iso"
NEW_ISO_DIR="./build"
NEW_ISO="${NEW_ISO_DIR}/${NEW_ISO_NAME}"
NEW_SHA="${NEW_ISO}.sha256sum"

# Those are the flags used to rebuild the ISO image
MKISOFS_FLAGS="-o ${NEW_ISO} \
	-b isolinux/isolinux.bin \
	-c isolinux/boot.cat \
	--no-emul-boot \
	--boot-load-size 4 \
	--boot-info-table \
	-eltorito-alt-boot \
	-e images/efiboot.img \
	-graft-points EFI/BOOT=${NEW_ISO_ROOT}/EFI/BOOT images/efiboot.img=${NEW_ISO_ROOT}/images/efiboot.img \
	-no-emul-boot \
        -J \
	-R \
	-V ${NEW_ISO_LABEL} \
	${NEW_ISO_ROOT}"



####
#### VARIABLES
####



# Print the banner
echo '    ___    __                __    _                 '
echo '   /   |  / /___ ___  ____ _/ /   (_)___  __  ___  __'
echo '  / /| | / / __ `__ \/ __ `/ /   / / __ \/ / / / |/_/'
echo ' / ___ |/ / / / / / / /_/ / /___/ / / / / /_/ />  <  '
echo '/_/  |_/_/_/ /_/ /_/\__,_/_____/_/_/ /_/\__,_/_/|_|  '
echo ' ANSSI-BP-028 COMPLIANT'
echo ' '
echo "=> Builds an ANSSI-BP-028 compliant installation ISO from AlmaLinux 9.2"
echo "=> AlmaLinux: https://almalinux.org/"
echo ' '



# Clear the build log file
echo "===Buildlog===" > ${LOGFILE}



# Check if the local AlmaLinux directory exists
echo -n -e "${TEXT_INFO} Checking if the local AlmaLinux directory exists..."
if [ ! -d ${ALMA_LOCAL_DIR} ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_INFO} Local AlmaLinux directory doesn't exist: creating ${ALMA_LOCAL_DIR}"
	mkdir ${ALMA_LOCAL_DIR}
fi



# Check if the ISO exists
echo -n -e "${TEXT_INFO} Checking if the AlmaLinux ISO has already been downloaded..."
if [ ! -f ${ALMA_LOCAL} ]; then
	echo -n -e "${LINE_RESET}"
	echo -n -e "${TEXT_INFO} Downloading the upstream AlmaLinux ISO"
	curl -o ${ALMA_LOCAL} ${ALMA_URL} &>> ${LOGFILE}
	if [ $? -ne 0 ]; then
		echo -n -e "${LINE_RESET}"
		echo -e "${TEXT_FAIL} Failed to download the upstream AlmaLinux ISO"
		rm -rf ${TMPDIR}
		exit 255
	else
		echo -n -e "${LINE_RESET}"
		echo -e "${TEXT_SUCC} Downloaded the upstream AlmaLinux ISO"
	fi
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_INFO} Using previously downloaded AlmaLinux ISO"
fi



# Create the new ISO root dir in the tmpdir
echo -n -e "${TEXT_INFO} Creating a new ISO root directory"
mkdir ${NEW_ISO_ROOT}
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Failed to create new ISO root directory"
	rm -rf ${TMPDIR}
        exit 255
else
	echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Created new ISO root directory"
fi



# Extract the AlmaLinux ISO to the temporary directory
echo -n -e "${TEXT_INFO} Extracting the AlmaLinux ISO..."
xorriso -osirrox on -indev ${ALMA_LOCAL} -extract / ${NEW_ISO_ROOT} &>> ${LOGFILE}
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_FAIL} Failed to extract AlmaLinux ISO"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_SUCC} Extracted the AlmaLinux ISO"
fi



# Patch the ISO
echo -n -e "${TEXT_INFO} Patching the AlmaLinux ISO..."
cp -r ${ISO_PATCH_PATH}/* ${NEW_ISO_ROOT}/
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_FAIL} Failed to patch the AlmaLinux ISO"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_SUCC} Patched the AlmaLinux ISO"
fi



####
#### KICKSTARTS
####



# Copy the kickstarts
echo -n -e "${TEXT_INFO} Installing the kickstarts..."
cp -r ${PATH_KICKSTARTS}/*.ks ${NEW_ISO_ROOT}/
if [ $? -ne 0 ]; then
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Failed to install the kickstarts"
        rm -rf ${TMPDIR}
        exit 255
else
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Installed the kickstarts"
fi



# Configure the kickstarts

echo -e "${TEXT_INFO} Starting kickstart configuration..."

# Configure the main kickstart
sed -i "s/%TARGET_BLOCK_DEVICE%/${TARGET_BLOCK_DEVICE}/g" ${PATH_KICKSTART_MAIN}
echo -e "${TEXT_SUCC} => Configured the main kickstart"

# Configure the OpenSCAP kickstart
sed -i "s/%SCAP_PROFILE%/${SCAP_PROFILE}/g" ${PATH_KICKSTART_SCAP}
sed -i "s|%SCAP_CONTENT%|${SCAP_CONTENT}|g" ${PATH_KICKSTART_SCAP}
sed -i "s/%SCAP_ID_DATASTREAM%/${SCAP_ID_DATASTREAM}/g" ${PATH_KICKSTART_SCAP}
sed -i "s/%SCAP_ID_XCCDF%/${SCAP_ID_XCCDF}/g" ${PATH_KICKSTART_SCAP}
echo -e "${TEXT_SUCC} => Configured the OpenSCAP kickstart"

# Configure the hardening kickstart
sed -i "s/%TARGET_BLOCK_DEVICE%/${TARGET_BLOCK_DEVICE}/g" ${PATH_KICKSTART_HARD}
sed -i "s/%SCAP_PROFILE%/${SCAP_PROFILE}/g" ${PATH_KICKSTART_HARD}
sed -i "s|%SCAP_CONTENT%|${SCAP_CONTENT}|g" ${PATH_KICKSTART_HARD}
echo -e "${TEXT_SUCC} => Configured the hardening kickstart"

# Configure the partitioning kickstart
sed -i "s/%TARGET_BLOCK_DEVICE%/${TARGET_BLOCK_DEVICE}/g" ${PATH_KICKSTART_PART}
echo -e "${TEXT_SUCC} => Configured the partitioning kickstart"

# We're done
echo -e "${TEXT_SUCC} Configured all kickstarts"



# Configure ISOLINUX
sed -i "s/%NEW_ISO_LABEL%/${NEW_ISO_LABEL}/g" ${NEW_ISO_ROOT}/isolinux/isolinux.cfg
sed -i "s/%PATH_KICKSTART_MAIN%/kickstart.ks/g" ${NEW_ISO_ROOT}/isolinux/isolinux.cfg
sed -i "s/%ALMA_VERSION%/${ALMA_RELEASE}/g" ${NEW_ISO_ROOT}/isolinux/isolinux.cfg
sed -i "s/%NEW_ISO_LABEL%/${NEW_ISO_LABEL}/g" ${NEW_ISO_ROOT}/isolinux/grub.conf
sed -i "s/%PATH_KICKSTART_MAIN%/kickstart.ks/g" ${NEW_ISO_ROOT}/isolinux/grub.conf
sed -i "s/%ALMA_VERSION%/${ALMA_RELEASE}/g" ${NEW_ISO_ROOT}/isolinux/grub.conf
echo -e "${TEXT_SUCC} Configured ISOLINUX"



# Configure GRUB2
sed -i "s/%NEW_ISO_LABEL%/${NEW_ISO_LABEL}/g" ${NEW_ISO_ROOT}/EFI/BOOT/grub.cfg
sed -i "s/%PATH_KICKSTART_MAIN%/kickstart.ks/g" ${NEW_ISO_ROOT}/EFI/BOOT/grub.cfg
sed -i "s/%ALMA_VERSION%/${ALMA_RELEASE}/g" ${NEW_ISO_ROOT}/EFI/BOOT/grub.cfg
echo -e "${TEXT_SUCC} Configured GRUB2"



# Create the on-disk repo
echo -n -e "${TEXT_INFO} Creating the on-disk repo..."
mkdir -p ${PATH_REPO}/Packages
if [ $? -ne 0 ]; then
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Couldn't create the on-disk repo"
        rm -rf ${TMPDIR}
        exit 255
else
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Created the on-disk repo"
fi



# Download the packages
echo -n -e "${TEXT_INFO} Downloading the packages..."
pushd ${PATH_REPO}/Packages &>> ${LOGFILE}
dnf download ${PACKAGES_TO_ADD} &>> ${LOGFILE}
if [ $? -ne 0 ]; then
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Couldn't download the packages"
        rm -rf ${TMPDIR}
        exit 255
else
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Downloaded the packages"
fi
popd &>> ${LOGFILE}



# Generate the repodata information
echo -n -e "${TEXT_INFO} Generating the repodata..."
createrepo ${PATH_REPO} &>> ${LOGFILE}
if [ $? -ne 0 ]; then
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Couldn't generate the repodata"
        rm -rf ${TMPDIR}
        exit 255
else
        echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Generated the repodata"
fi



# Check if the build folder exists
echo -n -e "${TEXT_INFO} Checking if the build folder exists..."
if [ ! -d ${NEW_ISO_DIR} ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_INFO} Build folder doesn't exist. Creating"
        mkdir ${NEW_ISO_DIR}
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_INFO} Detected existing build folder. Cleaning up"
	rm -rf ${NEW_ISO_DIR}/*
fi



# Rebuild a bootable ISO
echo -n -e "${TEXT_INFO} Building the new ISO..."
mkisofs ${MKISOFS_FLAGS} &>> ${LOGFILE}
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_FAIL} Couldn't build the new ISO"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_SUCC} Built the new ISO"
fi



# Run isohybrid
echo -n -e "${TEXT_INFO} Making the ISO bootable..."
isohybrid --uefi ${NEW_ISO} &>> ${LOGFILE}
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_FAIL} Couldn't make ISO bootable"
	rm -rf ${TMPDIR}
	exit 255
else
	echo -n -e "${LINE_RESET}"
	echo -e "${TEXT_SUCC} Made the ISO bootable"
fi



# Compute the new ISO's checksum
echo -n -e "${TEXT_INFO} Computing the ISO checksum..."
sha256sum ${NEW_ISO} > ${NEW_SHA}
if [ $? -ne 0 ]; then
	echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_FAIL} Couldn't compute the SHA256"
        rm -rf ${TMPDIR}
        exit 255
else
	echo -n -e "${LINE_RESET}"
        echo -e "${TEXT_SUCC} Computed the SHA256"
fi



# We're done! Let's clean up
echo -e "${TEXT_SUCC} Script succeeded. Cleaning up."
rm -rf ${TMPDIR}
echo "===Buildlog===" >> ${LOGFILE}

