psql pdbsws -c "update pdbsws set ac = 'Q04631' where pdb = '1d8d' and chain = 'A'"
./DoAlignments.pl -pdbc=1d8dA
psql pdbsws -c "update pdbsws set ac = 'Q04631' where pdb = '1d8e' and chain = 'A'"
./DoAlignments.pl -pdbc=1d8eA
