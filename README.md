# AlmaLinux, ANSSI-BP-028

Build a disk image that automatically deploys a minimal AlmaLinux 8.6 installation secured to ANSSI-BP-028-HIGH compliance. Zero user interaction required from the moment you power on the device to the moment you can log in. Not a single click.

The image also installs the packages specified in the `packages-to-add.txt` file located at the root of the repository. The packages are downloaded and packaged in a repository built within the image, so there's no need for any networking during the installation process.

The script has been tested on **Alma Linux 8.6**

Read the official ANSSI guides here:

[ANSSI-BP-028 1.2 (FR) (PDF)](https://www.ssi.gouv.fr/uploads/2016/01/linux_configuration-fr-v1.2.pdf)

[ANSSI-BP-028 1.2 (EN) (PDF)](https://www.ssi.gouv.fr/uploads/2019/03/linux_configuration-en-v1.2.pdf)

## Contributing

All contributions are welcome! Check out the OpenSCAP report and addresses all the issues you want. Let's get to 100% compliance **together!**

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

## Compliance

**The deployed system does not pass all ANSSI-BP-028-HIGH OpenSCAP tests out of the box.**

An OpenSCAP report (HTML format) can be found at the root of the repository showing the system's compliance. You can recreate the report by running the following commands on a freshly installed system:

`# oscap xccdf eval --results results.xml --profile xccdf_org.ssgproject.content_profile_anssi_bp28_high /usr/share/xml/scap/ssg/content/ssg-almalinux8-ds-1.2.xml`

`# oscap xccdf generate report results.xml > report.html`

### False positives

These checks are reported as failed, but should be reported as passing. This is due to issues with OpenSCAP.

* **Ensure a dedicated group owns sudo (R57)**: You can manually verify this rule with the following command: `ls -l /usr/bin | grep sudo`. The group *wheel* owns the binary.

* **IOMMU configuration directive (R11)**: You can manually verify iommu usage is enforced with the following command: `dmesg | grep iommu=force`

### Depend on user configuration

The system requires configuration and secrets unique to the user's infrastructure for those checks to pass.

* **Explicit arguments in sudo specifications (R63)**: sudo configuration should be brought in by the user.

* **Don't target root user in the sudoers file (R60)**: sudo configuration should be brought in by the user.

* **Configure TLS for rsyslog remote logging (R43)**: It is up to the user to configure the rsyslog server to match their infrastructure.

* **Configure CA certificate for rsyslog remote logging (R43)**: It is up to the user to configure the TLS certificates to match their infrastructure.
