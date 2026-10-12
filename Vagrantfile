# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/noble64"
  config.vm.hostname = "clouddistro-builder"

  config.vm.provider "virtualbox" do |vb|
    vb.name = "clouddistro-builder"
    vb.memory = "4096"
    vb.cpus = 2
  end

  config.vm.provider "libvirt" do |lv|
    lv.memory = 4096
    lv.cpus = 2
  end

  config.vm.provider "hyperv" do |hv|
    hv.memory = 4096
    hv.cpus = 2
  end

  config.vm.synced_folder ".", "/vagrant", disabled: false

  # Build CloudDistro WSL2 rootfs automatically inside the clean VM
  config.vm.provision "shell", inline: <<-SHELL
    set -euo pipefail
    echo "==> [Vagrant] Building CloudDistro WSL2 distro..."
    cd /vagrant
    chmod +x build.sh rootfs/usr/libexec/cloud-distro-oobe
    sudo ./build.sh
    echo "==> [Vagrant] Build complete! Check ./dist/ for the .wsl and .tar.gz assets."
  SHELL
end
