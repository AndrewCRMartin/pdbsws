#!/bin/sh
#########################################################################
# You NEED to alter these...
############################
# The final output map of PDB to SwissProt
PDBSWSMAP=/acrm/data/pdbuniprot/pdb_uniprot_map.lst
PDBSWSCHN=/acrm/data/pdbuniprot/pdb_uniprot_chain_map.lst
PDBSWSMUT=/acrm/data/pdbuniprot/pdb_uniprot_mutants.xml
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
# The location of the web interface
WEB=/acrm/www/html/pdbsws/
UPDATEFILE=$WEB/lastupdate.tt
# How old a non-exact hit should be before re-scanning it
DAYSOLD=150
# Path needed for tpage when re-making the web pages
export PATH="$PATH:/acrm/usr/local/bin" 
#### Note! you also need to alter the makefile to give the
#### paths to the sprot and trembl files

#########################################################################
# Should NEVER need to alter below here...
##########################################

# Populate from trEMBL data
#echo -n "Starting trEMBL : "
#date
#$PROGS/ProcessSProt.pl -dbname=$DB $TREMBL_DATA &> $LOGS/ProcessTrembl.log

# Vacuum the database
#echo -n "Vacuum/analyze database : "
#date
#psql $DB -c 'vacuum analyze'

# 06.03.07 Moved SwissProt after trEMBL in case entries appear in both
# (by mistake) SwissProt will have priority
# Populate from SwissProt data
#echo -n "Starting SwissProt : "
#date
#$PROGS/ProcessSProt.pl -dbname=$DB $SPROT_DATA  &> $LOGS/ProcessSProt.log

# Vacuum the database
#echo -n "Re-analyze database : "
#date
#psql $DB -c 'vacuum analyze'

# Populate main table from PDB data
#echo -n "Starting PDB : "
#date
#$PROGS/ProcessPDB.pl -dbname=$DB $PDBDIR      &> $LOGS/ProcessPDB.log

# Now fix referencing from PDB table, patching in information
# from the SwissProt/trEMBL for single-chain PDB files
#echo -n "Starting FiXPDB : "
#date
#$PROGS/FixPDBData.pl -dbname=$DB              &> $LOGS/FixPDBData.log

# Patch in information from SwissProt/trEMBL for multi-chain PDB files
#echo -n "Starting Multi-chains from SwissProt : "
#date
#$PROGS/MatchSprotData.pl -dbname=$DB     &> $LOGS/MatchSprotData.log

# Vacuum the database
#echo -n "Re-analyze database : "
#date
#psql $DB -c 'vacuum analyze'

# Build the combined SwissProt/trEMBL database if necesary
#echo -n "Starting Build FASTA file : "
#date
#$PROGS/MakeFASTA.pl $SPROT_FASTA $TREMBL_FASTA $SPROT_TREMBL
#make -f $PROGS/makefile sprottrembl

# Run the brute-force scan on remaining un-assigned sequences
echo -n "Starting Brute Force Scan : "
date
$PROGS/BruteForceScan.pl -noupdates -dbname=$DB -daysold=$DAYSOLD $SPROT_TREMBL &> $LOGS/BruteForceScan.log

# Vacuum the database
echo -n "Re-analyze database : "
date
psql $DB -c 'vacuum analyze'

# Finally create the alignments and dump the results
echo -n "Starting Alignments : "
date
$PROGS/DoAlignments.pl -dbname=$DB   &> $LOGS/DoAlignments.log
echo -n "Starting By-residue Dump : "
date
$PROGS/dump_mapping.pl -dbname=$DB >${PDBSWSMAP}.2
mv ${PDBSWSMAP}.2 $PDBSWSMAP
echo -n "Starting By-chain Dump : "
date
$PROGS/dump_chain_mapping.pl -dbname=$DB >${PDBSWSCHN}.2
mv ${PDBSWSCHN}.2 $PDBSWSCHN

# Vacuum the database
echo -n "Re-analyze database : "
date
psql $DB -c 'vacuum analyze'

# Extract mutants from the final map
$PROGS/findmutants.pl $PDBSWSMAP > ${PDBSWSMUT}.2
mv ${PDBSWSMUT}.2 $PDBSWSMUT

# Update the web interface so the date is displayed correctly
date | awk '{print $3, $2, $6}' > $UPDATEFILE
sleep 2
(cd $WEB; make)

# All done!
echo -n "Finished : "
date
