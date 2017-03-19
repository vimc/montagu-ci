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

(Note: the first run may take up to 10 minutes, more on a slow connection as there is a lot to download).

To create and start a TeamCity build agent, run `vagrant up` with one of the agent names;

    $ vagrant up montagu-ci-agent-01
    $ vagrant up montagu-ci-agent-02
    $ vagrant up montagu-ci-agent-03

## Accessing the TeamCity server

Once the server it started, it can be accessed at http://fi--didelx05:8111 (which is forwarded from the server VM).

Once one or more agents have been started they can be authorised from the Agents page in the web UI, http://fi--didelx05:8111/agents.html.

See the [TeamCity Administrator's Guide](https://confluence.jetbrains.com/display/TCD9/Administrator%27s+Guide) for configuring the server.

## VIMC notes

Ubuntu 16.04 VMs are used for the server and agents.

The TeamCity .tar.gz file is downloaded by the scripts and saved to the `downloads` directory, along with the cached Oracle Java .deb files and the Java/MySQL connector.

The server provisioning takes about 10-15 minutes including downloading.  There will be a couple of minutes lag between the VM starting and the landing page being available.  The maintenance page will also about 5 minutes to get through, after which there is a licence agreement to deal with.

Then start an agent.  It'll take a few minutes to start and will, a few minutes later, apear in [the agents page](http://fi--didelx05:8111/agents.html) under "Unauthorized".  Clicking the tab takes you through to the [page to authorise the agent](http://fi--didelx05:8111/agents.html?tab=unauthorizedAgents).

The server has a separate "data" disk, following suggestions in the [teamcity documentation](https://confluence.jetbrains.com/display/TCD10/TeamCity+Data+Directory) to keep the build directory off the system disk.  The size of this disk can be configured in the Vagrantfile.

Be aware that `vagrant destroy montagu-ci-server` will take out the second disk of that machine too.  This is probably desirable but might still be alarming.

The private ip of the server (192.168.80.10) is used the agent configuration and should be updated if the Vagrantfile is.  This will be needed when we test backup recovery.
