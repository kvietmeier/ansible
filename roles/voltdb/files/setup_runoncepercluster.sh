#!/usr/bin/bash
# Not sure what this does - loads some data?

. $HOME/.profile

cd
cd bin

sqlcmd --servers=$1 < create_runoncepercluster.sql