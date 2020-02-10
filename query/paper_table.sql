select source, valid, count(pdb) from pdbsws where ac != 'SHORT' and
ac != 'DNA'  group by source, valid;
