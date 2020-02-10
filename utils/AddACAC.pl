#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   Final brute force scan of remaining unassigned PDB 
#               sequences against SwissProt
#   
#   Copyright:  (c) 1997, UCL
#   Author:     Dr. Andrew C.R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   Phone:      +44 (0)171 419 3890
#   EMail:      martin@biochem.ucl.ac.uk
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
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DBI::errstr" if(!$::dbh);

DoMainProcessing($::sprottrembl);

#*************************************************************************
sub DoMainProcessing
{
    my($fullsprot) = @_;
    my(@acs, $ac, @results);
    my($sql, $sth, $rv);
    
    $sql = "SELECT ac FROM sprot";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @acs, "$results[0]";
    }

    foreach $ac (@acs)
    {
        $sql = "INSERT INTO acac VALUES('$ac', '$ac')";
        $::dbh->do($sql);
    }
    return(0);
}

