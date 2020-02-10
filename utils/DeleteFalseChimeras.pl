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
    my($sql, $sth, $rv, $pdb, $chain, $seq, $count, $minstart);

    $sql = "SELECT pdb, chain FROM ndbref WHERE count > 1";
    $sth = $::dbh2->prepare($sql);
    $rv = $sth->execute;
    while(($pdb, $chain) = $sth->fetchrow_array)
    {
        $sql   = "SELECT count FROM chimera WHERE pdb = '$pdb' and chain = '$chain'";
        ($count) = $::dbh->selectrow_array($sql);
        if($count == 1)
        {
            print "INFO: Resetting false chimera $pdb chain '$chain'\n";
            # Find minimum start for this pdb/chain 
            # NOTE! This works properly even though 'start' is char(5) not int
            # Actually it doesn't matter - we just want one record
            $sql = "SELECT MIN(start) FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain'";
            ($minstart) = $::dbh->selectrow_array($sql);
            # Delete all other records for this pdb/chain
            $sql = "DELETE FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain' AND start != '$minstart'";
            $::dbh->do($sql);
            # Finally fix the start/stop range to be '?' so we align the whole thing
            $sql = "UPDATE pdbsws SET start = '?', stop = '?' WHERE pdb = '$pdb' AND chain = '$chain'";
            $::dbh->do($sql);
        }
    }
}

