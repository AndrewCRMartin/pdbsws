#!/usr/bin/perl
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2004
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   Phone:      +44 (0)171 679 7034
#   EMail:      andrew@bioinf.org.uk
#               martin@biochem.ucl.ac.uk
#   Web:        http://www.bioinf.org.uk/
#               
#               
#*************************************************************************
#
#   This program is not in the public domain, but it may be copied
#   according to the conditions laid out in the accompanying file
#   COPYING.DOC
#
#   The code may be modified as required, but any modifications must be
#   documented so that the person responsible can be identified. If 
#   someone else breaks this code, I don't want to be blamed for code 
#   that does not work! 
#
#   The code may not be sold commercially or included as part of a 
#   commercial product except as described in the file COPYING.DOC.
#
#*************************************************************************
#
#   Description:
#   ============
#
#*************************************************************************
#
#   Usage:
#   ======
#
#*************************************************************************
#
#   Revision History:
#   =================
#
#*************************************************************************
# Packages to use
use ACRMPerlVars;
use CGI;
use DBI;

use strict;

$|=1;

my($pdbdir, $pdbfile, @pdbfiles);

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DNI::errstr" if(!$::dbh);

if(defined($::h))
{
    print STDERR "\nUsage: FixPDBData [-dbname=dbname] [-dbhost=dbhost]\n";
    exit 0;
}


print "INFO: *** REPLACING SWISSPROT ID WITH AC ***\n";
IDtoAC();
print "INFO: *** REMOVING REDUNDANT SWISSPROT IDS ***\n";
RemoveRedundantID();
print "INFO: *** REPLACING DEPRACATED SWISSPROT ACS ***\n";
UpdateAC();
print "INFO: *** VALIDATING REMAINING SWISSPROT ACS ***\n";
ValidateAC();

#*************************************************************************
# Replaces SwissProt IDs by ACs
sub IDtoAC
{
    my($sql, $sth,@results,@ids,$id,$ac,$retval);

    # First grab a list of all the IDs in use

    # Note horrible syntax to match %_% - SQL needs %\\_%
    # but then we have to escape that for Perl
    $sql = "SELECT DISTINCT ac FROM pdbsws WHERE ac LIKE '%\\\\_%'";
    $sth = $::dbh->prepare($sql);
    $retval = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @ids, $results[0];
    }

    # Now work through the IDs and correct them to ACs
    foreach $id (@ids)
    {
        $sql = "SELECT ac FROM idac WHERE id = '$id'";
        ($ac) = $::dbh->selectrow_array($sql);
        if($ac eq "")
        {
            print "WARN: No SwissProt accession known for ID = $id\n";
        }
        else
        {
            print "INFO: Fixing SwissProt ID $id to AC $ac\n";
            $sql = "UPDATE pdbsws SET ac = '$ac', aligned = 'f' WHERE ac = '$id'";
            $retval = $::dbh->do($sql);
        }
    }
}

#*************************************************************************
# Updates depracated ACs
sub UpdateAC
{
    my($sql,$sth,@results,$oldac,%updateac,$retval);
    $sql = "SELECT DISTINCT p.ac, a.ac FROM pdbsws p, acac a WHERE p.ac = a.altac AND p.ac != a.ac";

    $sth = $::dbh->prepare($sql);
    $retval = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        $updateac{$results[0]} = $results[1];
    }

    foreach $oldac (keys %updateac)
    {
        print "INFO: Updating depracated SwissProt AC $oldac to new AC $updateac{$oldac}\n";
        $sql = "UPDATE pdbsws SET ac = '$updateac{$oldac}', aligned = 'f' WHERE ac = '$oldac'";
        $retval = $::dbh->do($sql);
    }
}

#*************************************************************************
sub ValidateAC
{
    my($sql, $retval, $sth, @results);

    # Set all valid flags to TRUE if they are valid primary SProt accessions
    $sql = "UPDATE pdbsws SET valid = 't' WHERE pdbsws.ac = sprot.ac AND pdbsws.valid <> 't'";
    $retval = $::dbh->do($sql);

    # List all invalid ACs (just for verification)
    $sql = "SELECT pdb, chain, ac FROM pdbsws WHERE valid = 'f' AND ac <> '?'";
    $sth = $::dbh->prepare($sql);
    $retval = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        print "WARN: Invalid SwissProt code ($results[2]) in PDB entry $results[0] $results[1]\n";
    }

    # Now set all invalid ACs to a ?
