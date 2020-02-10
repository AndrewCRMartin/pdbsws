#!/bin/sh
LOGS=/acrm/data/tmp/pdbsws

trembl=`grep -v Already $LOGS/ProcessTrembl.log | grep -v Updating | wc -l`
sprot=`grep -v Already $LOGS/ProcessSProt.log | grep -v Updating | wc -l`
pdb=`grep Processing $LOGS/ProcessPDB.log | wc -l`
brute=`grep Setting $LOGS/BruteForceScan.log | wc -l`

echo "Processed $trembl new entries from trEMBL"
echo "Processed $sprot new entries from UniProt/KB"
echo "Processed $pdb new entries from PDB"
echo "Found $brute additional mappings through brute-force scan"

