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
@pdbs = qw(1ccz 1fe8 1frt 1i3r 1iea 1igf 1igt 1kj2 1kt2 1ktd 1mco 1mwa 1nc2 1nc4 1nfd 1q55 1q5a 1q5b 1q5c 1qlr 1rzj 1rzk 1tcr 1ypz 1yy9 2fbj 2igf 2nxy 2ny6 2q86 2qsc 2vn4 2vn7 2w59 2xqy 2xsp 2zxe 3a5v 3dsf 3g04 3hdb 3jwd 3jwo 3jxa 3kld 3lrs 3mbe 3mme 3mrw 3mry 3mug 3muh 3n1d 3n2d 3n31 3n3x 3n5d 3nfm 3ngb 3njs 3nx9 3o6n 3pl6 3rpi 3rtq 3sq6 3sq9 3u7w 3u7y 3uji 3vg0 3zyr);

#@pdbs = ('104l');

# For each PDB in the pdbsws table
foreach my $pdb (@pdbs)
{
    my $sql = "DELETE FROM pdbsws WHERE pdb = '$pdb'";
    DoSQL($sql);
    $sql = "DELETE FROM alignment WHERE pdb = '$pdb'";
    DoSQL($sql);
}

sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
    print "$sql\n";
}

