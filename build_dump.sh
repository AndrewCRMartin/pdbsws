#!/bin/sh
#########################################################################
# You NEED to alter these...
############################
# The final OUTPUT maps of PDB to SwissProt
PDBSWSMAP=/acrm/data/pdbuniprot/pdb_uniprot_map.lst
PDBSWSCHN=/acrm/data/pdbuniprot/pdb_uniprot_chain_map.lst
PDBSWSMUT=/acrm/data/pdbuniprot/pdb_uniprot_mutants.xml
# The SwissProt and trEMBL files
SPROT_DATA=/acrm/data/swissprot/full/uniprot_sprot.dat
TREMBL_DATA=/acrm/data/swissprot/full/uniprot_trembl.dat
SPROT_FASTA=/acrm/data/swissprot/full/uniprot_sprot.fasta
TREMBL_FASTA=/acrm/data/swissprot/full/uniprot_trembl.fasta
# Temp working directory (needs lots of space)
TMPDIR=/acrm/data/tmp/pdbsws
# Where the PDB lives
PDBDIR=/acrm/data/pdb
# Location of the scripts, logs and touch files
PROGS=/home/bsm/martin/pdbcec_new/
LOGS=/home/bsm/martin/pdbcec_new/
TOUCH=/home/bsm/martin/pdbcec_new/
# Name of database
DB=pdbsws
# The location of the web interface
WEB=/acrm/www/html/pdbsws/
# How old a non-exact hit should be before re-scanning it
DAYSOLD=150
# Path needed for tpage when re-making the web pages
export PATH="$PATH:/acrm/usr/local/bin" 
#### Note! you also need to alter the makefile to give the
#### paths to the sprot and trembl files

#########################################################################
# Should NEVER need to alter below here...
##########################################
# The SwissProt and Trembl FASTA file
SPROT_TREMBL=$TMPDIR/sprottrembl.faa
UPDATEFILE=$WEB/lastupdate.tt

# Now dump the results
echo -n "Starting By-residue Dump : "
date
$PROGS/dump_mapping.pl -dbname=$DB >${PDBSWSMAP}.2
gzip -c ${PDBSWSMAP}.2 > ${PDBSWSMAP}.2.gz
mv ${PDBSWSMAP}.2 ${PDBSWSMAP}
mv ${PDBSWSMAP}.2.gz ${PDBSWSMAP}.gz

echo -n "Starting By-chain Dump : "
date
$PROGS/dump_chain_mapping.pl -dbname=$DB >${PDBSWSCHN}.2
gzip -c ${PDBSWSCHN}.2 > ${PDBSWSCHN}.2.gz
mv ${PDBSWSCHN}.2 ${PDBSWSCHN}
mv ${PDBSWSCHN}.2.gz ${PDBSWSCHN}.gz

# Extract mutants from the final map
$PROGS/findmutants.pl ${PDBSWSMAP} > ${PDBSWSMUT}.2
gzip -c ${PDBSWSMUT}.2 > ${PDBSWSMUT}.2.gz
mv ${PDBSWSMUT}.2 ${PDBSWSMUT}
mv ${PDBSWSMUT}.2.gz ${PDBSWSMUT}.gz

# Update the web interface so the date is displayed correctly
date | awk '{print $3, $2, $6}' > $UPDATEFILE
sleep 2
(cd $WEB; make)

# All done!
echo -n "Finished : "
date
