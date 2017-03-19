# -*- mode: ruby -*-

# Older versions of vagrant can't start the ubuntu bentobox with
# private networking
Vagrant.require_version ">= 1.8.2"

domain = 'localdomain'
box = "bento/ubuntu-16.04"
server =
  { :hostname => 'montagu-ci-server',   :ip => '192.168.80.10', :ram => '3072' }
agents = [
  { :hostname => 'montagu-ci-agent-01', :ip => '192.168.80.11', :ram => '2048' },
  { :hostname => 'montagu-ci-agent-02', :ip => '192.168.80.12', :ram => '2048' },
  { :hostname => 'montagu-ci-agent-03', :ip => '192.168.80.13', :ram => '2048' }
]

# This is the thing that will significantly change size over time, so
# let's pull it out into its own thing for now
server_artifacts_disk = './server_artifacts_disk.vdi'
server_artifacts_disk_size = 10 # in GB

Vagrant.configure(2) do |config|
  # Common bits:
  config.vm.box = box

  # All nodes need Oracle Java 8 on them
  config.vm.provision :shell do |shell|
    shell.path = 'scripts/install-java.sh'
  end

  # Team city server:
  config.vm.define server[:hostname] do |server_config|
    server_config.vm.provider :virtualbox do |vbox|
      vbox.gui = false
      unless File.exist?(server_artifacts_disk)
        vbox.customize ['createhd', '--filename', server_artifacts_disk,
                        '--variant', 'Fixed',
                        '--size', server_artifacts_disk_size * 1024]
      end
      # Then do this:
      #
      # http://stackoverflow.com/a/27515105
      # http://zacklalanne.me/using-vagrant-to-virtualize-multiple-hard-drives/
      #
      # To mount directory at
      # /opt/teamcity-server/data
      vbox.memory = server[:ram]
      vbox.customize ['storageattach', :id, '--storagectl', 'SATA Controller',
                      '--port', 1, '--device', 0, '--type', 'hdd',
                      '--medium', server_artifacts_disk]
    end
    server_config.vm.hostname = server[:hostname] + '.' + domain
    server_config.vm.network :private_network, ip: server[:ip]
    server_config.vm.network "forwarded_port", guest: 8111, host: 8111
    server_config.vm.provision :shell do |shell|
      shell.path = 'scripts/setup-server-disk.sh'
    end
    server_config.vm.provision :shell do |shell|
      shell.path = 'scripts/setup-server.sh'
    end
  end

  # The agents
  agents.each do |agent|
    config.vm.define agent[:hostname] do |agent_config|
      agent_config.vm.provider :virtualbox do | vbox |
        vbox.gui = false
        vbox.customize ['modifyvm', :id, '--memory', agent[:ram]]
      end
      agent_config.vm.hostname = agent[:hostname] + '.' + domain
      agent_config.vm.network :private_network, ip: agent[:ip]
      agent_config.vm.provision :shell do |shell|
        shell.path = 'scripts/setup-agent.sh'
      end
    end
  end
end
