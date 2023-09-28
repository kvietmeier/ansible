#!/bin/sh

. $HOME/.profile

cd
cd bin

sqlcmd --servers=$1 < create_runoncepercluster.sql

