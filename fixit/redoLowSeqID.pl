#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2012
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      andrew@bioinf.org.uk
#               andrew.martin@ucl.ac.uk
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

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh  = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);

while(<>)
{
    chomp;
    my($pdb, $chain) = split;

    my $sql = "SELECT source FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain'";
    my ($source) = $::dbh->selectrow_array($sql);

    # If mapping hasn't come from the PDB file
    if($source ne "pdb")
    {
        # Delete entries for all chains of the PDB file in pdbsws
        $sql = "DELETE FROM pdbsws WHERE pdb = '$pdb'";
        print "$sql\n";
        $::dbh->do($sql);

        # Delete entries from alignment
        $sql = "DELETE FROM alignment WHERE pdb = '$pdb'";
        print "$sql\n";
        $::dbh->do($sql);
    }
    else
    {
        print "Mapping from PDB skipped: $pdb.$chain\n";
    }
}

