# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

###--------------------------------
### Added for VoltDB
###--------------------------------

VOLT_VERSION="11.4"
JAVA_VERSION="jdk-11.0.4"

PATH="${PATH}:${HOME}/voltdb-ent-${VOLT_VERSION}/bin:${HOME}/bin:${HOME}/bin/${JAVA_VERSION}/bin"

JAVA_HOME=${HOME}/bin/${JAVA_VERSION}

export VOLT_VERSION
export PATH
export JAVA_HOME

# Set VOLTDB_HEAPMAX
VOLTDB_HEAPMAX=5000
export VOLTDB_HEAPMAX

# Set Java Params

JAVA_MAJOR_VERSION=11
export JAVA_MAJOR_VERSION

if
        [ "$JAVA_MAJOR_VERSION" -ge 11 ]
then
    JVMOPTS="--add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.net=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED"
fi

###--------------------------------