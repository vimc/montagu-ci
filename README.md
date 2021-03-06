# TeamCity Vagrant

This is a Vagrant setup for creating a TeamCity server and build agents. It uses a shell script for provisioning.

Our teamcity server runs at http://teamcity.montagu.dide.ic.ac.uk:8111

This was based off of [this repo](https://github.com/rodm/teamcity-vagrant) but has been totally rewritten follow the recommended installation approach for TeamCity 10.x

## Issues

Use the `"CI system"` component in [YouTrack](https://vimc.myjetbrains.com/youtrack/issues?q=Component:%20%7BCI%20system%7D)

## Requirements

1. Install in the host machine:
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)

2. Clone this repository.

## Creating and starting the CI service
Run (as root):

    $ ./scripts/start-on-boot.sh

This will create a new systemd service and start it. TeamCity will automatically
resume on host boot.

To just run TeamCity without installing it as a service, run:

    $ ./scripts/start.sh

**Note:** the first run may take up to 10 minutes, more on a slow connection as 
there is a lot to download.  Provisioning (not including downloading) takes 
about 2-3 minutes, and there is a further 1-2 minutes of maintenence after the 
server starts up while teamcity starts its systems.

The server should start automatically. It didn't when we tried on 25/10/17, and
we had to ssh in, become root, and run `/etc/init.d/teamcity-server start`.

**Note**; the `montagu-ci-server` *must* come up and be enabled before starting 
agents.  This is because the agent needs to download its setup from the agent 
during provisioning, and register with the server during startup. 

## Remove the CI service
Run (as root):

    $ ./scripts/remove-start-on-boot.sh

## Managing TeamCity service
To start:

    sudo systemctl start montagu-ci

To stop:

    sudo systemctl stop montagu-ci

To view logs:

    systemctl status montagu-ci     # Gives short status
    journalctl --unit montagu-ci    # Gives full log

## Accessing the TeamCity server

Once the server it started, it can be accessed at http://teamcity.montagu.dide.ic.ac.uk (which is forwarded from the server VM).

Once one or more agents have been started they can be authorised from the Agents page in the web UI, http://teamcity.montagu.dide.ic.ac.uk/agents.html.

See the [TeamCity Administrator's Guide](https://confluence.jetbrains.com/display/TCD9/Administrator%27s+Guide) for configuring the server.

## Installing dependencies on the agents

Add the apt packages required to [`files/agent/dependencies`](files/agent/dependencies) and rerun `vagrant provision`

    for i in 1 2 3; do
      vagrant provision "montagu-ci-agent-0$i"
    done

## Updating packages

There is a script `/vagrant/bin/update-packages.sh'` that does this; it is not in the provisioning though because I don't know how to get parts of the Vagrantfile to run conditionally.  So for now do:

    vagrant ssh <name> -- -t 'sudo /vagrant/bin/upgrade-packages.sh'

which of course needs to be done for all the running machines

## Backups

The CI server will backup every day into `/vagrant/restore/TeamCity_Backup.zip` which corresponds to
 `/home/vagrant/montagu-ci/shared/restore/TeamCity_Backup.zip` on the host machine

To restore the server into a *freshly created machine, during provisioning*, run

    $ vagrant up montagu-ci-server

To test that the restore works, run

    $ vagrant up montagu-ci-backup

which will open a new instance of TeamCity server with the most recently backed up data.  It will be available at http://teamcity.montagu.dide.ic.ac.uk:8112 (it will have no agents though as they register themselves with the main host).  As with the main server, it will take 1-2 minutes for the login page to work after provisioning is complete.

## Recovery from backup

```
git clone https://github.com/vimc/montagu-ci.git montagu-ci
mkdir -p montagu-ci/shared/restore
cp vagrant/shared/TeamCity_Backup.zip montagu-ci/shared/restore
cd montagu-ci
vagrant up montagu-ci-server
```

then after confirming that the server has come up correctly, start the workers

```
vagrant up montagu-ci-agent-01 montagu-ci-agent-02 montagu-ci-agent-03
```

and log them into docker (as below)

## Logging into the machines

Through a series of twisty passages:

```
ssh support.montagu.dide.ic.ac.uk
sudo su vagrant
cd ~/montagu-ci
vagrant status
vagrant ssh montagu-ci-agent-01
```

## docker registry

There are two parts to this; one is getting the registry running on the CI host and the other is configuring systems to be able to pull and push from the registry.

### Running the registry on the CI host

See [montagu-registry](https://github.com/vimc/montagu-registry) for details on getting the registry up and running.

### Configuring docker clients to use the registry

You must login to the docker registry to be able to push or pull.  The login lasts as long as the username/password are not changed (which is not frequent).  The general documentation is in the [montagu-registry](https://github.com/vimc/montagu-registry/tree/master#login) repository.

For the agents, this can be done by running (from `support.montagu`)

```
vagrant ssh -c 'sudo su teamcity montagu-auth' montagu-ci-agent-01
vagrant ssh -c 'sudo su teamcity montagu-auth' montagu-ci-agent-02
vagrant ssh -c 'sudo su teamcity montagu-auth' montagu-ci-agent-03
```

which will prompt for your GitHub PAT.  This will also configure ssh keys for the agent, using [vimc-robot](https://github.com/orgs/vimc/people/vimc-robot).

## Upgrading teamcity

1. Increase the `TEAMCITY_VERSION` number in [`provision/setup-server.sh`](provision/setup-server.sh)
2. Destroy everything and then recreate the server (`vagrant destroy -f`, `./scripts/destroy-disks.sh`, `vagrant up montagu-ci-server`)
3. After the machine comes up, do `vagrant ssh montagu-ci-server -c 'sudo grep "token:" /opt/TeamCity/logs/teamcity-server.log'` and copy the authentication token
3. Go to http://teamcity.montagu.dide.ic.ac.uk:8111 and click the link "I'm a server administrator, show me the details"
4. Paste the token in the box
5. Click "Upgrade"
6. Wait until TeamCity is back up and running (takes a couple of minutes)
7. Bring up the agents (`vagrant up montagu-ci-agent-01 montagu-ci-agent-02 montagu-ci-agent-03` and then log in to the docker registry for each agent as above)
8. Go to http://teamcity.montagu.dide.ic.ac.uk:8111/agents.html?tab=unauthorizedAgents and authorise the agents.  The page will note that "Agent authorization token does not match the stored one" but this is expected.

If all goes well, the whole process should take about half an hour.

## VIMC notes

Ubuntu 16.04 VMs are used for the server and agents.

The TeamCity .tar.gz file is downloaded by the scripts and saved to the `downloads` directory, along with the cached Oracle Java .deb files and the Java/MySQL connector.

The server provisioning takes about 10-15 minutes including downloading.  There will be a couple of minutes lag between the VM starting and the landing page being available.  The maintenance page will also about 5 minutes to get through, after which there is a licence agreement to deal with.

Then start an agent.  It'll take a few minutes to start and will, a few minutes later, apear in [the agents page](http://teamcity.montagu.dide.ic.ac.uk/agents.html) under "Unauthorized".  Clicking the tab takes you through to the [page to authorise the agent](http://teamcity.montagu.dide.ic.ac.uk/agents.html?tab=unauthorizedAgents).

The server has a separate "data" disk, following suggestions in the [teamcity documentation](https://confluence.jetbrains.com/display/TCD10/TeamCity+Data+Directory) to keep the build directory off the system disk.  The size of this disk can be configured in the Vagrantfile.

Be aware that `vagrant destroy <machine-name>` Does not remove the disk, which is stored in `disk/`.  That leads to problems like [this](https://github.com/kusnier/vagrant-persistent-storage/issues/69).  The solution is to do:

```
vboxmanage closemedium disk <uuid> --delete
```

Using the **second** uuid reported by `vboxmanage list hdds`.  Better is to do

```
vboxmanage closemedium disk disk/montagu-ci-backup.vdi --delete
```

The private ip of the server (192.168.80.10) is used the agent configuration and should be updated if the Vagrantfile is.  This will be needed when we test backup recovery.

Slack notifications need an incoming webhook; go [here](https://my.slack.com/services/new/incoming-webhook/) to create one or go [here](https://vimc.slack.com/services/B4LR1L5MH) to get the current URL (starts with `https://hooks.slack.com/services/`)

## GitHub Integration

Official documenation is [here](https://confluence.jetbrains.com/display/TCD18/Commit+Status+Publisher), and the process is surprisingly easy.

1. Go to the build page that you want to add a status checker for
2. Click "Edit Configuration Settings"
3. On the left panel, click "Build Features"
4. Click the "Add build feature" button
5. Select "Commit status publisher"
6. Leave "VCS Root" as it is
7. For "Publisher", select "GitHub"
8. Get the token from the vault at `/secret/vimc-robot/teamcity-token` and paste that in as the access token (this uses the `vimc-robot` account)
9. Press the "Test connection" button
10. If you get "Connection failed! there is no push access to the repository..." then go to the settings page for the repo (e.g. `https://github.com/vimc/<repo>/settings/collaboration` and add the `robots` team with **Write** access
11. Press "Save"

From now on, new commits and pull requests will have TeamCity status shown!

## Restarting disconnected agent

1. Remove the disconnected agent - via teamcity site go to disconnected list of agents and remove the agent
1. On the command line ssh to montagu as vagrant user `ssh vagrant@support.montagu.dide.ic.ac.uk` and destroy the removed agent `vagrant destroy <agent_name>`
1. Bring the agent back up `vagrant up <agent_name>`
1. Configure the client to use registry `vagrant ssh -c 'sudo su teamcity montagu-auth' <agent_name>`
1. Authorise the agent on teamcity website 

## Adapting this for other projects

There's relatively little in here that is specific to our needs.  It's more complicated than [this barebones](https://github.com/rodm/teamcity-vagrant) setup because it's aimed at supporting:

* docker builds
* scriptable backups

Uses of `vimc`, `montagu` are things to look for to identify customisations to walk away from.
