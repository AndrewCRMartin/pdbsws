#!/bin/sh
#########################################################################
# You NEED to alter these...
############################
# The final output map of PDB to SwissProt
PDBSWSMAP=/home/bsm/martin/pdbcec_new/testdata/out.map
# The SwissProt file
SPROT_DATA=/home/bsm/martin/pdbcec_new/testdata/sprot/test.sprot
TREMBL_DATA=/home/bsm/martin/pdbcec_new/testdata/sprot/test.trembl
SPROT_FASTA=/home/bsm/martin/pdbcec_new/testdata/sprot/sprot.faa
TREMBL_FASTA=/home/bsm/martin/pdbcec_new/testdata/sprot/trembl.faa
# Where the PDB lives
PDBDIR=/home/bsm/martin/pdbcec_new/testdata/pdb
LOGS=/home/bsm/martin/pdbcec_new/testdata
TOUCH=/home/bsm/martin/pdbcec_new/testdata
# The SwissProt and Trembl FASTA file
SPROT_TREMBL=/home/bsm/martin/pdbcec_new/testdata/sprottrembl.faa
# Location of the scripts
PROGS=/home/bsm/martin/pdbcec_new/
# Name of database
DB=pdbswstest

#########################################################################
# Should NEVER need to alter below here...
##########################################

# Populate from SwissProt data
echo -n "Starting SwissProt : "
date
$PROGS/ProcessSProt.pl -dbname=$DB   $SPROT_DATA  &> $LOGS/ProcessSProt.log

# Populate from trEMBL data
echo -n "Starting trEMBL : "
date
$PROGS/ProcessSProt.pl -dbname=$DB  $TREMBL_DATA &> $LOGS/ProcessTrembl.log

# Vacuum the database
echo -n "Vacuum/analyze database : "
date
psql $DB -c 'vacuum analyze'

# Populate main table from PDB data
echo -n "Starting PDB : "
date
$PROGS/ProcessPDB.pl -dbname=$DB $PDBDIR      &> $LOGS/ProcessPDB.log

# Now fix referencing from PDB table, patching in information
# from the SwissProt/trEMBL for single-chain PDB files
echo -n "Starting FiXPDB : "
date
$PROGS/FixPDBData.pl -dbname=$DB &> $LOGS/FixPDBData.log

# Patch in information from SwissProt/trEMBL for multi-chain PDB files
echo -n "Starting Multi-chains from SwissProt : "
date
$PROGS/MatchSprotData.pl -dbname=$DB    &> $LOGS/MatchSprotData.log

# Vacuum the database
echo -n "Re-analyze database : "
date
psql $DB -c 'vacuum analyze'

# Build the combined SwissProt/trEMBL database if necesary
echo -n "Starting Build FASTA file : "
date
$PROGS/MakeFASTA.pl $SPROT_FASTA $TREMBL_FASTA $SPROT_TREMBL
#make -f $PROGS/testdata/makefile sprottrembl

# Run the brute-force scan on remaining un-assigned sequences
echo -n "Starting Brute Force Scan : "
date
$PROGS/BruteForceScan.pl -dbname=$DB $SPROT_TREMBL &> $LOGS/BruteForceScan.log

# Vacuum the database
echo -n "Re-analyze database : "
date
psql $DB -c 'vacuum analyze'

# Finally create the alignments and dump the results
echo -n "Starting Alignments : "
date
$PROGS/DoAlignments.pl -dbname=$DB       &> $LOGS/DoAlignments.log
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
