# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/noble64"
  config.vm.hostname = "clouddistro-builder"
  config.vm.provider "libvirt" do |lv|
    lv.memory = 4096
    lv.cpus = 2
  end
  config.vm.synced_folder ".", "/vagrant", disabled: false
end
