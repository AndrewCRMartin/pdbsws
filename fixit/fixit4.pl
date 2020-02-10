#!/acrm/usr/local/bin/perl

$|=1;

# Skip header
<>;
<>;
$db="pdbsws";
$host="acrm8";
$spt="/acrm/data/tmp/sprottrembl.faa";

while(<>)
{
    chomp;
    @fields = split;
    $pdbc = $fields[0] . $fields[2];
    $pdbc =~ s/\s//g;

    print "Fixing $pdbc....";
    `../BruteForceScan.pl -pdbc=$pdbc -dbname=$db -dbhost=$host $spt`;
    print "done\n";
}
