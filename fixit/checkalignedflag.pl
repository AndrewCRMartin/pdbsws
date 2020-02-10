#!/acrm/usr/local/bin/perl -s
# Reports cases where the aligned flag in pdbsws is set to false
# but there is an entry in the alignment table
use DBI;
use strict;
use warnings;
use ACRMPerlVars;

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);
 
# Get a complete list of aligned PDB/chains from the alignment table
my @pdbcs = GetAlignedPDBCs();
#my @pdbcs = ('2z62A','1blnB');

# For each PDBC in the alignment table
foreach my $pdbc (@pdbcs)
{
    PrintAlignedFlag($pdbc);
}

sub PrintAlignedFlag
{
    my($pdbc) = @_;
    my $pdb = substr($pdbc,0,4);
    my $chain = substr($pdbc,4,1);
    $chain = ' ' if($chain eq '');
    my $sql = "SELECT aligned FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain'";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            if(!$results[0])
            {
                print "$pdb $chain\n";
            }
        }
    }
}

sub GetAlignedPDBCs
{
    my(@pdbcs);
    my $sql = "SELECT DISTINCT pdb, chain FROM alignment";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            push @pdbcs, $results[0] . $results[1];
        }
    }
    return(@pdbcs);
}

