#!/acrm/usr/local/bin/perl

while(<>)
{
    chomp;
    print "DELETE FROM pdbsws WHERE pdb = '$_';\n";
    print "DELETE FROM alignment WHERE pdb = '$_';\n";
}

