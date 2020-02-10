#!/bin/sh
#########################################################################
# You NEED to alter these...
############################
PROGS=/home/bsm/martin/pdbcec_new/fixit/

$PROGS/fixchainnames.pl &>fixchainnames_100309b.out
$PROGS/checkdna.pl &>checkdna_100309.out

