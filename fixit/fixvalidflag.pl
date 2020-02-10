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

my @pdbs = ();
my @chains = ();
my @acs = ();
my @valids = ();

# Get the pdb/chain/ac for all entries with the valid flag set to
# false and an apparently OK accession
my $sql = "select pdb, chain, ac from pdbsws where valid = 'f' and ac != '?'";
my $sth = $::dbh->prepare($sql);
if($sth->execute)
{
    while(my @results = $sth->fetchrow_array)
    {
        push @pdbs,   $results[0];
        push @chains, $results[1];
        push @acs,    $results[2];
    }
}
 
# For each entry see if this is actually a valid AC
for(my $i=0; $i<@pdbs; $i++)
{
    $sql = "select count(*) from sprot where ac = '$acs[$i]'";
    my @results = $::dbh->selectrow_array($sql);
    $valids[$i] = $results[0];
}

# Now run through the valid ones and set them to valid
for(my $i=0; $i<@pdbs; $i++)
{
    if($valids[$i])
    {
        print "INFO: Setting valid flag for $pdbs[$i]/$chains[$i]/$acs[$i]\n";
        $sql = "update pdbsws set valid = 't' where pdb = '$pdbs[$i]' and chain = '$chains[$i]' and ac = '$acs[$i]'";
        DoSQL($sql);
    }
    else
    {
        print "INFO: Invalid flag correct for $pdbs[$i]/$chains[$i]/$acs[$i]\n";
    }
}

# Now run through the valid ones and run the alignment program
for(my $i=0; $i<@pdbs; $i++)
{
    if($valids[$i])
    {
        print "INFO: Running alignment for $pdbs[$i]/$chains[$i]\n";
        my $pdbc = $pdbs[$i] . $chains[$i];
        my $exec = "../DoAlignments.pl -pdbc=$pdbc";
        `$exec`;
    }
}

sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
#    print "$sql\n";
}

