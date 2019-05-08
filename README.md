# Firewarden

Firewarden is a bash script used to open a program within a private
[Firejail][1] sandbox.

Firewarden will launch the given program within a Firejail sandbox with a
private home directory on a temporary filesystem. Networking is enabled by
default, but may be disabled.

This may be useful for a number of applications, but was created specifically
with Chromium in mind. To open a [shady site][2] within an isolated and
temporary sandbox -- or simply to help further protect your online banking --
prepend your normal command with `firewarden`:

    $ firewarden chromium http://www.forbes.com

## Local Files

If the final argument appears to be a local file, Firewarden will copy the file
into a temporary directory. This directory will be used by Firejail as the user
home. After the program has closed, the temporary directory and all of its
contents are deleted.

By default, networking is disabled and a private `/dev` is used when viewing a
local file.

This is particularly useful for mitigating harm caused by opening potentially
malicious files, such as PDF and JPGs. Add it to your mailcap to protect your
system against shady email attachments.

For example, you may want to view the file `~/notatrap.pdf` with the PDF reader `zathura`.

    $ firewarden zathura ~/notatrap.pdf

This is the equivalent of doing:

    $ export now=`date --iso-8601=s`
    $ mkdir -p $XDG_RUNTIME_DIR/$USER/firewarden/$now
    $ cp ~/notatrap.pdf $XDG_RUNTIME_DIR/$USER/firewarden/$now/
    $ firejail --net=none --private-dev --private=$XDG_RUNTIME_DIR/$USER/firewarden/$now zathura notatrap.pdf
    $ rm -r $XDG_RUNTIME_DIR/$USER/firewarden/$now

## Options

### Configuration Script

When the `-c` option is specified, Firewarden will attempt to locate and
execute a configuration script named for the application in
`$XDG_CONFIG_HOME/firewarden/$APP.sh`. For example, executing `firewarden -c
chromium` will cause Firewarden to check for
`$XDG_CONFIG_HOME/firewarden/chromium.sh`. If this script exists, it will be
passed the variables `$FIREWARDEN_HOME` (corresponding to the home directory of
the sandbox) and `$FIREWARDEN_FILE` (corresponding to the name of the local
file, if appropriate), and executed.

This may be used as a way to configure applications within the temporary
filesystem of the sandbox. For example, you may install your normal Chromium
preferences file:

    #!/bin/sh
    mkdir -p "$FIREWARDEN_HOME/.config/chromium/Default"
    cp "$HOME/.config/chromium/Default/Preferences "$FIREWARDEN_HOME/.config/chromium/Default"

Or, rather than installing your complete Zathura config, you may want to just
configure zoom keys.

    #!/bin/sh
    mkdir -p "$FIREWARDEN_HOME/.config/zathura"
    echo "map <C-i> zoom in" >> "$FIREWARDEN_HOME/.config/zathura/zathurarc"
    echo "map <C-o> zoom out" >> "$FIREWARDEN_HOME/.config/zathura/zathurarc"

Or, you may wish to ensure that, if a local file was provided, you always have
permission to write to it in the sandbox.

    #!/bin/sh
    if [ -n "$FIREWARDEN_FILE" ] && [ -r "FIREWARDEN_HOME/$FIREWARDEN_FILE" ]; then
        chmod u+w "FIREWARDEN_HOME/$FIREWARDEN_FILE"
    fi

### Network

Networking is enabled by default, unless viewing local files (which most of the
time do not need network access).

The user may explicitly enable or disable network access, overriding the default behavior.

    # deny network access, regardless of the defaults.
    $ firewarden -n ...
    # enable network access, regardless of the defaults.
    $ firewarden -N ...

Optionally, the sandbox may be launched with an isolated network namespace and
a restrictive netfilter. Unless otherwise specified, [NetworkManager][3] will
be used to determine the first connected network interface. This interface will
be used to create the new network namespace.

    # isolate the network, using the first connected interface.
    $ firewarden -i ...
    # isolate the network, using the specified interface.
    $ firewarden -I eth0 ...

When isolating the network, Firejail's default client network filter will be
used in the new network namespace.

```
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
# allow ping
-A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
-A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
-A INPUT -p icmp --icmp-type echo-request -j ACCEPT
# drop STUN (WebRTC) requests
-A OUTPUT -p udp --dport 3478 -j DROP
-A OUTPUT -p udp --dport 3479 -j DROP
-A OUTPUT -p tcp --dport 3478 -j DROP
-A OUTPUT -p tcp --dport 3479 -j DROP
COMMIT

```

### /dev

Optionally, a new `/dev` can be created to further restrict the sandbox. This
has the effect of preventing access to audio input and output, as well as any
webcams. It is enabled by default when viewing local files.

    # create a private /dev, regardless of the defaults.
    $ firewarden -d ...
    # do not create a private /dev, regardless of the defaults.
    $ firewarden -D ...

## Application Flags

Firewarden will always add certain flags when it executes specific applications.

### Chromium

When executing `chromium` or `google-chrome`, Firewarden will prevent the first run
greeting, disable the default browser check, and prevent WebRTC IP leak.

* `--no-first-run`
* `--no-default-browser-check`
* `--enforce-webrtc-ip-permission-check`

### Qutebrowser

When executing `qutebrowser`, Firewarden will set the basedir to `~/basedir`
within the sandbox home directory to prevent session-sharing attempts.

* `--basedir`

## Examples

    $ firewarden -d -i chromium https://www.nsa.gov/ia/ &
    $ firewarden zathura /mnt/usb/nsa-ant.pdf &
    $ firewarden chromium https://www.youtube.com/watch?v=bDJb8WOJYdA &
    $ firejail --list
    630:pigmonkey:/usr/bin/firejail --private --net=enp0s25 --netfilter --private-dev chromium --no-first-run --no-default-browser-check https://www.nsa.gov/ia/
    31788:pigmonkey:/usr/bin/firejail --private=/run/user/1000/firewarden/2016-01-31T16:09:14-0800 --net=none --private-dev zathura nsa-ant.pdf
    32255:pigmonkey:/usr/bin/firejail --private chromium --no-first-run --no-default-browser-check https://www.youtube.com/watch?v=bDJb8WOJYdA


[1]: https://github.com/netblue30/firejail
[2]: http://www.engadget.com/2016/01/08/you-say-advertising-i-say-block-that-malware/
[3]: https://wiki.gnome.org/Projects/NetworkManager
