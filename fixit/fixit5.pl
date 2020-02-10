#!/acrm/usr/local/bin/perl -s
use DBI;
use strict;
use warnings;
use ACRMPerlVars;

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));
$::daysold   = 150 if(!defined($::daysold));
$::sprot     = "/acrm/data/tmp/sprottrembl.faa" if(!defined($::sprot));

$::bfs       = "/home/bsm/martin/pdbcec_new/BruteForceScan.pl";
$::align     = "/home/bsm/martin/pdbcec_new/DoAlignments.pl";

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);
 
my @pdbcs;
# Get a list of PDBCs where the ac==DNA and valid==t and source==brute
@pdbcs = GetChainList();
foreach my $pdbc (@pdbcs)
{
    print "Re-running $pdbc\n";
    ResetValues($pdbc);
    `$::bfs -pdbc=$pdbc -dbname=$::dbname -daysold=$::daysold $::sprot`;
    `$::align -pdbc=$pdbc -dbname=$::dbname`
}

sub ResetValues
{
    my($pdbc) = @_;

    my $pdb   = substr($pdbc, 0, 4);
    my $chain = substr($pdbc, 4, 1);
    my $sql;

    $sql = "update pdbsws set ac = '?', aligned = 'f', identity = 0, overlap = 0, length = 0, fracoverlap = 0 where pdb = '$pdb' and chain = '$chain'";
    DoSQL($sql);
}

sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
}

sub GetChainList
{
    my @pdbcs;
    my $sql = "select pdb, chain from pdbsws where ac = 'DNA' and valid = 't' and source = 'brute'";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            push @pdbcs, "$results[0]\U$results[1]";
        }
    }
    return(@pdbcs);
}
