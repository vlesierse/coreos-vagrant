# -*- mode: ruby -*-
# vi: set ft=ruby :

def generate_cluster_info(cluster)
  require 'open-uri'

  nodes = Array.new()
  cluster['roles'].each do |role|
    (1..role['instances']).each do |i|
      node = {
        :hostname => "%s-%s%02d" % [cluster['name'] || 'coreos', role['name'] || 'node', i],
        :vm => {
          :cpus => role['vm']['cpus'] || 1,
          :memory => role['vm']['memory'] || 1024,
          :ipaddress => "%s%d" % [role['vm']['ipbase'], 3 + i]
        },
        :configfile => role['configfile'],
        :units => role['units'] || Array.new()
      }
      nodes.push(node)
    end
  end

  return {
    :coreos => {
      :token => cluster['coreos']['token'] || open('https://discovery.etcd.io/new').read,
      :channel => cluster['coreos']['channel'] || 'stable'
    },
    :nodes => nodes
  }
end