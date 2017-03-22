# Docker registry

The docker registry is a bit of a faff, but I think it does belong in this repository because we'll primarily use it with the CI system (though it will probably get used when we deploy the actual apps too)

The basic idea is this:

* We create a self signed certificate for the server (it's possible we could do better given that there are real certificates floating around for imperial but this should be enough for our needs).  This will be stored in the `certs/domain.key` and `certs/domain.crt` (relative to this directory).  The common name points at `fi--didelx05.dide.ic.ac.uk` which will be the host that we're running the registry on.
* We run the registry using this self signed certificate.  It will be set to come up with the docker daemon on system restart
* Copy the file `certs/domain.crt` to `/etc/docker/certs.d/fi--didelx05.dide.ic.ac.uk:5000/domain.crt` on *every* docker host that needs to push/pull to this registry.  This will be automated in agent provisioning, though it does require some work when the keys are refreshed.

To automate these there are some scripts here:

* `./create_key.sh`: create a key and certificate pair in `certs`
* `./run_registry.sh`: start the registry server on `localhost:5000`
* `./destroy_registry.sh`: remove a registry *and delete all image data*

Quick test to see if things work

```
docker pull postgres
docker tag postgres fi--didelx05.dide.ic.ac.uk:5000/postgres
docker push fi--didelx05.dide.ic.ac.uk:5000/postgres
docker pull fi--didelx05.dide.ic.ac.uk:5000/postgres
```
