#!/acrm/usr/local/bin/perl -s
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
my %pdbcs_aligned = GetAlignedPDBCs();
#my %pdbcs_aligned; $pdbcs_aligned{'2vozA'} = 0;

my @pdbcs_pdbsws = GetPdbswsPDBCs();
#my @pdbcs_pdbsws; $pdbcs_pdbsws[0] = '2vozA';

# For each PDBC in the pdbsws table
foreach my $pdbc (@pdbcs_pdbsws)
{
    if(!$pdbcs_aligned{$pdbc})
    {
        ClearAlignedFlag($pdbc);
    }
}

sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
#    print "$sql\n";
}

sub ClearAlignedFlag
{
    my($pdbc) = @_;
    my $pdb = substr($pdbc,0,4);
    my $chain = substr($pdbc,4,1);
    $chain = ' ' if($chain eq '');
    my $sql = "UPDATE pdbsws SET aligned = 'f' WHERE pdb = '$pdb' AND chain = '$chain'";
    DoSQL($sql);
}

sub GetAlignedPDBCs
{
    my(%pdbcs);
    my $sql = "SELECT DISTINCT pdb, chain FROM alignment";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            my $pdbc = $results[0] . $results[1];
            $pdbcs{$pdbc} = 1;
        }
    }
    return(%pdbcs);
}

sub GetPdbswsPDBCs
{
    my(@pdbcs);
    my $sql = "SELECT DISTINCT pdb, chain FROM pdbsws";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            my $pdbc = $results[0] . $results[1];
            push @pdbcs, $pdbc;
        }
    }
    return(@pdbcs);
}

