# Make the swap a bit smaller and the main disk a bit bigger:

    sudo swapoff -a
    sudo lvs
    sudo lvresize -L16G /dev/fi--didevimc01-vg/swap_1
    sudo mkswap /dev/fi--didevimc01-vg/swap_1
    sudo lvresize -l +100%FREE /dev/fi--didevimc01-vg/root
    sudo swapon -a

# Basics

    sudo apt-get update
    sudo apt-get install curl git vim
    sudo update-alternatives --set editor `which vim.basic`

# Secure ssh

Copy your keys to the server!

Then change these in `/etc/ssh/sshd_config`

    PermitRootLogin no
    PasswordAuthentication no

and run

    sudo service ssh restart

which does not affect the running session.  Then confirm you can still log in with keys and cannot without

# User setup (everyone will need to do this)

    git config --global user.name "Rich FitzJohn"
    git config --global user.email "rich.fitzjohn@gmail.com"
    ssh-keygen
    cat ~/.ssh/id_rsa.pub

Add this to github at https://github.com/settings/keys

# Need docker on everything

This is already worked out [here](https://github.com/vimc/montagu-ci/blob/master/provision/setup-docker.sh)

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
         $(lsb_release -cs) \
         stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce
    sudo usermod -aG docker rich

annoyingly one must manually include the version number here.  And because of path issues we have previously found it most convenient to install into `/usr/bin` not `/usr/local/bin`; it's easy enough to move though

    curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > docker-compose
    sudo mv docker-compose /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

# Install dependencies

## Virtual box

From [the virtualbox downloads](https://www.virtualbox.org/wiki/Linux_Downloads)

    wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
    sudo add-apt-repository \
         "deb http://download.virtualbox.org/virtualbox/debian \
         $(lsb_release -cs) \
         contrib"
    sudo apt-get update
    sudo apt-get install virtualbox-5.1

## Vagrant

    curl -LO https://releases.hashicorp.com/vagrant/1.9.5/vagrant_1.9.5_x86_64.deb
    sudo dpkg -i vagrant_1.9.5_x86_64.deb

## Users

Vagrant is going to work best an extra user so that more than one person can control it easily.  The other option would be to put things into a shared directory (with some sort of group membership/ownership system), but I don't know that is compatible with the way that virtualbox likes to store things so this seems like the path of least pain

     sudo adduser vagrant
     sudo usermod -aG docker vagrant
     sudo usermod -aG sudo vagrant

# Get things running

     sudo su vagrant
     cd
     git clone https://github.com/vimc/montagu-ci
