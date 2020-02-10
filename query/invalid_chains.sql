-- This query finds PDB files which reference a blank chain as
-- well as chain A. Either this is because the DBREF uses 'A' where it
-- should be blank, or both chain names really appear.

select a.pdb 
from   pdbsws a, pdbsws b 
where  a.chain = 'A' 
  and  b.chain = ' '
  and  a.pdb = b.pdb;
