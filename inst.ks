#version=RHEL9

# Use text install
text

# Use CDROM installation media
cdrom

# Keyboard layouts
keyboard --xlayouts='de(nodeadkeys)'
# System language
lang en_US

# Network information
network --bootproto=dhcp --ipv6=auto --activate
network --hostname=localhost.localdomain

# Root password
rootpw Packer

# Run the Setup Agent on first boot
firstboot --disable

# Do not configure the X Window System
skipx

# System services
services --disabled="kdump" --enabled="sshd,rsyslog,chronyd"

# System timezone
timezone Europe/Berlin --utc

# SELinux
selinux --enforcing

# Firewall
firewall --enabled --ssh

# Authentication
authselect --useshadow --passalgo=sha512 --kickstart

# Reboot at end of installation
reboot

# Only use first disk
ignoredisk --only-use=sda
# Partition clearing information
clearpart --none --initlabel
# Disk partitioning information (CIS)
part     /boot/efi         --fstype="efi"   --ondisk=sda --size=600              --fsoptions="umask=0077,shortname=winnt"
part     pv.604            --fstype="lvmpv" --ondisk=sda --size=28194            --grow
part     /boot             --fstype="xfs"   --ondisk=sda --size=1024
volgroup system            --pesize=4096    pv.604
logvol   /tmp              --fstype="xfs"   --size=1024  --name=tmp              --vgname=system
logvol   /var              --fstype="xfs"   --size=5120  --name=var              --vgname=system
logvol   swap              --fstype="swap"  --size=2048  --name=swap             --vgname=system
logvol   /                 --fstype="xfs"   --size=5120  --name=root             --vgname=system
logvol   /var/tmp          --fstype="xfs"   --size=1024  --name=var_tmp          --vgname=system
logvol   /home             --fstype="xfs"   --size=512   --name=home             --vgname=system
logvol   /var/log          --fstype="xfs"   --size=5120  --name=var_log          --vgname=system
logvol   /var/log/audit    --fstype="xfs"   --size=2048  --name=var_log_audit    --vgname=system

# Repositories for live update (yum update is no longer needed in post script)
# repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream
repo --name=baseos-updates --mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=BaseOS-$releasever --cost=1000
repo --name=appstream-updates --mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=AppStream-$releasever --cost=1000
repo --name=extras-updates --mirrorlist=https://mirrors.rockylinux.org/mirrorlist?arch=$basearch&repo=extras-$releasever --cost=1000

%packages
@^minimal-environment
kexec-tools

# unnecessary firmware
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-libertas-usb8388-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end

%post
# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
yum -C -y remove linux-firmware

# remove avahi
echo "Removing avahi/zeroconf"
yum -C -y remove avahi\*

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active_profile

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot

echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/auditd
touch /var/log/boot.log
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# reorder console entries
sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/allow-root-ssh.conf

yum clean all
%end
