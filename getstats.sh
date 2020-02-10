#!/bin/bash

echo -n "Total PDB chains in PDBSWS: "
psql -tqc "select count(*) from pdbsws" pdbsws

echo -n "  of which, number of short peptides: "
psql -tqc "select count(*) from pdbsws where ac = 'SHORT'" pdbsws

echo -n "  and, number of DNA/RNA chains: "
psql -tqc "select count(*) from pdbsws where ac = 'DNA'" pdbsws

echo -n "Cross-links obtained from the PDB: "
psql -tqc "select count(*) from pdbsws where ac not in ('?', 'SHORT', 'DNA') and source like 'pdb%'" pdbsws

echo -n "Cross-links obtained from SwissProt: "
psql -tqc "select count(*) from pdbsws where ac not in ('?', 'SHORT', 'DNA') and source = 'sprot'" pdbsws

echo -n "Cross-links obtained from Brute-force scan: "
psql -tqc "select count(*) from pdbsws where ac not in ('?', 'SHORT', 'DNA') and source = 'brute'" pdbsws

echo -n "Number of unmatched chains: "
psql -tqc "select count(*) from pdbsws where ac = '?'" pdbsws

