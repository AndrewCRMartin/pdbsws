#!/acrm/usr/local/bin/perl -s
use strict;
use ACRMPerlVars;
use DBI;

$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

my $delpdb = "$ENV{'HOME'}/pdbcec_new/utils/DeletePDBEntry.pl";
my $processpdb = "$ENV{'HOME'}/pdbcec_new/ProcessPDB.pl -dbname=$::dbname -dbhost=$::dbhost -file";
my $align = "$ENV{'HOME'}/pdbcec_new/DoAlignments.pl -dbname=$::dbname -dbhost=$::dbhost";

# Connect to the database
$::dbh  = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);

my %processedPDBs = ();

while(<>)
{
    chomp;
    if(/\<-\>/)
    {
        my($mapping, $nmatch, $nmismatch) = split;
        $nmismatch *= (-1);
        if(($nmismatch > $nmatch) || ($nmismatch > 200))
        {
            $mapping =~ /(\d...):(.)\<-\>(......)/;
            my($pdb,$chain,$ac) = ($1,$2,$3);
            if(!defined($processedPDBs{$pdb}))
            {
                $processedPDBs{$pdb} = 1;
                print "Redoing: $pdb $chain $ac Match: $nmatch Mismatch: $nmismatch\n";
                `$delpdb $pdb`;
                my $fnm = $ACRMPerlVars::pdbprep . $pdb . $ACRMPerlVars::pdbext;
                `$processpdb $fnm`;

                # Get list of chains for this PDB
                my @chains = GetChainList($pdb);
                foreach my $chain (@chains)
                {
                    print "   Handling chain $chain\n";
                    # Fix the accession code
                    FixAccession($pdb, $chain);

                    # Do alignment for this chain
                    my $pdbc = "$pdb$chain";
                    `$align -pdbc=$pdbc`;
                }
            }
        }
    }
}

sub FixAccession
{
    my($pdb, $chain) = @_;

    my $sql = "SELECT ac FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain'";
    my $sth = $::dbh->prepare($sql);
    my $rv=$sth->execute;
    my @acs;
    my @results;
    while(@results = $sth->fetchrow_array)
    {
        push @acs, $results[0];
    }

    foreach my $ac (@acs)
    {
        $sql = "SELECT ac FROM acac WHERE altac = '$ac'";
        my($newac) = $::dbh->selectrow_array($sql);
        if($ac ne $newac)
        {
            $sql = "UPDATE pdbsws SET ac = '$newac', valid = 't' WHERE pdb = '$pdb' AND chain = '$chain' AND ac = '$ac'";
            $::dbh->do($sql);
        }
    }

}

sub GetChainList
{
    my($pdb) = @_;
    my @chains = ();
    my $sql = "SELECT DISTINCT chain FROM pdbsws WHERE pdb = '$pdb'";
    my $sth = $::dbh->prepare($sql);
    my $rv=$sth->execute;
    my @results;
    while(@results = $sth->fetchrow_array)
    {
        push @chains, $results[0];
    }
    return(@chains);
}
