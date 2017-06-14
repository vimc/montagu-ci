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
backup =
  { :hostname => 'montagu-ci-backup',   :ip => '192.168.80.20', :ram => '3072' }

# This is the thing that will significantly change size over time, so
# let's pull it out into its own thing for now
server_data_disk = 'server_data_disk.vdi'
server_data_disk_size = 30 # in GB

Vagrant.configure(2) do |config|
  # Common bits:
  config.vm.box = box
  config.vm.synced_folder 'shared', '/vagrant'

  # All nodes need Oracle Java 8 on them
  config.vm.provision :shell do |shell|
    shell.path = 'provision/install-java.sh'
  end
  config.vm.provision :shell do |shell|
    shell.path = 'provision/setup-users.sh'
  end

  # Team city server:
  config.vm.define server[:hostname] do |server_config|
    server_config.vm.provider :virtualbox do |vbox|
      vbox.gui = false
      unless File.exist?(server_data_disk)
        vbox.customize ['createhd', '--filename', server_data_disk,
                        '--variant', 'Fixed',
                        '--size', server_data_disk_size * 1024]
      end
      vbox.memory = server[:ram]
      vbox.customize ['storageattach', :id, '--storagectl', 'SATA Controller',
                      '--port', 1, '--device', 0, '--type', 'hdd',
                      '--medium', server_data_disk]
    end
    server_config.vm.hostname = server[:hostname] + '.' + domain
    server_config.vm.network :private_network, ip: server[:ip]
    server_config.vm.network "forwarded_port", guest: 8111, host: 8111
    server_config.vm.provision :shell do |shell|
      shell.path = 'provision/setup-server-disk.sh'
    end
    server_config.vm.provision :shell do |shell|
      shell.path = 'provision/setup-server.sh'
    end
  end

  # This is identical to server (and could probably be added together
  # with .each) except that
  #
  #   * we don't customise or set up a separate disk
  #
  #   * we foward to a different port so that it can be run on the
  #     same host without conflict.
  #
  # We'll deal with filling the backup during setup-server.sh
  config.vm.define backup[:hostname] do |backup_config|
    backup_config.vm.provider :virtualbox do |vbox|
      vbox.gui = false
      vbox.memory = backup[:ram]
    end
    backup_config.vm.hostname = backup[:hostname] + '.' + domain
    backup_config.vm.network :private_network, ip: backup[:ip]
    backup_config.vm.network "forwarded_port", guest: 8111, host: 8112
    backup_config.vm.provision :shell do |shell|
      shell.path = 'provision/setup-server.sh'
    end
  end

  # The agents
  agents.each do |agent|
    config.vm.define agent[:hostname] do |agent_config|
      agent_config.vm.provider :virtualbox do | vbox |
        vbox.gui = false
        vbox.memory = agent[:ram]
      end
      agent_config.vm.hostname = agent[:hostname] + '.' + domain
      agent_config.vm.network :private_network, ip: agent[:ip]
      # This needs to come before the setup-docker because the latter
      # depends on the existance of a teamcity user.
      agent_config.vm.provision :shell do |shell|
        shell.path = 'provision/setup-agent.sh'
      end
      agent_config.vm.provision :shell do |shell|
        shell.path = 'provision/setup-docker.sh'
      end
      agent_config.vm.provision :shell do |shell|
        shell.path = 'provision/setup-docker-registry.sh'
      end
      agent_config.vm.provision :shell do |shell|
        shell.path = 'provision/setup-docker-compose.sh'
      end
      agent_config.vm.provision :shell do |shell|
        shell.path = 'provision/setup-agent-dependencies.sh'
      end
    end
  end
end
