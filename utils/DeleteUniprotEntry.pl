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

# Get the PDB code to delete
my $ac = shift(@ARGV);
$ac = "\U$ac";

# Delete from the pdbsws table
my $sql = "DELETE FROM pdbsws WHERE ac IN (SELECT ac FROM acac WHERE altac = '$ac')";
$::dbh->do($sql);
$sql = "DELETE FROM pdbsws WHERE ac = '$ac'";
$::dbh->do($sql);

# Delete from the alignment table
$sql = "DELETE FROM alignment WHERE ac IN (SELECT ac FROM acac WHERE altac = '$ac')";
$::dbh->do($sql);
$sql = "DELETE FROM alignment WHERE ac = '$ac'";
$::dbh->do($sql);

# Delete from the idac table
$sql = "DELETE FROM idac WHERE ac IN (SELECT ac FROM acac WHERE altac = '$ac')";
$::dbh->do($sql);
$sql = "DELETE FROM idac WHERE ac = '$ac'";
$::dbh->do($sql);

# Delete from the sprot table
$sql = "DELETE FROM sprot WHERE ac IN (SELECT ac FROM acac WHERE altac = '$ac')";
$::dbh->do($sql);
$sql = "DELETE FROM sprot WHERE ac = '$ac'";
$::dbh->do($sql);

# Delete from the acac table
$sql = "DELETE FROM acac WHERE ac = '$ac' OR altac = '$ac'";
$::dbh->do($sql);


