# AlmaLinux, ANSSI-BP-028

Build a disk image that automatically deploys a minimal AlmaLinux 8.5 installation secured to ANSSI-BP-028-HIGH compliance. Zero user interaction required from the moment you power on the device to the moment you can log in. Not a single click.

The image also installs the packages specified in the `packages-to-add.txt` file located at the root of the repository. The packages are downloaded and packaged in a repository built within the image, so there's no need for any networking during the installation process.

The script has been tested on **Alma Linux 8.5**

Read the official ANSSI guides here:

[ANSSI-BP-028 1.2 (FR) (PDF)](https://www.ssi.gouv.fr/uploads/2016/01/linux_configuration-fr-v1.2.pdf)

[ANSSI-BP-028 1.2 (EN) (PDF)](https://www.ssi.gouv.fr/uploads/2019/03/linux_configuration-en-v1.2.pdf)

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

**The deployed system is compliant to the ANSSI-BP-028-HIGH standard at 97%**. The remaining 3% of compliance rely on user configuration that varies on the user infrastructure and needs.

An OpenSCAP report (HTML format) can be found at the root of the repository showing the system's compliance. However, it does show some false positives:

* **Ensure /boot Located on Separate Partition (R12)**: FALSE POSITIVE. The parition is separate, but has the `noauto` flag so OpenSCAP can't validate the rule.

* **Ensure a dedicated group owns sudo (R57)**: FALSE POSITIVE. You can manually verify this rule with `ls -l /usr/bin | grep sudo`. The group *wheel* owns the binary.

* **Explicit arguments in sudo specifications (R63)**: FALSE POSITIVE. As described in the report, false positives happen due to bad parsing of the sudoers file.

* **Don't target root user in the sudoers file (R60)**: It is up to the user to configure this file to suit their needs.

* **Configure TLS for rsyslog remote logging (R43)**: It is up to the user to configure the TLS certificates to match their infrastructure.

* **Configure CA certificate for rsyslog remote logging (R43)**: It is up to the user to configure the TLS certificates to match their infrastructure.

* **Add noexec option to /boot (R12)**: FALSE POSITIVE. The flag is there, but has the `noauto` flag so OpenSCAP can't validate the rule.

* **Add nosuid option to /boot (R12)**: FALSE POSITIVE. The flag is there, but has the `noauto` flag so OpenSCAP can't validate the rule.

* **Enable the deny_execmem SELinux Boolean (R67)**: FALSE POSITIVE. The boolean is set to on and can be checked with `getsebool -a | grep deny_execmem`.

* **Set SSH Idle Timeout Interval (R29)**: FALSE POSITIVE. The interval is set in the OpenSSH server configuration file.

* **Set SSH Client Alive Count Max (R29)**: FALSE POSITIVE. The count is set in the OpenSSH server configuration file.

* **Configure Polyinstantiation of /tmp Directories (R39)**: Polyinstantiation configuration is not persistent on a TMPFS. The /tmp parition is a TMPFS.

## Known bugs:

* SELinux prevents the firewalld and kdump systemd units from starting. Investigations underway.
