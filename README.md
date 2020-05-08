# Ngindock

> *Zero-downtime Docker container deployments with nginx.*

Ngindock starts your new container on a different port to the old one, waits for it to look healthy (by HTTP 200 status check),
then rewrites your `nginx.conf` to direct traffic to the new port, and finally stops the old container and renames the
new one in its place.

## Installation

TODO: Update this to something more "production".

For now, just check out https://github.com/jes/ngindock in your home directory, and run it like:

    $ PERL5LIB=lib ./ngindock

## Usage

This documentation assumes that you are running nginx on the host system and not inside a container. If you're running
it inside a container than you'll most likely want to run Ngindock inside the same container as nginx.

Create an `ngindock.yaml` file for the project you want to hot-deply, looking something like this:

    nginx_conf: /etc/nginx/conf.d/app.conf
    nginx_upstream: app
    ports: [3000,3001]
    container_port: 8080
    image_name: app_image
    container_name: app_container
    health_url: /health-check

See below for documentation of the individual fields.

To perform a hot-deploy, simply run:

    $ ngindock

Or:

    $ ngindock -c ngindock-production.yaml

To specify a config file name.

Add `-v` or `-v -v` to get more verbose output.

## Configuration

The configuration is in a YAML file, by default read from `ngindock.yaml`.

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

The port numbers you want to use to direct traffic to your application. Typically there would be
exactly 2 here, but you are allowed to specify more than 2, and if you specify more then they'll
be used in sequence.

Example:

    ports: [3000,3001]

### container_port (required)

The port number on your container that you want traffic to come into.

Example:

    container_port: 8080

### image_name (required)

### container_name (required)

### health_url (optional)

The URL on your application to request to find out whether the application is healthy. Only
when this URL starts returning a 200 status code will the nginx config be updated.

If this field is not present, then the health check will be skipped.

Example:

    health_url: /health-check

### health_sleep (optional)

A number of seconds to sleep before considering the new container healthy. If used in
combination with `health_url`, then this will sleep *after* the URL starts returning
200.

If this field is not present, then no sleep will occur.

Example:

    health_sleep: 5

### docker_opts (optional)

Extra parameters you want to pass to `docker run`. This will be split on space characters
before being passed as multiple arguments.

Example:

    docker_opts: "--device=/dev/snd:/dev/snd"
