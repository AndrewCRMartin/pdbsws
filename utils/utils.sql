-- Reset to re-run BruteForceScan.pl
update pdbsws set valid = 'f', source = 'pdbchain' where ac = 'DNA' or ac = 'ERROR';

