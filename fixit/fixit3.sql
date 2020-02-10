select a.pdb, a.chain, a.ac, count(a.swscount)
from pdbsws p, alignment a
where p.pdb = a.pdb
and p.chain = a.chain
and p.aligned = 't'
and p.ac = 'DNA'
group by a.pdb, a.chain, a.ac;

