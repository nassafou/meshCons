# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # consulm server
  config.vm.define "consulm" do |consulm|
    consulm.vm.box = "ubuntu/bionic64"
    consulm.vm.hostname = "consulm"
    consulm.vm.box_url = "ubuntu/bionic64"
    consulm.vm.network :private_network, ip: "192.168.58.10"
    consulm.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      v.customize ["modifyvm", :id, "--memory", 1024]
      v.customize ["modifyvm", :id, "--name", "consulm"]
      v.customize ["modifyvm", :id, "--cpus", "1"]
    end
    config.vm.provision "shell", inline: <<-SHELL
      sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config    
      service ssh restart
    SHELL
    consulm.vm.provision "shell", path: "install_consulm.sh"
  end

numberSrv=3
  # myapp server
  (1..numberSrv).each do |i|
    config.vm.define "myapp#{i}" do |myapp|
      myapp.vm.box = "ubuntu/bionic64"
      myapp.vm.hostname = "myapp#{i}"
      myapp.vm.network "private_network", ip: "192.168.58.1#{i}"
      myapp.vm.provider "virtualbox" do |v|
        v.name = "myapp#{i}"
        v.memory = 1024
        v.cpus = 1
      end
      config.vm.provision "shell", inline: <<-SHELL
        sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config
        service ssh restart
      SHELL
      myapp.vm.provision "shell", path: "install_myapp.sh"
    end
  end
end
