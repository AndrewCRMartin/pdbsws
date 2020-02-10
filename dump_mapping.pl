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

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh  = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);
$::dbh2 = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh2);

DoProcessing();

#*************************************************************************
sub DoProcessing
{
    my($sql, $sth, $rv, @results);
    my($sth2, @results2);
    my($pdb, $chain, $pdbcount, $resnam, $resid, $ac, $swsaa, $swscount);

    $sql = "SELECT DISTINCT pdb, chain FROM pdbsws WHERE aligned = 't' AND ac != 'ERROR' AND ac != 'DNA' AND ac != 'SHORT' ORDER BY pdb, chain";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        $pdb      = $results[0];
        $chain    = substr($results[1], 0, 1);

        $sql = "SELECT pdbcount, resnam, resid, ac, swsaa, swscount FROM alignment WHERE pdb = '$pdb' AND chain = '$chain' ORDER BY pdbcount";
        $sth2 = $::dbh2->prepare($sql);
        $rv = $sth2->execute;
        while(@results2 = $sth2->fetchrow_array)
        {
            $pdbcount = $results2[0];
            $resnam   = $results2[1];
            $resid    = $results2[2];
            $ac       = $results2[3];
            $swsaa    = substr($results2[4], 0, 1);
            $swscount = $results2[5];

            # Remove spaces
            $pdb    =~ s/\s//g;
            $resnam =~ s/\s//g;
            $resid  =~ s/\s//g;
            $ac     =~ s/\s//g;

            $chain = "@" if (($chain eq "") || ($chain eq " "));

            if($swscount == 0)
            {
                printf "%4s %1s    %5d %-4s%-6s                      \n",
                       $pdb, $chain, $pdbcount, $resnam, $resid;
            }
            else
            {
                printf "%4s %1s    %5d %-4s%-6s %6s    %1s     %5d\n",
                       $pdb, $chain, 
                       $pdbcount, $resnam, $resid,
                       $ac, $swsaa, $swscount;
            }
        }
    }
}

