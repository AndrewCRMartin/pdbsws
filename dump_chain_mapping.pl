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
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2006
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

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh  = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);

DoProcessing();

#*************************************************************************
sub DoProcessing
{
    my($sql, $sth, $rv, @results);
    my($sth2, @results2);
    my($pdb, $chain, $pdbcount, $resnam, $resid, $ac, $swsaa, $swscount);

    $sql = "SELECT DISTINCT pdb, chain, ac FROM pdbsws WHERE ac != 'ERROR' AND ac != 'DNA' AND ac != 'SHORT' ORDER BY pdb, chain, ac";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        $pdb      = $results[0];
        $chain    = substr($results[1], 0, 1);
        $ac       = $results[2];

        printf "%4s %1s %6s\n", $pdb, $chain, $ac;
    }
}

