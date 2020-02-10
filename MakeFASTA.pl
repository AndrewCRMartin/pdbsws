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
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2005
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
use strict;

UsageDie() if(defined($::h));

my($sprot, $trembl, $sprottrembl, @stats, $sprottime, $trembltime, $sprottrembltime);

$sprot = shift(@ARGV);
$trembl = shift(@ARGV);
$sprottrembl = shift(@ARGV);

@stats = stat $sprot;
$sprottime = $stats[9];

@stats = stat $trembl;
$trembltime = $stats[9];

@stats = stat $sprottrembl;
$sprottrembltime = $stats[9];

if(($sprottime > $sprottrembltime) || ($trembltime > $sprottrembltime))
{
    `cat $sprot $trembl > $sprottrembl`;
}

#*************************************************************************
sub UsageDie
{
    print <<__EOF;

MakeFASTA.pl V1.0 (c) Dr. Andrew C.R. Martin, UCL, 2005
Usage: MakeFASTA.pl sprot_file trembl_file sprot_trembl_file

Concatenates sprot_file trembl_file into sprot_trembl_file if either
file has changed since sprot_trembl_file was last modified

__EOF
   exit 0;
}
