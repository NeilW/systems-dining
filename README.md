# Dining Philosophers using systemd.

The dining philosophers problem is a classic in Computer Science that
illustrates the major issues with concurrency.

Most people immediately reach for their favourite programming language
to attack this problem but here we're going to do something different.

The Linux operating system is a multi-user concurrent system which is
designed to have separate people using it all at the same time. Most of
this remains unused these days.

So I thought it would be fun to bring back the multi-user power of Unix
via a set of NPCs fighting over some rather fiddly pasta, while driving
the characters using the user level systemd functions.

All while allowing the real world adminstrator to watch each user via
the logging systems.

We're going to use classic Unix tools from the archives and give the
Unix Programming Environment a work out it hasn't seen for a good while.

## Design overview

We'll be using is a variant of the Chandry/Misra 'hygiene' solution to
the Dining Philosophers problem.

Each philosopher is a separate user ID on the server and sits in its
own unix group. It is also a member of the 'philosophers' group which
has access to the dining room at /home/share/dining-room.

The philosophers run autonomously and take their seats once the
dining-room is open (writable by group 'philosophers'). Seats are
dynamically allocated on a first come first served basis with each
philosopher grabbing the first seat they can by creating a file in the
dining room with their seat number on it that nobody else can write to.

Once a philosopher has taken a seat they will pick up a 'sticky' fork
by creating a fork file with their name on it, the number of the *next*
position and the 'sticky bit' set.  The philosopher in seat #1 will
exercise their head of the table privilege and take the 'sticky' fork #1 as well.

Now the philosophers think for a while until they get hungry by scheduling
a transient systemd job in the future.

Once a philosopher gets hungry they email their dining neighbours asking
for the shared fork.

## Installation

From an Ubuntu LTS server logged in as the admin user and run the setup script

    ubuntu@srv-2q8eh:~$ git clone git@github.com:NeilW/systemd-dining.git
    Cloning into 'systemd-dining'...
    ...
    ubuntu@srv-2q8eh:~$ cd systemd-dining/
    ubuntu@srv-2q8eh:~/systemd-dining$ sudo ./setup.sh
    Adding required packages
    ...
    Installing simulation

## Run the simulation

Create the philosophers

    ubuntu@srv-2q8eh:~/systemd-dining$ xargs -L 1 sudo /usr/local/sbin/create_philosopher < philosophers

Check the 

## Stop the simulation

Remove the philosophers

    ubuntu@srv-2q8eh:~/systemd-dining$ awk '{print $1}' philosophers | xargs sudo /usr/local/sbin/remove_philosopher
