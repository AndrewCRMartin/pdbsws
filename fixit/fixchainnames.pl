#!/acrm/usr/local/bin/perl -s
use DBI;
use strict;
use warnings;
use ACRMPerlVars;

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Programs
$::getpdbchainlist = $ACRMPerlVars::bindir . "/getchainlist";

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);
 
my @pdbs;
# Get a complete list of PDBs from the pdbsws table
@pdbs = GetPDBs();
#@pdbs = ('104l');

# For each PDB in the pdbsws table
foreach my $pdb (@pdbs)
{
    # Get the list of chains from the PDB file
    my $pdbfile = $::ACRMPerlVars::pdbprep . $pdb . $::ACRMPerlVars::pdbext;
    my $crnfile = $::ACRMPerlVars::pdbprep . "1crn" . $::ACRMPerlVars::pdbext;

    # 10.03.09 Just delete entries where PDB file has gone away
    if((! -e $pdbfile) && (-e $crnfile))
    {
        DeleteEntry($pdb);
        print "INFO: Removing depracated PDB file: $pdb\n";
    }
    else
    {
        my $pdbchainlist = `$::getpdbchainlist $pdbfile`;
        $pdbchainlist =~ s/[\'\n]//g;
        
        # Get the list of chains from the pdbsws table
        my @pschainlist = GetChains($pdb);
        my $missingchains = 0;
        my @badchains = ();
        foreach my $pschain (@pschainlist)
        {
            if(!($pdbchainlist =~ /$pschain/))
            {
                $missingchains++;
                push(@badchains, $pschain);
            }
        }
        if(($missingchains == 1)  &&             # Only one missing chain
           ($badchains[0] eq ' ') &&             # it was a ' ' in PDBSWS
           ($pdbchainlist =~ /A/) &&             # there was an A in the PDB
           (!(join(@pschainlist,'') =~ /A/)))    # and no A in the PDBSWS list
        {
            print "-- Updated $pdb blank chain to chain 'A'\n";
            my $sql;
            $sql = "update pdbsws set chain = 'A' where pdb = '$pdb' and chain = ' '";
            DoSQL($sql);
            $sql = "update alignment set chain = 'A' where pdb = '$pdb' and chain = ' '";
            DoSQL($sql);
        }
        elsif($missingchains)
        {
            DeleteEntry($pdb);
            print "INFO: Removing PDB file for reprocessing: $pdb\n";
        }
    }
}

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

sub GetPDBs
{
    my @pdbs;
    my $sql = "select distinct pdb from pdbsws where ac != 'DNA' and ac != 'ERROR' and ac != 'SHORT'";
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

sub GetChains
{
    my($pdb) = @_;

    my @chains;
    my $sql = "select chain from pdbsws where pdb = '$pdb' and ac != 'DNA' and ac != 'ERROR' and ac != 'SHORT'";
    my $sth = $::dbh->prepare($sql);
    if($sth->execute)
    {
        while(my @results = $sth->fetchrow_array)
        {
            push @chains, "$results[0]";
        }
    }
    return(@chains);
}
