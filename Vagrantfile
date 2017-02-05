# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.ssh.insert_key = false

  # define box template
  config.vm.box = "lupin/centos7"

  config.vm.box_check_update = true

  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.synced_folder "./src", "/tmp/atlas/"

  if Vagrant.has_plugin?("vagrant-hostsupdater")
    # hostonly: static
    config.vm.network :private_network, ip: "192.168.3.10"
    config.vm.hostname = "atlas.com"
  else
    # bridged: prompt
    config.vm.network :public_network
  end

  config.vm.provider "virtualbox" do |vb|
    vb.gui = false
    vb.memory = "1024"
    vb.cpus = 2
    vb.name = "Atlas"
  end

  config.vm.provision 'prepare', type: 'shell', inline: <<-SHELL
    sudo yum install -y vim epel-release
    sudo yum install --enablerepo=epel -y nginx
    sudo systemctl enable nginx.service

    sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
    sudo firewall-cmd --reload

    sudo mkdir -p /var/www/atlas.com/public_html/vagrant/boxes
    sudo mkdir -p /var/www/atlas.com/public_html/vagrant/templates
    sudo mkdir -p /var/www/atlas.com/public_html/css
    sudo cp /tmp/atlas/index.html /var/www/atlas.com/public_html
    sudo cp /tmp/atlas/css/styles.css /var/www/atlas.com/public_html/css
    sudo cp /tmp/atlas/atlas.com.conf /etc/nginx/conf.d/atlas.com.conf

    sudo useradd atlas
    sudo cp /tmp/atlas/atlas.sh /home/atlas/atlas.sh
    sudo chown atlas:atlas /home/atlas/atlas.sh
    sudo chmod 0700 /home/atlas/atlas.sh
    sudo chown -R atlas:atlas /var/www/atlas.com/public_html
    sudo chmod 0755 /var/www/atlas.com/public_html
    sudo systemctl start nginx
  SHELL

  config.vm.provision 'info', type: "shell", inline: <<-SHELL
    sudo ip link set dev enp0s8 up
    sudo systemctl restart network

    ATLAS_IP=$(sudo ip -f inet addr show enp0s8 | grep 'inet' | awk '{print $2}')
    echo "check /etc/hosts for: ${ATLAS_IP: : -3}  atlas.com"
    echo "open URL: http://atlas.com"
  SHELL

end
