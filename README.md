# AlmaLinux 9.2 server, secured to ANSSI-BP-028-ENHANCED

This repository is a set of scripts used to build an ISO format installation image that automatically installs a secured AlmaLinux 9.2 system, without any user interaction.

This fork of AlmaLinux is aimed at VirtIO virtualised servers and features compliance to ANSSI-BP-028-ENHANCED, the second highest standard of Linux security in the French cybersecurity administration, but also quality of life features like web management and system administration through Cockpit.

By simply inserting this installation image in your virtualization hypervisor, you can deploy extremely secure servers on which to run your services. Maintenance is minimal.

By forking this repository and modifying it to your needs, you can deploy infinitely customizable secure servers.

The installation process requires no user interaction and no network connectivity.

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

`$ docker build -t almalinux-bp-028-9.2-build`

Now run the build process within the build environment:

`$ docker run --rm -v $(pwd):/app almalinux-bp-028-9.2-build`

## Dependencies

The build process requires `createrepo`, `curl`, `xorriso` and `syslinux` from EPEL:

`# dnf install epel-release && dnf update`

`# dnf install xorriso syslinux createrepo curl`

## Usage

Build the image and insert it in your virtualization hypervisor.

## The deployed system

Two user accounts are created: `root` and `admin`. Their password are `root` and `admin` respectively and will have to be changed after installation. They are not set to automatically expire so as to not break the system at the first log-in.

You will have to manually configure `rsyslog` and its certificates to work with your own journaling system.

OpenSSH and Cockpit are installed and running.

## Compliance

**The deployed system does not pass all ANSSI-BP-028-ENHANCED OpenSCAP tests out of the box.**

An OpenSCAP report (HTML format) can be found at the root of the repository showing the system's compliance. You can recreate the report by running the following commands on a freshly installed system:

`# oscap xccdf eval --results results.xml --profile xccdf_org.ssgproject.content_profile_anssi_bp28_enhanced /usr/share/xml/scap/ssg/content/ssg-almalinux9-ds.xml`

`# oscap xccdf generate report results.xml > report.html`

### Depend on user configuration

The system requires configuration and secrets unique to the user's infrastructure for those checks to pass.

### Bugs

* **Set the UEFI Boot Loader Password (R17)**: OpenSCAP reports a failure. Status unknown. To be investigated.

### Maintenance

System maintenance should be minimal and depends on the specific needs of your organization. We do however recommend scheduling automated OpenSCAP compliance checks, and AIDE integrity checks.