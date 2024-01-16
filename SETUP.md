# Installing and running the simulation

The simulation is designed to run on an Ubuntu server within the Brightbox
cloud, although it should work on Ubuntu anywhere. Patches welcome for
any discrepencies

## Installation

Create an Ubuntu Brightbox server [using the control panel](https://cloud.brightbox.com/login). Use the latest
Ubuntu version you can. If you want the simulation to be available over
IPv4 then map a CloudIP to the server.

Log on to the server and run the setup script directly from Github.

    $ curl https://raw.githubusercontent.com/NeilW/systemd-dining/master/setup.sh | sudo sh

This will install the support software, download the simulation and
setup both a web terminal and a secure socket forwarder protected by a
Let's Encypt TLS certificate.

## Running the simulation container

To start the simulation run

    $ sudo machinectl start philosophers

To stop the simulation run

    $ sudo machinectl stop philosophers

To access the simulation as the adminstrator

    $ sudo machinectl shell philosophers

The adminstrator [starts and stops the simulation](README.md) from the shell.

To remove the simulation so it can be reinstalled

    $ sudo machinectl remove philosophers
    $ sudo machinectl clean

## Reinstallation

Removing the simulation should be enough to allow you to run the setup
script again and pull down the latest version. Be warned it
removes all the data - including any agents or philosophers you've setup.

If you have added or removed a cloudip, and rerun the setup to generate
a new certificate you'll have to restart the terminal services to pick
it up. An expiring certificate will require the same treatment.

Run the following from the server, not the simulation container

    $ sudo systemctl try-restart wsssh tlssh

## Add third party agents

You can add users (agents) who can query the simulation. First access
the simulation as the administrator.

To add an agent

    # create_agent agent1 "Agent One"

To remove an agent

    # remove_agent agent1

When an agent is created, the first access will require the user to set a password.

## Accessing the simulation

You can access the simulation either via a browser or directly from a terminal.

### Browser access

You can bring up a terminal session by pointing any web browser at the public address of the server, e.g.

    https://public.srv-testy.gb1.brightbox.com

### Terminal access

In addition, for hard core enthusiasts, the underlying direct terminal
access is exposed on port 8000 of the server and you can get to that
using the `socat` or `openssl` commands

With `socat` use:

    $ socat STDIN,cfmakeraw OPENSSL:public.srv-testy.gb1.brightbox.com:8000

With `openssl` use:

    $ stty raw -echo; openssl s_client -connect public.srv-testy.gb1.brightbox.com:8000 -tls1_3; reset

You will need to add the server to a server group with port 8000 open for TCP.

## Logging on as an agent

Once you have the simulation terminal window open, follow the on screen
prompts to gain access. If this is the first time using an agent, then
you will have to set a password.
