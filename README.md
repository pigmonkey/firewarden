# Firewarden

Firewarden is a shell script used to open a file via the specified application
within a private [Firejail](https://github.com/netblue30/firejail) sandbox.

This is accomplished by creating a temporary directory, copying the given file
into it, and then specifying that temporary directory be used by Firejail as
the user home. After the application has closed, the temporary directory and
all of its contents are deleted.

Firewarden makes it easy to take advantage of Firejail's protection. It is
useful for mitigating harm caused by opening potentially compromised files,
such as PDF and JPGs. Add it to your mailcap to protect your system against
shady email attachments.

## Sandbox Protection

In addition to a private home directory, the sandbox will also be launched with
a private `/dev` and with no network access. Further protection will be
inherited from the appropriate Firejail profile.

See `man 1 firejail` and `man 5 firejail-profile` for more details.

### Private Home

The behaviour of Firewarden is similar to using Firejail's `--private-home`
option, but with a shorter syntax and the added benefit of working on files
outside of the user's home directory.

The following commands are equivalent:

    $ firejail --private-dev --net=none --private-home=~/notatrap.pdf zathura notatrap.pdf
    $ firewarden zathura ~/notatrap.pdf

However, the following will fail due to the location of the file:

    $ firejail --private-dev --net=none --private-home=/media/sdc1/notatrap.pdf zathura notatrap.pdf

Instead, use Firewarden:

    $ firewarden zathura /media/sdc1/notatrap.pdf
