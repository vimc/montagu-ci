# TeamCity Vagrant

This is a Vagrant setup for creating a TeamCity server and build agents. It uses a shell script for provisioning.

This was based off of [this repo](https://github.com/rodm/teamcity-vagrant) but has been totally rewritten follow the recommended installation approach for TeamCity 10.x

## Issues

Use the `"CI system"` component in [YouTrack](https://vimc.myjetbrains.com/youtrack/issues?q=Component:%20%7BCI%20system%7D)

## Requirements

1. Install in the host machine:
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)

2. Clone this repository.

## Starting the TeamCity server

To create the TeamCity server VM and start the server, run:

    $ vagrant up montagu-ci-server

**Note:** the first run may take up to 10 minutes, more on a slow connection as there is a lot to download.  Provisioning (not including downloading) takes about 2-3 minutes, and there is a further 1-2 minutes of maintenence after the server starts up while teamcity starts its systems.

To create and start a TeamCity build agent, run `vagrant up` with one of the agent names;

    $ vagrant up montagu-ci-agent-01
    $ vagrant up montagu-ci-agent-02
    $ vagrant up montagu-ci-agent-03

**Note**; the `montagu-ci-server` *must* come up and be enabled before starting agents.  This is because the agent needs to download its setup from the agent during provisioning, and register with the server during startup.  Practically this means that full restart will look like


    $ vagrant up montagu-ci-server
    # ... ensure that the server is up and you can log in; up to ~10 minutes
    $ vagrant up

Each agent should take 1-2 minutes to provision; this will be much faster than the server because they just pull the files from the java cache and from the server itself.  As the number of dependencies grows, things could get slower though.  There will be a gap of up to a minute before the agent appears in the agents page.

## Accessing the TeamCity server

Once the server it started, it can be accessed at http://fi--didelx05:8111 (which is forwarded from the server VM).

Once one or more agents have been started they can be authorised from the Agents page in the web UI, http://fi--didelx05:8111/agents.html.

See the [TeamCity Administrator's Guide](https://confluence.jetbrains.com/display/TCD9/Administrator%27s+Guide) for configuring the server.

## Installing dependencies on the agents

Add the apt packages required to [`files/agent/dependencies`](files/agent/dependencies) and rerun `vagrant provision`

    for i in 1 2 3; do
      vagrant provision "montagu-ci-agent-0$i"
    done

## Updating packages

There is a script `/vagrant/scripts/update-packages.sh'` that does this; it is not in the provisioning though because I don't know how to get parts of the Vagrantfile to run conditionally.  So for now do:

    vagrant ssh <name> -- -t 'sudo /vagrant/scripts/upgrade-packages.sh'

which of course needs to be done for all the running machines

## Backups

The CI server will backup every day into `/opt/TeamCity/data/backup`

From the host, running `./shared/scripts/sync-backups.sh` will syncronise these backups to the host, in the directory `backup`, and will set a link to the most recent one in `restore`.  This will need some work to be cron-able because the working directory will matter.

To restore the server into a *freshly created machine, during provisioning*, run

    $ ln -s TeamCity_Backup.zip restore/montagu-ci-server
    $ vagrant up montagu-ci-server
    $ rm restore/montagu-ci-server

To test that the restore works, run

    $ vagrant up montagu-ci-backup

which will open a new instance of TeamCity server with the most recently backed up (and synchronised) data.  It will be available on port 8112 (it will have no agents though as they register themselves with the main host).  As with the main server, it will take 1-2 minutes for the login page to work after provisioning is complete.

## Logging into the machines

If you're not the person who set the machines up, `vagrant` commands are not going to work.  So add ssh public keys into [`files/keys`](files/keys) named with the username (e.g., `rich.pub` is the key for a user called `rich`).  During provisioning, we create a sudo-able user account for each user listed here.  Password login is disabled but after logging in you can sudo with the password [horsestaple](https://xkcd.com/936/).  See [VIMC-72](https://vimc.myjetbrains.com/youtrack/issue/VIMC-72) for something better.

If the machines are rebuilt, then you will get the big warning about keys changing.

## VIMC notes

Ubuntu 16.04 VMs are used for the server and agents.

The TeamCity .tar.gz file is downloaded by the scripts and saved to the `downloads` directory, along with the cached Oracle Java .deb files and the Java/MySQL connector.

The server provisioning takes about 10-15 minutes including downloading.  There will be a couple of minutes lag between the VM starting and the landing page being available.  The maintenance page will also about 5 minutes to get through, after which there is a licence agreement to deal with.

Then start an agent.  It'll take a few minutes to start and will, a few minutes later, apear in [the agents page](http://fi--didelx05:8111/agents.html) under "Unauthorized".  Clicking the tab takes you through to the [page to authorise the agent](http://fi--didelx05:8111/agents.html?tab=unauthorizedAgents).

The server has a separate "data" disk, following suggestions in the [teamcity documentation](https://confluence.jetbrains.com/display/TCD10/TeamCity+Data+Directory) to keep the build directory off the system disk.  The size of this disk can be configured in the Vagrantfile.

Be aware that `vagrant destroy montagu-ci-server` will take out the second disk of that machine too.  This is probably desirable but might still be alarming.

The private ip of the server (192.168.80.10) is used the agent configuration and should be updated if the Vagrantfile is.  This will be needed when we test backup recovery.

Slack notifications need an incoming webhook; go [here](https://my.slack.com/services/new/incoming-webhook/) to create one or go [here](https://vimc.slack.com/services/B4LR1L5MH) to get the current URL (starts with `https://hooks.slack.com/services/`)
