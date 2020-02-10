#!/bin/sh
#########################################################################
# You NEED to alter these...
############################
# The final output map of PDB to SwissProt
PDBSWSMAP=/acrm/data/tmp/pdb_sws_map.lst
# The SwissProt and trEMBL files
SPROT_DATA=/acrm/data/swissprot/full/uniprot_sprot.dat
TREMBL_DATA=/acrm/data/swissprot/full/uniprot_trembl.dat
SPROT_FASTA=/acrm/data/swissprot/full/uniprot_sprot.fasta
TREMBL_FASTA=/acrm/data/swissprot/full/uniprot_trembl.fasta
# Where the PDB lives
PDBDIR=/acrm/data/pdb
LOGS=/home/bsm/martin/pdbcec_new/
TOUCH=/home/bsm/martin/pdbcec_new/
# The SwissProt and Trembl FASTA file
SPROT_TREMBL=/acrm/data/tmp/sprottrembl.faa
# Location of the scripts
PROGS=/home/bsm/martin/pdbcec_new/
# Name of database
DB=pdbsws
#### Note! you also need to alter the makefile to give the
#### paths to the sprot and trembl files

#########################################################################
# Should NEVER need to alter below here...
##########################################


# Finally create the alignments and dump the results
echo -n "Starting Alignments : "
date
$PROGS/DoAlignments.pl -dbname=$DB   &> $LOGS/DoAlignments.log
echo -n "Starting Dump : "
date
$PROGS/dump_mapping.pl -dbname=$DB >${PDBSWSMAP}.2
mv ${PDBSWSMAP}.2 $PDBSWSMAP

# Vacuum the database
echo -n "Re-analyze database : "
date
psql $DB -c 'vacuum analyze'

# All done!
echo -n "Finished : "
date
