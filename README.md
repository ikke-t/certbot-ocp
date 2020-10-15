# certbot-ocp

Utility for creating and updating SSL certificates for routes in OpenShift
project. Uses [Let's Encrypt certbot](https://certbot.eff.org/), apache and
OpenShift command line tools to fetch, update and install
the certificates.

This utility container is stored at
[quay.io/fevermap/certbot-ocp](https://quay.io/repository/fevermap/certbot-ocp?tab=info)

# How does it work?

I created an container that runs apache and certbot. When the container starts
it scans all the routes in OpenShift project. Those routes that have been
labeled with ```letsencrypt-me=true``` will be listed.

Container will create acme-challenge routes for the the domains, and it will
handle the certbot requests for all the domains. SSL certs are stored to
persistent storage for further renewals.

Once all certs are acquired, they will be patched to the application routes.
Now you have SSL certs which are valid for 90 days. When ever container is
rerun, it will renew the certs that need renewing. And again updates the routes
with fresh certs.

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
* **CERTBOT_SERVICE_NAME**: name of the certbot service, if empty defaults to certbot-ocp.

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

## Ansible playbook

Download the
[ansible playbook](https://raw.githubusercontent.com/ikke-t/cerbot-ocp/master/certbot-playbook.yml)
in this repo, and run it:

```
ansible-playbook certbot-playbook.yml \
-i "localhost ansible_connection=local", \
-c local \
-e api_url=https://api.example.com:6443 -e user=your_ocp_username \
-e api_key=$(oc whoami -t) \
-e project_name=fevermap \
-e cb_extra_opts='--test' \
-e cb_email=you@example.com \
-e state=present
```

> Just for safety, the above one uses --test option, which is not rate limited
> and creates fake certs. Replace it with empty string ```''``` for production.

At this moment there is no cron job done for kubernetes. So remember to scale
manually the pod to 1 for running it, and to zero once done.

While you decommission it, change present to absent and rerun the playbook.
Note that this will also remove the cached certificate info from certbot,
and it won't be possible to renew the existing certs. So scale it down to 0
if you plan to renew certificates, and remove totally if your route is no longer
used.


## Manual way

Apply the deployment config from this repo. Add the env variables first
according to above description.

In pod-certbot-ocp.yaml and cronjob-certbot-ocp.yaml, change the values:
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
oc create -f manifests/sa-certbot-ocp.yaml
oc adm policy add-role-to-user certbot-ocp -z certbot-ocp-sa
oc create -f manifests/pvc-certbot-letsencrypt.yaml
oc create -f manifests/pod-certbot-ocp.yaml
oc create -f manifests/svc-certbot-ocp.yaml
oc create -f manifests/cronjob-certbot-ocp.yaml
```

Container runs once, and from container logs you can check did everything work. To check logs do following

```
oc logs certbot-ocp
```

If you need to run Pod again do following

```
oc delete po certbot-ocp && oc create -f manifests/pod-certbot-ocp.yaml
```

CronJob will start certbot container once per day and renew certiciates if needed. You can change job interval by modifying manifests/cronjob-certbot-ocp.yaml. There a filed called schedule.

To get more info about job runs run

```
oc get jobs
```

And to get rid of this alltogether, do:
```
oc delete svc,pod,role,sa,cronjob,job,pvc -l app=certbot-ocp
```
