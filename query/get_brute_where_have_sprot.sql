-- Get all entries that have been marked as processed by brute, yet
-- there is an entry in the pdbac table which should indicate that the
-- information could have come from SwissProt

-- The reason these exist is that the MatchSprotData.pl script only
-- allows SwissProt entries to match PDB chains for the 'best'
-- matches; others must be filled in by the Brute force scan. Good
-- example is 1ysa/P03069. 1ysa has 4 chains: C and D should match
-- P03069. However, MatchSprotData.pl finds the match with chain C,
-- which has a slightly higher sequence ID than chain D (one residue
-- difference) and therefore ignores the match with chain D.

select distinct p.pdb, p.chain, p.ac
from pdbsws p, pdbac s 
where p.ac != 'DNA' 
  and p.valid = 't' 
  and p.source = 'brute' 
  and p.ac != 'SHORT'
  and p.ac = s.ac
  and p.pdb = s.pdb;

