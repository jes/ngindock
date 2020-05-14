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

2. Install any missing CPAN dependencies, for example:

    $ sudo apt install libyaml-perl

2. Build the docker image:

    $ docker build -t ngindock_demo_app .

3. Start nginx:

    $ ./start-nginx.sh

4. Start the application:

    $ docker run -d -p 3001:3000 ngindock_demo_app

Alternatively, you can start it using Ngindock:

    $ PERL5LIB=../lib ../ngindock -v -v

5. Check that the application is working, fetched through the nginx listening
on port 3000:

    $ curl http://localhost:3000
    OK!

6. Edit the application to send different content:

    $ sed -i 's/OK/Hello/' ./app

7. Rebuild the docker image:

    $ docker build -t ngindock_demo_app .

8. Use ngindock to switch over to the new image with no downtime:

    $ PERL5LIB=../lib ../ngindock -v -v

9. Check that the application is still working and up-to-date:

    $ curl http://localhost:3000
    Hello!

10. When you're finished with nginx, you can stop it:

    $ ./stop-nginx.sh
