# AlmaLinux, ANSSI-BP-028

Build a disk image that automatically deploys a minimal AlmaLinux 9.2 installation secured to ANSSI-BP-028-HIGH compliance. Zero user interaction required from the moment you power on the device to the moment you can log in. Not a single click.

The image also installs the packages specified in the `packages-to-add.txt` file located at the root of the repository. The packages are downloaded and packaged in a repository built within the image, so there's no need for any networking during the installation process.

The script has been tested on **Alma Linux 9.2**

Read the official ANSSI guides here:

[ANSSI-BP-028 1.2 (FR) (PDF)](https://www.ssi.gouv.fr/uploads/2016/01/linux_configuration-fr-v1.2.pdf)

[ANSSI-BP-028 1.2 (EN) (PDF)](https://www.ssi.gouv.fr/uploads/2019/03/linux_configuration-en-v1.2.pdf)

## Contributing

All contributions are welcome! Check out the OpenSCAP report and addresses all the issues you want. Let's get to 100% compliance **together!**

## Automated build with Docker

The image can be built in an AlmaLinux 9.2 Docker container using the provided Dockerfile.

First pull the `almalinux` Docker image:

`$ docker pull almalinux`

Then build the Docker image for the build environment:

`$ docker build -t almalinux-bp-028-9.2-build:latest`

Now run the build process within the build environment:

`$ docker run -v $(pwd):/app almalinux-bp-028-9.2-build:latest`

## Dependencies

The build process requires `createrepo`, `curl`, `xorriso` and `syslinux` from EPEL:

`# dnf install epel-release && dnf update`

`# dnf install xorriso syslinux createrepo curl`

## Usage

Run the script. You might want to run it as root if you can't use `mktemp`.

`chmod +x build.sh && ./build.sh`

The resulting image will be generated in the `build` directory, along with its SHA256 checksum.

## The deployed system

Two user accounts are created: `root` and `admin`. Their password are `root` and `admin` respectively and will have to be changed after installation. They are not set to automatically expire so as to not break the system at the first log-in.

You will have to manually configure `rsyslog` and its certificates to work with your own journaling system.

OpenSSH and Cockpit are installed and running.

The system drive is mostly encrypted in a LUKS2 container, and is automatically decrypted at startup using a TPM2. There is no passphrase to enter.

## Compliance

**The deployed system does not pass all ANSSI-BP-028-HIGH OpenSCAP tests out of the box.**

An OpenSCAP report (HTML format) can be found at the root of the repository showing the system's compliance. You can recreate the report by running the following commands on a freshly installed system:

`# oscap xccdf eval --results results.xml --profile xccdf_org.ssgproject.content_profile_anssi_bp28_high /usr/share/xml/scap/ssg/content/ssg-almalinux9-ds.xml`

`# oscap xccdf generate report results.xml > report.html`

Note that compliance to ANSSI-BP-028-R67 requires setting the `secure_mode_insmod` variable, which prevents loading kernel modules required by the secure system. The reasoning behind this rule is that the kernel should be compiled according to the orginization's needs, which can be done on Debian (the distribution which is culturally ingrained in ANSSI and French government OPSEC/INFOSEC, see the DGAC secure OS project "inseca" based on Debian) but cannot be done on Red Hat Entreprise Linux due to massive backporting in the kernel.

To allow both critical kernel module operation while maintaining compliance to the rule, the variable is globally set to be FALSE. A systemd unit sets it to TRUE at startup, after the modules have been loaded.

### Depend on user configuration

The system requires configuration and secrets unique to the user's infrastructure for those checks to pass.

* **Explicit arguments in sudo specifications (R63)**: sudo configuration should be brought in by the user.

* **Don't target root user in the sudoers file (R60)**: sudo configuration should be brought in by the user.

* **Configure TLS for rsyslog remote logging (R43)**: It is up to the user to configure the rsyslog server to match their infrastructure.

* **Configure CA certificate for rsyslog remote logging (R43)**: It is up to the user to configure the TLS certificates to match their infrastructure.

### Bugs

* **Set the UEFI Boot Loader Password (R17)**: OpenSCAP reports a failure. Status unknown. To be investigated.

* **TPM decryption setup:** Due to an unidentified upstream issue, automatic TPM decryption must be set up manually after installing the system. To do so, use the password `temppass` to decrypt the disks at boot time, and execute the following commands from a root shell:

`# clevis luks bind -d /dev/vda3 tpm2 '{"pcr_bank":"sha256","pcr_ids":"0,1,2,3,4,5,7,9"}' <<< "temppass"`

`# clevis luks bind -d /dev/vda4 tpm2 '{"pcr_bank":"sha256","pcr_ids":"0,1,2,3,4,5,7,9"}' <<< "temppass"`

You can then remove the temporary LUKS password by using the following commands:

`# cryptsetup luksRemoveKey /dev/vda3 <<< "temppass"`

`# cryptsetup luksRemoveKey /dev/vda4 <<< "temppass"`

Change `vda` to `sda` if you're installing on a bare metal system.

### Maintenance

System maintenance should be minimal and depends on the specific needs of your organization. We do however recommend scheduling automated OpenSCAP compliance checks, and AIDE integrity checks.

Updating the kernel, UEFI firmware, or other components of the TPM chains of trust will lead to changes in PCR values. Such updates therefore require regenerating clevis bindings to account for PCR changes:

`# clevis luks regen -d /dev/vda3 -s 1 tpm2`

`# clevis luks regen -d /dev/vda4 -s 1 tpm2`
