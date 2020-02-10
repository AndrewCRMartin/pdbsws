#!/acrm/usr/local/bin/perl -s
use DBI;
use strict;
use warnings;
use ACRMPerlVars;

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Programs
$::chaintype = $ACRMPerlVars::bindir . "/chaintype";

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);
 
my %redolist = ();

# Get a list of PDBCs marked as DNA
my @pdbcs = GetDNAPDBCs();

# For each PDB in the pdbsws table
my $count = 0;
foreach my $pdbc (@pdbcs)
{
    my $pdb   = substr($pdbc, 0, 4);
    my $chain = substr($pdbc, 4, 1);

    my $pdbfile = $ACRMPerlVars::pdbprep . $pdb . $ACRMPerlVars::pdbext;
    my $crnfile = $::ACRMPerlVars::pdbprep . "1crn" . $::ACRMPerlVars::pdbext;

    if((! -e $pdbfile) && (-e $crnfile))
    {
        # Just delete entries where PDB file has gone away
        DeleteEntry($pdb);
    }
    else
    {
        if($chain ne " ")
        {
            # Now check if this chain is really DNA/RNA
            my $result = `$::chaintype -c $chain $pdbfile`;
            if(($result =~ /PROTEIN/) || ($result =~ /HYBRID/))
            {
                # It was really protein, so the file needs to be re-done
                print "INFO: Identified chain marked as DNA/RNA which is PROTEIN/HYBRID: $pdbc\n";
                $redolist{$pdb} = 1;
                $count++;
            }
        }
    }
}

print "INFO: A total of $count chains have been identified for reprocessing\n";

$count = 0;
foreach my $key (keys %redolist)
{
    DeleteEntry($key);
    $count++;
}
print "INFO: A total of $count PDB files have been removed from the database for reprocessing\n";

###################################################################################
sub DeleteEntry
{
    my($pdb) = @_;
    my $sql;
    $sql = "DELETE FROM pdbsws WHERE pdb = '$pdb'";
    DoSQL($sql);
    $sql = "DELETE FROM alignment WHERE pdb = '$pdb'";
    DoSQL($sql);
    $sql = "DELETE FROM pdbac WHERE pdb = '$pdb'";
    DoSQL($sql);
}

sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
#    print "$sql\n";
}

sub GetDNAPDBCs
{
    my @pdbs;
    my $sql = "select pdb, chain from pdbsws where ac = 'DNA'";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            push @pdbs, $results[0].$results[1];
        }
    }
    return(@pdbs);
}

