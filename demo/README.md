This directory contains a (hopefully) working setup to demonstrate Ngindock.

You might want to familiarise yourself with `ngindock.yaml` and `nginx.conf`
in this directory so as to better understand what is going on.

For the purposes of the demonstration we're using nginx_opts with "-p ." so
that we can pass a relative path to the nginx configuration, but in real life
you'll probably just use an absolute path and remove nginx_opts.

We'll have nginx listening on port 3000, and our application container
alternating between ports 3001 and 3002 with each deployment.

This has been tested on Ubuntu 20.04 LTS.

1. Install nginx, for example:

    $ sudo apt install nginx-light

2. Install ngindock, see `../README.md`

3. Build the docker image:

    $ docker build -t ngindock_demo_app .

4. Start nginx:

    $ ./start-nginx.sh

5. Start the application:

    $ docker run -d -p 3001:3000 ngindock_demo_app

Alternatively, you can start it using Ngindock:

    $ ngindock -v -v

6. Check that the application is working, fetched through the nginx listening
on port 3000:

    $ curl http://localhost:3000
    OK!

7. Edit the application to send different content:

    $ sed -i 's/OK/Hello/' ./app

8. Rebuild the docker image:

    $ docker build -t ngindock_demo_app .

9. Use ngindock to switch over to the new image with no downtime:

    $ ngindock -v -v

10. Check that the application is still working and up-to-date:

    $ curl http://localhost:3000
    Hello!

11. When you're finished with nginx, you can stop it:

    $ ./stop-nginx.sh
