# Ngindock

> *Zero-downtime Docker container deployments with nginx.*

Ngindock starts a new container on a different port to the old one, waits for the new container to look healthy (by HTTP 200 status check),
then rewrites your `nginx.conf` to direct traffic to the new port, and finally stops the old container and renames the
new one in its place.

Please see the "Caveats" section before wielding this against anything important.

## Who is it for?

Ngindock is for you if you already run nginx as a reverse proxy and want to incrementally dockerise one or more services with a minimum of
disruption.

If you think traefik, kubernetes, or docker-swarm might be more appropriate for your use case, you're probably right.

## Installation

First install the CPAN module dependencies, which are `Getopt::Long`, `IPC::Run`, `LWP::UserAgent`, and `YAML::XS`. On Ubuntu 20.04, you'll
only have to:

    $ sudo apt install libyaml-perl

Ngindock is packaged as a single Perl script file created by concatenating all the library files together with the program, look in `Makefile` to see
how it works.

Install it with:

    $ sudo make install

Then you can run it with:

    $ ngindock

anywhere that has an `ngindock.yaml`.

## Usage

This documentation assumes that you are running nginx on the host system and not inside a container. If you're running
it inside a container than you'll most likely want to run Ngindock inside the same container as nginx.

Create an `ngindock.yaml` file for the project you want to hot-deploy, looking something like this:

    nginx_conf: /etc/nginx/conf.d/app.conf
    nginx_upstream: app
    ports: [3000,3001]
    container_port: 8080
    image_name: app_image
    container_name: app_container
    health_url: /health-check

See below for documentation of the individual fields.

To get Ngindock to create your new container but not tear down the existing one (so that you can test that it is
working correctly), run with `--dry-run`:

    $ ngindock --dry-run

To perform a hot-deploy, simply pull (or build) your updated image and run:

    $ ngindock

Or, to specify a config file name:

    $ ngindock -c ngindock-production.yaml

Add `-v` or `-v -v` to get more verbose output.

    Usage: ngindock [-c config] [-n] [-v -v]

    Options:
        -c,--config FILE    Set config file to read from.
        -n,--dry-run        Create the new container but don't redirect traffic.
        -v,--verbose        Enable verbose output. Specify twice for more.

## Configuration

The configuration is in a YAML file, by default read from `ngindock.yaml`. Documentation here is grouped by
required options first and optional options second, and sorted lexically within those groups.

### container_name (required)

The name to use for the Docker container to be created, and for the old container to be destroyed.

Example:

    container_name: app_container

### container_port (required)

The port number on your container that you want traffic to come to. Also see `ports`.

Example:

    container_port: 8080

### image_name (required)

The name of the Docker image to use when creating containers.

Example:

    image_name: app_image

### nginx_conf (required)

The path to the nginx configuration file containing the "upstream" directive
that sends traffic to your container.

Example:

    nginx_conf: /etc/nginx/conf.d/app.conf

### nginx_upstream (required)

The name of the "upstream" directive used by your application.

Example:

    nginx_upstream: app

### ports (required)

The host port numbers you want to use to direct traffic to your application. Typically there would be
exactly 2 here, but you are allowed to specify more than 2, and if you specify more then they'll
be used in sequence. Also see `container_port`.

Example:

    ports: [3000,3001]

### docker_opts (optional)

Extra parameters you want to pass to `docker run`. This will be split on space characters
before being passed as multiple arguments.

Example:

    docker_opts: "--device=/dev/snd:/dev/snd"

### grace_period (optional)

A number of seconds to sleep between the new container becoming healthy and stopping the old
container. This is to allow for completion of long-running requests that are still being handled
by the old container.

If this field is not present, then no sleep will occur.

Example:

    grace_period: 30

### health_sleep (optional)

A number of seconds to sleep before considering the new container healthy. If used in
combination with `health_url`, then this will sleep *after* the URL starts returning
200.

If this field is not present, then no sleep will occur.

Example:

    health_sleep: 5

### health_url (optional)

The URL on your application to request to find out whether the application is healthy. Only
when this URL starts returning a 200 status code will the nginx config be updated.

If this field is not present, then the health check will be skipped.

Example:

    health_url: /

### nginx_opts (optional)

Extra parameters you want to pass to `nginx -s reload`. This will be split on space
characters before being passed as multiple arguments.

Example:

    nginx_opts: "-p ."

## Caveats

It operates Docker by running `docker run ...` etc. rather than using the API.

It assumes your upstream directive looks basically like this:

    upstream app {
        server 127.0.0.1:3000;
    }

In particular, it is currently hard-coded to require "127.0.0.1:" before the port number.

If it gets stuck in a situation where the running container and the nginx config do not match (for
example it bailed out partway through a previous attempt), you need to manually fix that before it
will work.

## Future improvements

We'd want to support the use case where nginx is running inside docker and forwarding traffic to changing container names with
a fixed port number, instead of always 127.0.0.1 with changing port numbers.

We'd possibly want to copy the docker config of the existing container instead of having to put everything in `docker_opts`, using
something like https://github.com/lavie/runlike

It should perhaps be packaged as a Docker image that you then connect to your nginx config and docker socket, and perform a hot-deployment
with:

    $ docker run --rm -v ngindock.yaml:/ngindock.yaml -v /etc/nginx/conf.d/app.conf:/nginx.conf -v /var/run/docker.sock:/var/run/docker.sock ngindock

Should probably have automated testing.

## Contact

Ngindock is developed by James Stanley. You can email me on james@incoherency.co.uk or
read my blog at https://incoherency.co.uk/.
