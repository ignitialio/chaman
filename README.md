> WARNING!
> WIP ! Nothing to see here for the moment.

# Ignitial Chaman

## Use in development

### Install dependencies

```bash
npm i
```

### Populate database for development

Database and authentication service need a minimum set of info (eg. roles) in
order to run web app. Then, you need to populate database before starting your
app:

```bash
npm run dev:config:populate
```

Here we use mongodb as primary database (user info is a MongoDB collection), then
we populate a MongoDB whose name is the one defined in the configuration.  

Configuration uses environment variables to overwrite default values. For the db,
you need to update __IIOS_DBNAME__ env variable. We do this in the script that
executes populate, __scripts/populate_db-mongo.sh__ in our case, since Mongo is
concerned:

```bash
export IIOS_DBNAME=chaman
```

RBAC information is populated as well in Redis. Then, we need to define IIOS
namespace in order to let script know which one to use in Redis database:

```bash
export IIOS_NAMESPACE=chaman
```

### Auto-populate

Starting with _dlake:3.2.0_ an automated populate is done by the _dlake_ service.
It creates the minimal roles and access rights as per the template needs, as well
as an _admin_ user (password: _toto13!_).

### Configure

We can configure application through two different methods:
- using JS and environment variables (_server/config_)
- using YAML configuration file template and related generated config data using
_iio-cli_

Currently, applicaiton is configured to use YAML configuration by default. See
_dev_start.sh_ script to check it:

```bash

#!/bin/sh

if command -v iio 2>/dev/null; then
  iio infra dev
  # HERE ------------------------------------------------
  iio config app generate
  # -----------------------------------------------------
  if [ $? -ne 0 ]
  then
    echo "iio version must be >=2.2.1: 'npm i -g @ignitial/iio-cli'"
    exit 1
  fi
else
  echo "iio not installed: 'npm i -g @ignitial/iio-cli'"
  exit 1
fi
```  

Command _iio config app generate_ will generate json configuration in the
_server/config_ folder. It uses _config/app.yaml_ for that, while _app.yaml_
references _config/i18n.yaml_ file for i18n translations.  
When generated file detected, it is automatically used for providing application
configuration.

The same can be done for Kubernetes deployments. That time it is necessary to use
a ConfigMap receipe, which is already done in the template.  
You just need to update _k8s/config/deploy.yaml_ and _k8s/config/app.yaml_ as per
your needs. First one defines Kubernetes related configuration (mainly references
used in K8S receipes), while the second one is equivalent to _config/app.yaml_
file, but for K8S deploy.

### Run for development

#### Start app and associated services

```bash
npm run dev:start
```

#### Stop and clean up

```bash
npm run dev:stop
```

### Run with minikube

> __Note__
>  
> You need minikube installed and configured.

First, you need to create app and dlake images and publish them to minikube docker
environment:

```bash
npm run docker:build
npm run docker:publish:minikube
```

> __Note__
>   
> This uses _ignitial/dlake_ and _ignitial/auth_ images published on Docker Hub.

```bash
iio deploy
```

And it works:

[![asciicast](https://asciinema.org/a/0lgSjc7qy526Mgqj6DUTmSSWx.svg)](https://asciinema.org/a/0lgSjc7qy526Mgqj6DUTmSSWx)

#### Clean up

```bash
iio remove
```

> _WARNING_: this will erase Redis persistent volume and then you will lose current
> roles and users. On production deploy, you need to separate PV management from
> deployment itself.

> __Note__
>   
> This will not stop minikube cluster.

### Run for production

You need first to push app image to some private registry (currently targets
GitLab one, but you can obviously conifigure tour own replacing that registry
name).

```bash
npm run docker:publish:private
```  

Then you need to update your .kube/config file or to point out any kubeconfig file
that targets the right Kubernetes cluster (in this second situation, you need to
update accordingly related _cluster.kubeConfigPath_ in _k8s/config/deploy.yaml_
file). Then, same as previously:

```bash
iio deploy
```

Done !