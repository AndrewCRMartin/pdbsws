#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   Rewrites all IDAC entries
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2007
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
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
#   This is designed to be run only to patch in correct IDAC entries.
#   A bug in ProcessSProt.pl meant that IDAC was not being fixed after
#   a sequence was updated. This patches in those fixes.
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

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DNI::errstr" if(!$::dbh);

ProcessSwissProt();

#######################################################################
sub StoreEntry
{
    my($id, $date, $seq, $acs_p, $pdbs_p) = @_;
    my($i, $sql, $olddate, $retval, $oldseq);

    # See if this entry is already in the database
    $sql = "SELECT date, sequence FROM sprot WHERE ac = '$$acs_p[0]'";
    ($olddate, $oldseq) = $::dbh->selectrow_array($sql);

    # If the entry was found
    if($olddate ne "")
    {
        # Delete this ID from the IDAC table (in case it exists and the
        # old AC isn't listed in the Sprot Entry)
        $sql = "DELETE FROM idac WHERE id = '$id'";
        print "$sql\n";
        $retval = $::dbh->do($sql);
        # Store the idac entry
        $sql = "INSERT INTO idac VALUES ('$id', '$$acs_p[0]')";
        print "$sql\n";
        $retval = $::dbh->do($sql);
    }
}

#######################################################################
sub ProcessSwissProt
{
    my($id, $date, $seq, @acs, @fields, @pdbs);
    while(<>)
    {
        chomp;
        if(/^\/\//)            # End of entry
        {
            $seq =~ s/\s//g;
            StoreEntry($id, $date, $seq, \@acs, \@pdbs) if($id ne "");
            $id  = "";
            @acs  = ();
            @pdbs = ();
            $date = "";
            $seq  = "";
        }
        if(/^ID /)
        {
            @fields = split;
            $id = $fields[1];
        }
        elsif(/^AC /)
        {
            s/\;/ /g;           # Remove semi-colons
            s/\s+/ /g;          # Condense white-space
            @fields = split;    # Grab the accessions
            shift @fields;
            push @acs, @fields;
        }
        elsif(/^DT /)
        {
            @fields = split;    # Store the final date record
            $date = $fields[1];
            #+++ 06.03.07 A comma seems to have crept onto end of date
            $date =~ s/\,//g;
            #END
        }
        elsif(/^DR /)
        {
            s/\;/ /g;           # Remove semi-colons
            s/\s+/ /g;          # Condense white-space
            tr/A-Z/a-z/;        # Down-case
            @fields = split;
            if($fields[1] eq "pdb")
            {
                push @pdbs, $fields[2];
            }
        }
        elsif(/^   /)
        {
            $seq .= $_;
        }
    }
}
