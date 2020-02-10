DELETE FROM pdbsws
WHERE valid = 'f'
AND source = 'pdb'
AND lower(ac) = lower(pdb);
