#!/usr/bin/perl
#*************************************************************************
#
#   Program:    FindMutants.pl
#   File:       
#   
#   Version:    
#   Date:       
#   Function:   Identifies mutants from the final mapping list
#   
#   Copyright:  (c) 2006, UCL
#   Author:     Dr. Andrew C.R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   Phone:      +44 (0)207 679 7034
#   EMail:      andrew@bioinf.org.uk
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
#   V1.0  29.06.06 Original
#
#*************************************************************************
use strict;

$::gReturn = 0;

my($pdbc, $sprot, $count);

Initialize();

print "<mutantmap>\n";
while(($pdbc, $sprot, $count) = ReadPDBMap())
{
    ProcessPDBMap($pdbc, $sprot, $count);
}
print "</mutantmap>\n";

#############################################################################
sub ProcessPDBMap
{
    my ($pdbc, $sprot, $count) = @_;
    my ($i, $insert, $gotprev, $gotpost);
    

    print "   <pdbc id='$pdbc' sprot='$sprot' rescount='$count'>\n";
    $insert = 0;
    $gotprev = 0;
    $gotpost = 0;
    for(my $i=0; $i<$count; $i++)
    {
        if($::gAA[$i] ne $::throne{$::gResnam[$i]})
        {
            if($::gAA[$i] eq "")
            {
                $insert++;
            }
            else
            {
                printf "      <mutation sprot='%s' pdb='%s' pdbnum='%s' sprotnum='%s' />\n",
                       $::gAA[$i], $::throne{$::gResnam[$i]},
                       $::gResnum[$i], $::gSprotnum[$i];
            }
        }
        $gotprev = 1 if(!$insert);
        $gotpost = 1 if($insert);
    }
    if($insert)
    {
        if($gotpost && $gotprev)
        {
            print "      <pdbinserts count='$insert' />\n";
        }
        else
        {
            print "      <pdbunaligned count='$insert' />\n";
        }
    }
    print "   </pdbc>\n";
}

#############################################################################
sub Initialize
{
    %::throne = ( 'ALA' => 'A',
                  'CYS' => 'C',
                  'ASP' => 'D',
                  'GLU' => 'E',
                  'PHE' => 'F',
                  'GLY' => 'G',
                  'HIS' => 'H',
                  'ILE' => 'I',
                  'LYS' => 'K',
                  'LEU' => 'L',
                  'MET' => 'M',
                  'ASN' => 'N',
                  'PRO' => 'P',
                  'GLN' => 'Q',
                  'ARG' => 'R',
                  'SER' => 'S',
                  'THR' => 'T',
                  'VAL' => 'V',
                  'TRP' => 'W',
                  'TYR' => 'Y' );
}

#############################################################################
sub ReadPDBMap
{
    return() if($::gReturn);

    my $sprot_first = "";
    my $pdbc_first  = "";
    my $count = 0;

    # Clear the mapping for a single PDBc
    @::gResnum = ();
    @::gResnam = ();
    @::gAA = ();
    @::gSprotnum = ();

    # If we haven't read anything yet, read the first line. Otherwise
    # we will already have the first line read on the last call
    if(@::gFields[0] eq "")
    {
        $_ = <>;
        chomp;
        @::gFields = split;
    }

    # Save the PDBc and SProt for the first line of a group
    $pdbc_first = $pdbc = "$::gFields[0]$::gFields[1]";
    $sprot_first = $sprot = $::gFields[5];

    # Store the residue number, name and amino acid
    push(@::gResnum,   $::gFields[4]);
    push(@::gResnam,   $::gFields[3]);
    push(@::gAA,       $::gFields[6]);
    push(@::gSprotnum, $::gFields[7]);

    while(<>)
    {
        chomp;
        @::gFields = split;
        $pdbc = "$::gFields[0]$::gFields[1]";
        $sprot = $::gFields[5];
        $count++;
        
        if(($pdbc ne $pdbc_first) || 
           (($sprot ne $sprot_first) && 
            ($sprot ne "") &&
            ($sprot_first ne "")))
        {
            return($pdbc_first, $sprot_first, $count);
        }
        if(($sprot ne "") && ($sprot_first eq ""))
        {
            $sprot_first = $sprot;
        }

        # Store the residue number, name and amino acid
        push(@::gResnum,   $::gFields[4]);
        push(@::gResnam,   $::gFields[3]);
        push(@::gAA,       $::gFields[6]);
        push(@::gSprotnum, $::gFields[7]);
    }
    $::gReturn = 1;
    return($pdbc_first, $sprot_first, $count);
}
