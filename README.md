# TeamCity Vagrant

This is a Vagrant setup for creating a TeamCity server and build agents. It uses a shell script for provisioning.

This is based off of [this repo](https://github.com/rodm/teamcity-vagrant) but is going to adapt over time to suite our needs for montagu.

## Issues

Use the `"CI system"` component in [YouTrack](https://vimc.myjetbrains.com/youtrack/issues?q=Component:%20%7BCI%20system%7D)

## Requirements

1. Install in the host machine:
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](https://www.vagrantup.com/downloads.html)
2. Clone this repository.

The JDK, Apache Tomcat, TeamCity WAR file and MySQL JDBC driver are downloaded by the scripts and saved to the `downloads` directory.

By default Ubuntu 16.04 VMs are used for the server and agents.

## Starting the TeamCity server

To create the TeamCity server VM and start the server, run:

    $ vagrant up server

(Note: the first run may take up to 10 minutes).

To create and start a TeamCity build agent, run `vagrant up` with one of the agent names;

    $ vagrant up montagu-ci-agent-01
    $ vagrant up montagu-ci-agent-02
    $ vagrant up montagu-ci-agent-03

## Accessing the TeamCity server

Once the server it started, it can be accessed at http://fi--didelx05:8111/teamcity (which is forwarded from the server VM).

Once one or more agents have been started they can be authorised from the Agents page in the web UI, http://fi--didelx05:8111/teamcity/agents.html.

See the [TeamCity Administrator's Guide](https://confluence.jetbrains.com/display/TCD9/Administrator%27s+Guide) for configuring the server.

## VIMC notes

The server provisioning takes about 10-15 minutes including downloading.  There will be a couple of minutes lag between the VM starting and the landing page being available.  The maintenance page will also about 5 minutes to get through, after which there is a licence agreement to deal with.

Then start an agent.  It'll take about 10 minutes to come up, too and should immediately appear in [the agents page](http://fi--didelx05:8111/teamcity/agents.html) under "Unauthorized".  Clicking the tab takes you through to the [page to authorise the agent](http://fi--didelx05:8111/teamcity/agents.html?tab=unauthorizedAgents) and will likely be saying "Agent has unregistered (will upgrade)".  This seems to take 10 minutes or so to complete.
