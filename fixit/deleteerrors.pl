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
 
my @pdbs;
# Get a list of PDBs where there is an ERROR for one chain
@pdbs = GetERRORPDBs();
#@pdbs = ('104l');

# For each PDB in the pdbsws table
foreach my $pdb (@pdbs)
{
    $sql = "DELETE FROM pdbsws WHERE pdb = '$pdb'";
    DoSQL($sql);
    $sql = "DELETE FROM alignment WHERE pdb = '$pdb'";
    DoSQL($sql);
}

sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
#    print "$sql\n";
}

sub GetERRORPDBs
{
    my @pdbs;
    my $sql = "select distinct pdb from pdbsws where ac == 'ERROR'";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            push @pdbs, "$results[0]";
        }
    }
    return(@pdbs);
}

