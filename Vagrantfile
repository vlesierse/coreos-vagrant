# -*- mode: ruby -*-
# # vi: set ft=ruby :
 
# Specify minimum Vagrant version and Vagrant API version
Vagrant.require_version ">= 1.6.0"
VAGRANTFILE_API_VERSION = "2"
VAGRANTFILE_PATH = File.dirname(__FILE__)

# Destroy all cloud config files when destroy
if ARGV[0].eql?('destroy')
  Dir.glob(File.join(VAGRANTFILE_PATH, '.vagrant/cloud-config*.yml')).each { |f| File.delete(f) }
end

# Require YAML module
require 'yaml'

cluster_file = File.join(VAGRANTFILE_PATH, 'cluster.yml')
require File.join(VAGRANTFILE_PATH, 'vagrant/lib/generate_cluster_info')
# Read YAML file with cluster details
cluster = generate_cluster_info(YAML.load_file(cluster_file))

cloud_config_file = File.join(VAGRANTFILE_PATH, '.vagrant/cloud-config.yml')
tmp_cloud_config_file = File.join(VAGRANTFILE_PATH, 'cloud-config.yml')
if !File.exists?(cloud_config_file) && File.exists?(tmp_cloud_config_file) && ARGV[0].eql?('up')
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

      node_config_file = node[:configfile] || File.join(VAGRANTFILE_PATH, '.vagrant/cloud-config-%s.yml' % node[:role])
      if (!File.exists?(node_config_file) && ARGV[0].eql?('up')) || ARGV[0].eql?('provision')
        data = YAML.load(IO.readlines(cloud_config_file)[1..-1].join)
        data['coreos']['fleet']['metadata'] = 'role=%s' % node[:role]
        node[:units].each do |unit|
          unit_file = "%s.service" % unit
          data['coreos']['units'].push({
            'name' => unit_file,
            'command' => 'start',
            'content' => File.read(File.join(VAGRANTFILE_PATH, "units/%s" % unit_file))
            })
          unit_discovery_file = "%s-discovery.service" % unit
          if File.exists?(File.join(VAGRANTFILE_PATH, "units/%s" % unit_discovery_file))
            data['coreos']['units'].push({
            'name' => unit_discovery_file,
            'command' => 'start',
            'content' => File.read(File.join(VAGRANTFILE_PATH, "units/%s" % unit_discovery_file))
            })
          end
        end

        yaml = YAML.dump(data)
        File.open(node_config_file, 'w') { |file| file.write("#cloud-config\n\n#{yaml}") }
      end
      config.vm.provision :file, :source => "#{node_config_file}", :destination => "/tmp/vagrantfile-user-data"
      config.vm.provision :shell, :inline => "mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/", :privileged => true
    end
  end
end