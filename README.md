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

**Note**; the docker registry key must have been generated (if changed) before provisioning the workers.  Practically this is only an issue when starting from absolute scratch.  The provisioning scripts will throw an error if this is not done; after generating the key you can continue with

    $ vagrant provision montagu-ci-agent-01

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

The CI server will backup every day into `/opt/TeamCity/data/backup`

From the host, running `./scripts/sync-backups.sh` will syncronise these backups to the host, in the directory `backup`, and will set a link to the most recent one in `restore`.  This will need some work to be cron-able because the working directory will matter.

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

You can only login after getting onto `support.montagu.dide.ic.ac.uk`; once on that machine you can possibly connect through with:

```
Host support.montagu support.montagu.dide.ic.ac.uk
  User <montagu username>
  ForwardAgent yes
Host montagu-ci-server
  User <montagu username>
  ProxyCommand ssh -q support.montagu.dide.ic.ac.uk nc 192.168.80.10 22
```

The configuration for the agents is similar but the ips end in `.11`, `.12` and `.13`.

## docker registry

There are two parts to this; one is getting the registry running on the CI host and the other is configuring systems to be able to pull and push from the registry.

### Running the registry on the CI host

To set things up with a docker registry, from within the `registry` directory, generate a self signed certificate

    $ (cd registry && ./create_key.sh)

which will copy the certificate into `shared/files/agent/registry.crt` ready for provisioning.  The registry does not need to be running at this point.  This step *must* be done to provision the agents.

To run the registry, run

    $ (cd registry && ./run_registry.sh)

which will run as a daemon.  See the [registry/README.md](registry/README.md) for more information.

### Configuring docker clients to use the registry

This needs to be done on all non-CI machines that want to use the registry (this is done already for the agents).  First, get the public key for the registry

    $ sudo mkdir -p /etc/docker/certs.d/docker.montagu.dide.ic.ac.uk:5000
    $ curl -L https://raw.githubusercontent.com/vimc/montagu-ci/master/registry/certs/domain.crt > domain.crt
    $ sudo cp domain.crt /etc/docker/certs.d/docker.montagu.dide.ic.ac.uk:5000
    
Or on Windows:

1. Download the certificate from https://raw.githubusercontent.com/vimc/montagu-ci/master/registry/certs/domain.crt
2. Start > "Manage Computer Certificates" (also available in the control panel)
3. Right-click on "Trusted Root Certification Authoritites" > "All tasks" > "Import"
4. Browse to the crt file and then keep pressing "Next" to complete the wizard
5. Restart Docker for Windows

You can verify that this works with:

    $ docker pull docker.montagu.dide.ic.ac.uk:5000/postgres

which will pull the image (if needed) but not throw an error.

The registry setup is experimental.  The [offical registry documentation](https://docs.docker.com/registry) may help somewhat.

## VIMC notes

Ubuntu 16.04 VMs are used for the server and agents.

The TeamCity .tar.gz file is downloaded by the scripts and saved to the `downloads` directory, along with the cached Oracle Java .deb files and the Java/MySQL connector.

The server provisioning takes about 10-15 minutes including downloading.  There will be a couple of minutes lag between the VM starting and the landing page being available.  The maintenance page will also about 5 minutes to get through, after which there is a licence agreement to deal with.

Then start an agent.  It'll take a few minutes to start and will, a few minutes later, apear in [the agents page](http://teamcity.montagu.dide.ic.ac.uk/agents.html) under "Unauthorized".  Clicking the tab takes you through to the [page to authorise the agent](http://teamcity.montagu.dide.ic.ac.uk/agents.html?tab=unauthorizedAgents).

The server has a separate "data" disk, following suggestions in the [teamcity documentation](https://confluence.jetbrains.com/display/TCD10/TeamCity+Data+Directory) to keep the build directory off the system disk.  The size of this disk can be configured in the Vagrantfile.

Be aware that `vagrant destroy montagu-ci-server` will take out the second disk of that machine too.  This is probably desirable but might still be alarming.

The private ip of the server (192.168.80.10) is used the agent configuration and should be updated if the Vagrantfile is.  This will be needed when we test backup recovery.

Slack notifications need an incoming webhook; go [here](https://my.slack.com/services/new/incoming-webhook/) to create one or go [here](https://vimc.slack.com/services/B4LR1L5MH) to get the current URL (starts with `https://hooks.slack.com/services/`)

## Adapting this for other projects

There's relatively little in here that is specific to our needs.  It's more complicated than [this barebones](https://github.com/rodm/teamcity-vagrant) setup because it's aimed at supporting:

* docker builds
* scriptable backups

Uses of `vimc`, `montagu` are things to look for to identify customisations to walk away from.
