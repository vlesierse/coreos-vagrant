# -*- mode: ruby -*-
# # vi: set ft=ruby :
 
# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"
VAGRANTFILE_PATH = File.dirname(__FILE__)

# Require YAML module
require 'yaml'

cluster_file = File.join(VAGRANTFILE_PATH, 'cluster.yml')
require File.join(VAGRANTFILE_PATH, 'vagrant/lib/generate_cluster_info')
# Read YAML file with cluster details
cluster = generate_cluster_info(YAML.load_file(cluster_file))

cloud_config_file = File.join(VAGRANTFILE_PATH, '.vagrant/cloud-config.yml')
if File.exists?(cloud_config_file)
  File.delete(cloud_config_file)
end
tmp_cloud_config_file = File.join(VAGRANTFILE_PATH, 'cloud-config.yml')
if File.exists?(tmp_cloud_config_file) && ARGV[0].eql?('up')
  require 'open-uri'

  token = open('https://discovery.etcd.io/new').read
  data = YAML.load(IO.readlines(tmp_cloud_config_file)[1..-1].join)
  data['coreos']['etcd']['discovery'] = token

  yaml = YAML.dump(data)
  File.open(cloud_config_file, 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # always use Vagrants insecure key
  config.ssh.insert_key = false

  config.vm.box = "coreos-%s" % cluster[:coreos][:channel]
  config.vm.box_version = ">= 308.0.1"
  config.vm.box_url = "http://%s.release.core-os.net/amd64-usr/current/coreos_production_vagrant.json" % cluster[:coreos][:channel]

  config.vm.provider :virtualbox do |v|
    # On VirtualBox, we don't have guest additions or a functional vboxsf
    # in CoreOS, so tell Vagrant that so it can be smarter.
    v.check_guest_additions = false
    v.functional_vboxsf     = false
  end

  # plugin conflict
  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end


  cluster[:nodes].each do |node|

    config.vm.define vm_name = node[:hostname] do |config|
      config.vm.hostname = vm_name

      config.vm.provider :virtualbox do |vb|
        vb.gui = false
        vb.memory = node[:vm][:memory]
        vb.cpus = node[:vm][:cpus]
      end

      config.vm.network :private_network, ip: node[:vm][:ipaddress]

      node_config_file = node[:configfile] || cloud_config_file
      config.vm.provision :file, :source => "#{node_config_file}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
      
      # Provision Units
      node[:units].each do |unit|
        unit_file = "%s.service" % unit
        unit_path = File.join(VAGRANTFILE_PATH, "units/%s" % unit_file)
        if File.exist?(unit_path)
          config.vm.provision :file, :source => "#{unit_path}", :destination => "/tmp/units/#{unit_file}"
          config.vm.provision :shell, :inline => "mv /tmp/units/#{unit_file} /etc/systemd/system/#{unit_file} && systemctl enable #{unit_file} && systemctl start #{unit_file}", :privileged => true
        end
      end
    end
  end
end