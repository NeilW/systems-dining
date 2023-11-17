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

The philosophers now enter the thinking state and set a time in the
future when they will become hungry

Once a philosopher reaches the hungry target
they email their dining neighbours asking for the shared fork.

A sendmail '.forward' file runs a program for each email received.

For each fork request related to a sender
- if we have a dirty fork, or a clean fork and we're not hungry, we
  delete the fork and send a fork response back.
- otherwise we inform the mail system to queue and redeliver the message in the future.

For each fork response a clean fork is created.

Once a philosopher has two clean forks they enter the eating state and
set a time in the future when they will start thinking again.

Before they enter the thinking state again, any forks they own are marked
as sticky.

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

Open the dining room

    ubuntu@srv-5o1ic:~/systemd-dining$ sudo open_dining_room

Check a philosopher's activity

    ubuntu@srv-5o1ic:~/systemd-dining$ npcjournal hegel
    Nov 14 09:15:33 srv-5o1ic select-seat[7048]: The Dining Room is open. Looking for a seat.
    Nov 14 09:15:33 srv-5o1ic select-seat[7048]: I have seat #6
    Nov 14 09:15:33 srv-5o1ic select-seat[7048]: Acquired sticky fork #7

## Stop the simulation

Close the dining room

    ubuntu@srv-5o1ic:~/systemd-dining$ sudo close_dining_room

Remove the philosophers

    ubuntu@srv-2q8eh:~/systemd-dining$ awk '{print $1}' philosophers | xargs sudo /usr/local/sbin/remove_philosopher
