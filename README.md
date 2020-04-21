# cerbot-ocp

Utility for creating and updating SSL certificates for routes in OpenShift
project. Uses [Let's Encrypt certbot](https://certbot.eff.org/), NGINX and
OpenShift command line tools to fetch, update and install
the certificates.

This utility container is stored at
[quay.io/fevermap/certbot-ocp](https://quay.io/repository/fevermap/certbot-ocp?tab=info)

# Usage

At the moment this is work in process. It requires manual starts. For later,
operator would be nice. Contributions welcome :)

## Environement variables

The following environment variables are required:

* **EMAIL**: Your email address used for the
  [Let's Encrypt](https://letsencrypt.org/) account

Optional Parameters:

* **ROUTE_LABEL**: a label in routes to recognize which routes to setup SSL for.
* **CERTBOT_EXTRA_OPTS**: passes additional parameters for certbot.
  E.g. --test would be good while just trying out before production.
* **TRASH_ALL**: deletes all /etc/letsencrypt contents. Used to force getting
  new certs. Good to use while testing the service.

## OpenShift routes

This utility looks for routes labelled in certain way. You need to label your
public routes for your services with label ```letsencrypt-me=true```, or
according to your custom label from env ROUTE_LABEL.

E.g:

```
oc label route fevermap-app letsencrypt-me=true
```

## Persistence

Deployment conf may scaled to 0 when task is done, persistent data for certbot
will be saved in OpenShift persistent volume.

## Service account

oc -command will be used to modify the OpenShift route to include the
certificates. Fort that reason we create certbot-ocp service account to have
editing permission for the container.

# Running the container

Apply the deployment config from this repo. Add the env variables first
according to above description.

In dc-certbot-ocp.yaml, change the values:
```
      - env:
        - name: EMAIL
          value: your_email@example.com
        - name: CERTBOT_EXTRA_OPTS
          value: '--test'
```

> Note, above example will generate test certificates.

and run:

```
oc create -f pvc-certbot-letsencrypt.yaml
oc create -f dc-certbot-ocp.yaml
oc create sa certbot
oc adm policy add-role-to-user edit -z certbot
oc expose dc certbot-ocp --port=8080
oc scale --replicas=1 dc certbot-ocp
```

At the moment it keeps resapawning the container, which is bad. So just scale
down the container to zero once certs are acquired. This should happen on the
first run.

```
oc scale --replicas=0 dc certbot-ocp
```

And now, remember to scale it once up every 85 days. I hope until that I've
automated all this :D