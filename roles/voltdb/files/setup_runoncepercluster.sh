#!/usr/bin/bash
# Not sure what this does - loads some data?

. ${HOME}/.profile

servers=$(tr '\n' ',' < ${HOME}/.vdbhostnames | sed 's/,$//')

cd ${HOME}/bin

sqlcmd --servers=$servers < create_runoncepercluster.sql