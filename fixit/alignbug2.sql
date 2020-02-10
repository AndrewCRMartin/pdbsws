select pdb, chain from pdbsws p
where p.ac != '' and p.valid = 't' and p.aligned = 't'
and (select count(*) from alignment a where a.pdb = p.pdb and a.chain = p.chain) = 0;
