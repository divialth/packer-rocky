variables {
  iso_url      = "http://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-9.0-20220808.0-x86_64-dvd.iso"
  iso_checksum = "6fe05fb0992d0ed2e131da669e308bb10e8f5672ad5c0a1ec331ca3006d24493"
  boot_wait    = "5s"
  disk_size    = "50000"
  cpus         = "1"
  cores        = "2"
  memory       = "2048"
  ssh_username = "root"
  ssh_password = "Packer"
  ssh_timeout  = "20m"
  vm_name      = "Rocky-9.0-x86_64"
  format       = "ova"
}

packer {
  required_plugins {
    vmware = {
      version = ">= 1.0.3"
      source  = "github.com/hashicorp/vmware"
    }
  }
}

source "vmware-iso" "rocky" {
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  http_directory = "."
  boot_command = [
    "<up><tab> text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/inst.ks net.ifnames=0 biosdevname=0 <enter><wait>"
  ]
  boot_wait        = var.boot_wait
  disk_size        = var.disk_size
  cpus             = var.cpus
  cores            = var.cores
  memory           = var.memory
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = var.ssh_timeout
  vm_name          = var.vm_name
  guest_os_type    = "centos8-64"
  format           = var.format
  shutdown_command = "shutdown -P now"
}

build {
  sources = ["sources.vmware-iso.rocky"]
  provisioner "shell" {
    inline = [
      "yum install -y cloud-init cloud-utils-growpart gdisk open-vm-tools",
      "systemctl enable vmtoolsd",
      "shred -u /etc/ssh/*_key /etc/ssh/*_key.pub",
      "rm -f /var/run/utmp",
      ">/var/log/lastlog",
      ">/var/log/wtmp",
      ">/var/log/btmp",
      "rm -rf /tmp/* /var/tmp/*",
      "unset HISTFILE; rm -rf /home/*/.*history /root/.*history",
      "rm -f /root/*ks",
      "passwd -d root",
      "passwd -l root",
      "rm -f /etc/ssh/ssh_config.d/allow-root-ssh.conf"
    ]
  }
}