#    $sql = "UPDATE pdbsws SET ac = '?' WHERE valid = 'f' AND ac <> '?'";
#    $retval = $::dbh->do($sql);
}

#*************************************************************************
sub MarkSProtEntries
{
    my($sql, $retval);

    # Set the done flag in pdbac for all entries where the SPROT/PDB mapping
    # has come from the PDB file
    $sql = "UPDATE pdbac SET done = 't' WHERE pdbsws.ac = pdbac.ac AND pdbsws.valid = 't' AND pdbsws.pdb = pdbac.pdb";
    $retval = $::dbh->do($sql);
}

#*************************************************************************
sub TransferFromSprot
{
    my($sql, $retval, $sth, %pdbac, @results, $pdb);

    # Extract list of PDB/AC combinations from Sprot where there is
    # only 1 chain in the protein and it hasn't been set in the PDBSWS
    # table. Build this into a hash
    $sql = "SELECT s.pdb, s.ac FROM pdbac s, nchains n WHERE s.pdb = n.pdb AND s.done = 'f' AND n.count = 1";
    $sth = $::dbh->prepare($sql);
    $retval = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        $pdbac{$results[0]} = $results[1];
    }

    # Now place this information in the PDBSWS table and mark it as done
    # in the PDBAC table
    foreach $pdb (keys %pdbac)
    {
        print "INFO: Obtaining single chain annotation from SwissProt for PDB: $pdb AC: $pdbac{$pdb}\n";
        $sql = "UPDATE pdbsws SET ac = '$pdbac{$pdb}', valid = 't', source = 'sprot', date = 'now', aligned = 'f' WHERE pdb = '$pdb'";
        $retval = $::dbh->do($sql);
        $sql = "UPDATE pdbac SET done = 't' WHERE pdb = '$pdb'";
        $retval = $::dbh->do($sql);
    }
}


#*************************************************************************
sub RemoveErrors
{
    my($sql, $retval,);

    # For any entries where the accession code is actually the PDB code,
    # try to change it to a '?'
    $sql = "UPDATE pdbsws SET ac = '?' WHERE valid = 'f' AND source = 'pdb' AND lower(ac) = lower(pdb)";
    $retval = $::dbh->do($sql);

    # Any entries which did not get corrected in the last stage already
    # have a record in pdbsws with a '?' accession, so we can now
    # remove entries where the PDB code appears in the SwissProt field
    $sql = "DELETE FROM pdbsws WHERE valid = 'f' AND source = 'pdb' AND lower(ac) = lower(pdb)";
    $retval = $::dbh->do($sql);
}


#*************************************************************************
sub RemoveRedundantID
{
    my($sql, $retval, $sth, @results, @pdbs, @chains, @acs, $i);

    @pdbs   = ();
    @chains = ();
    @acs    = ();

    # Remove entries where an ID and an AC have been given as separate entries
    # The UPDATE to replace the ID with the AC will have failed
    $sql = "SELECT p.pdb, p.chain, p.ac FROM pdbsws p, idac i, pdbsws q WHERE p.ac = i.id AND p.valid = 'f' AND i.ac = q.ac AND q.pdb = p.pdb AND q.chain = p.chain AND i.id != i.ac";
    $sth = $::dbh->prepare($sql);
    $retval = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @pdbs,   $results[0];
        push @chains, $results[1];
        push @acs,    $results[2];
    }
    for($i=0; $i<@pdbs; $i++)
    {
        print "INFO: Removing entry $pdbs[$i] chain '$chains[$i]' with invalid AC $acs[$i] where we have a correct AC\n"; 
        $sql = "DELETE FROM pdbsws WHERE pdb = '$pdbs[$i]' AND chain = '$chains[$i]' AND ac = '$acs[$i]' AND valid = 'f'";
        $::dbh->do($sql);
    }
}




