select distinct c.pdb, c.chain, p.ac 
from chimera c, pdbsws p 
where c.count > 1
and c.pdb = p.pdb
and c.chain = p.chain
order by pdb, chain;
