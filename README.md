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

* **DOMS**: Space separated list of domain names for certificates.
  Can be also just one domain. E.g. "first.my.example.com second.my.example.com"
* **EMAIL**: Your email address used for the
  [Let's Encrypt](https://letsencrypt.org/) account

## OpenShift routes

This utility expects that some preconditions are met. You need to name your
public routes for your servicess according to FQDN, dots changed to hyphens,
E.g:

```
oc create route edge first-my-example-com \
  --hostname=first.my.example.com \
  --service=frontend
```

And for each such route you need to create additional route for this utility
to be able to catch the acme-challenges:

```
oc expose service certbot-ocp \
  --path=/.well-known/acme-challenge \
  --port=8080 \
  --name=certbot-first-my-example-com \
  --hostname=first.my.example.com
```

So you end up having for each FQDN the routes

* first-my-example-com, which will be updated with SSL certs by this utility
* certbot-first-my-example-com, which grabs the acme-challenges to certbot tool

## peristence

Deoployment conf may scaled to 0 when task is done, persistent data for certbot
will be saved in OpenShift persistent volume.

# Running the container

Apply the deployment config from this repo. Add the env variables first
according to above description.

In dc-certbot-ocp.yaml, change the values:
```
      - env:
        - name: DOMS
          value: 'app.apps.ocp4.example.com api.apps.ocp4.example.com'
        - name: EMAIL
          value: your_email@example.com
```

and run:

```
oc create -f pvc-certbot-letsencrypt.yaml
oc create -f dc-certbot-ocp.yaml
oc create route edge first-my-example-com \
  --hostname=first.my.example.com \
  --service=frontend
oc expose service certbot-ocp \
  --path=/.well-known/acme-challenge \
  --port=8080 \
  --name=certbot-first-my-example-com \
  --hostname=first.my.example.com
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