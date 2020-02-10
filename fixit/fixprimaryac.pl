#!/acrm/usr/local/bin/perl
# The problem comes from entries that move from trEMBL to SwissProt.
# Somehow what used to be a primary accession doesn't get removed
# This script removes these entries and updates any pdbsws table
# entries so they will be aligned on the next run.
#
use strict;
use warnings;
use ACRMPerlVars;
use DBI;
$|=1;
                                                                                
# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));
 
# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DNI::errstr" if(!$::dbh);
 
my @acs;
while(<>)
{
    if(/^ID /)
    {
        @acs = ();
    }
    elsif(/^AC /)
    {
        chomp;

        s/\;//g;                # Remove semi-colons
        s/\s+/ /g;              # Condense white-space
        my @fields = split;     # Split into an array
        shift @fields;          # Drop the "AC " key
        push @acs, @fields;     # Join into our complete array
    }
    elsif(/\/\//)               # End of record
    {
        my $primary = shift @acs;

        foreach my $secondary (@acs)
        {
            my $sql;
            print "\nChecking $secondary...\n";

            $sql = "SELECT count(*) FROM acac WHERE ac = '$secondary' AND altac = '$secondary'";
            if(GetOneRowSQL($sql))
            {
                $sql = "DELETE FROM acac WHERE ac = '$secondary' AND altac = '$secondary'";
                print "\nRemoving acac entry for secondary mapped to itself: $secondary/$secondary\n";
                DoSQL($sql);
            }

            # Now look to see if a secondary AC appears in the pdbsws table
            $sql = "SELECT count(*) FROM pdbsws WHERE ac = '$secondary'";
            if(GetOneRowSQL($sql))     # Found one
            {
                # Find the primary accession
                $sql = "SELECT ac FROM acac WHERE altac = '$secondary'";
                my($primary) = GetOneRowSQL($sql);
                # Set this in the pdbsws table
                print "Correcting pdbsws entry from secondary ac $secondary to primary ac $primary\n";
                $sql = "UPDATE pdbsws SET ac = '$primary', aligned = 'f' WHERE ac = '$secondary'";
                DoSQL($sql);
            }

            # Now delete any remaining acac entries where this secondary is listed as primary
            if(GetOneRowSQL("SELECT count(*) FROM acac WHERE ac = '$secondary'"))
            {
                print "Removing acac entries for secondary ac used as primary: $secondary\n";
                $sql = "DELETE FROM acac WHERE ac = '$secondary';";
                DoSQL($sql);
            }

            # delete any idac entries where this secondary is listed as primary
            if(GetOneRowSQL("SELECT count(*) FROM idac WHERE ac = '$secondary'"))
            {
                print "Removing idac entries for secondary ac used as primary: $secondary\n";
                $sql = "DELETE FROM idac WHERE ac = '$secondary';";
                DoSQL($sql);
            }

            # delete any sprot entries where this secondary is listed as primary
            if(GetOneRowSQL("SELECT count(*) FROM sprot WHERE ac = '$secondary'"))
            {
                print "Removing sprot entries for secondary ac used as primary: $secondary\n";
                $sql = "DELETE FROM sprot WHERE ac = '$secondary';";
                DoSQL($sql);
            }

            # delete any alignment entries where this secondary is listed as primary
            if(GetOneRowSQL("SELECT count(*) FROM alignment WHERE ac = '$secondary'"))
            {
                print "Removing alignment entries for secondary ac used as primary: $secondary\n";
                $sql = "DELETE FROM alignment WHERE ac = '$secondary';";
                DoSQL($sql);
            }
        }
    }
}

sub GetOneRowSQL
{
    my($sql) = @_;
    my($result) = $::dbh->selectrow_array($sql);
    return($result);
}

        
sub DoSQL
{
    my($sql) = @_;
    $::dbh->do($sql);
#    print "$sql\n";
}
