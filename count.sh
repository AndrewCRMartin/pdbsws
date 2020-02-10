#!/bin/sh

trembl=`grep -v Already ProcessTrembl.log | grep -v Updating | wc -l`
sprot=`grep -v Already ProcessSProt.log | grep -v Updating | wc -l`
pdb=`grep Processing ProcessPDB.log | wc -l`
brute=`grep Setting BruteForceScan.log | wc -l`

echo "Processed $trembl new entries from trEMBL"
echo "Processed $sprot new entries from UniProt/KB"
echo "Processed $pdb new entries from PDB"
echo "Found $brute additional mappings through brute-force scan"

