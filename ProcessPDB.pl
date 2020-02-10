#!/usr/bin/perl -s
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    V1.3
#   Date:       15.09.05
#   Function:   Build database table of SwissProt info from the PDB
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 1997-2005
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
#   EMail:      martin@biochem.ucl.ac.uk
#               andrew@bioinf.org.uk
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
#   Builds a DBM hash for all chains in the PDB. Each key is of the
#   form xxxxc where xxxx is the PDB code and c the (optional) chain name
#   The header of PDB file is scanned to look for chain-specific SwissProt
#   codes and these are inserted into the hash if found. Otherwise the
#   value is set to 0 to represent "unknown"
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
#   V1.0  12.08.97 Original
#   V1.1  12.09.97 Uses DBREF records in preference to REMARK 999 if found
#   V1.2  17.08.98 Commented out the special case code for single chain
#                  entries. This caused PDB files with a single chain,
#                  but WITH a chain label, to break.
#   V1.3  15.09.05 Database version
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
    print STDERR <<__EOF;

Usage: ProcessPDBEntry [-dbname=dbname] [-dbhost=dbhost] [-file] pdb

If -file is specified then the parameter is a specific file name rather than the
PDB directory

__EOF
    exit 0;
}

$pdbdir = shift(@ARGV);
$pdbfile = $pdbdir if(defined($::file));

if($::file)
{
    ProcessPDBFile($pdbfile);
}
else
{
    # Get a list of files in the PDB
    opendir(DIRHANDLE, $pdbdir) || die "Can't open directory $pdbdir";
    @pdbfiles = readdir(DIRHANDLE);
    closedir(DIRHANDLE);

    # For each PDB file
    foreach $pdbfile (@pdbfiles)
    {
        chomp($pdbfile);
        ProcessPDBFile("$pdbdir/$pdbfile");
    }
}

#*************************************************************************
sub ProcessPDBFile
{
    my($pdbfile) = @_;

    my($pdb,$chain,$sql);

    # Extract the PDB code by removing the extension and then keeping the
    # last 4 characters
    $pdb = $pdbfile;
    $pdb =~ tr/A-Z/a-z/;        # Down-case
    if(($pdb =~ /\./) && !($pdb =~ /\.noc$/))
    {
        chop $pdb while(substr($pdb,length($pdb)-1,1) ne ".");
        chop $pdb;

        $pdb = substr($pdb,length($pdb)-4);
        if(substr($pdb,0,1) =~ /\d/)
        {
            $sql = "SELECT chain FROM pdbsws WHERE pdb = '$pdb'";
            ($chain) = $::dbh->selectrow_array($sql);
            if($chain eq "")
            {
                print "INFO: Processing $pdb\n";
                ProcessFile($pdbfile, $pdb);
            }
            else
            {
                print "INFO: Entry exists for $pdb\n";
            }
        }
    }
}

#*************************************************************************
sub ProcessFile
{
    my($pdbfile, $pdb) = @_;
    my(@contents,%ChainHash,@chains,$nchains,$ch,$line,$NoDBREF,$sql);
    my($retval,$chain,$word2,@words,$word,$word3,$ac,$start,$stop);

    $NoDBREF = 1;

    if(!open(PDBFILE, $pdbfile))
    {
        warn "Can't read $pdbfile\n";
        return;
    }

    # Read in our PDB file
    @contents = <PDBFILE>;
    close PDBFILE;

    # Determine what chain names we have
    foreach $_ (@contents)
    {
        $NoDBREF = 0 if(/^DBREF /);

        if(/^ATOM/)
        {
            $ChainHash{substr($_,21,1)} = 1;
        }
    }
    # Convert our hash into a simple array of chain names
    $nchains = 0;
    foreach $ch (keys %ChainHash)
    {
        $chains[$nchains++] = $ch;
    }

    # Set values to ? (unknown)
    foreach $chain (@chains)
    {
        $sql = "INSERT INTO pdbsws VALUES ('$pdb', '$chain', '?', 'f', 'pdbchain', 'now', 'f', 0, 0, 0, 0, '?', '?')";
        $retval = $::dbh->do($sql);
    }

    # Run through the header looking for DBREF or REMARK 999 sequence information
    foreach $_ (@contents)
    {
        last if(/^ATOM  /);
        if(/^DBREF /)
        {
            # Allow UNP as well as SWS - 1uw5 does this
            if((substr($_,26,5) eq "SWS  ") ||
               (substr($_,26,5) eq "UNP  "))
            {
                $chain = substr($_,12,1);
                $start = substr($_,14,5);
                $stop  = substr($_,20,5);
                $start =~ s/\s//g;
                $stop  =~ s/\s//g;

                # Extract the first cross-reference
                $word2 = substr($_,33,8);
                $word2 =~ s/ //g;
                # If the first cross-reference isn't a SwissProt AC
                if(!($word2 =~ /^[OPQ]\d[A-Z0-9][A-Z0-9][A-Z0-9]\d/))
                {
                    # Get the second cross-reference
                    $word3 = substr($_,42,12);
                    $word3 =~ s/ //g;
                    # Use this instead if it is a SwissProt AC
                    if($word3 =~ /^[OPQ]\d[A-Z0-9][A-Z0-9][A-Z0-9]\d/)
                    {
                        $word2 = $word3;
                    }
                    else
                    {
                        # If cross-ref-1 was not a SwissProt ID and cross-ref-2 was
                        # then use this. Handles 1qd9
                        if(!($word2 =~ /.+_.+/) && ($word3 =~ /.+_.+/))
                        {
                            $word2 = $word3;
                        }
                    }
                }

                # Check to see if we already have an AC for this chain
                $sql = "SELECT ac FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain'";
                ($ac) = $::dbh->selectrow_array($sql);
                if(substr($ac,0,1) eq "?")
                {
                    # We don't have an AC so we update it
                    $sql = "UPDATE pdbsws SET ac = '$word2', source = 'pdb', date = 'now', start = '$start', stop = '$stop' WHERE pdb = '$pdb' AND chain = '$chain'";
                }
                else
                {
                    # We already have an AC so we add an extra line - this is a chimera
                    $sql = "INSERT INTO pdbsws VALUES ('$pdb', '$chain', '$word2', 'f', 'pdb', 'now', 'f', 0, 0, 0, 0, '$start', '$stop')";
                }
                $retval = $::dbh->do($sql);
            }
        }
        elsif($NoDBREF && /^REMARK 999/)
        {
            s/REMARK 999//;
            s/$pdb//;
            s/[\"\(\)]//g;
            # Split line into separate words
            @words = split;

            # Run through the words on this line
      WORD: foreach $word (@words)
            {
                # Run through the chain names
                foreach $chain (@chains)
                {
                    # If we have a match we appear to have found info for a chain
                    # This should still work OK for blank chain name since
                    # we will match a space somewhere in the string
                    if($chain eq $word)
                    {
                        foreach $word2 (@words)
                        {
                            if((($word2 =~ /_/) && 
                                (length($word2) <= 10) &&
                                (substr($word2,length($word2)-1,1) ne ":")) || 
                               ($word2 =~ /^[a-zA-Z]\d\d\d\d\d$/))
                            {
                                $sql = "UPDATE pdbsws SET ac = '$word2', source = 'pdb', date = 'now' WHERE pdb = '$pdb' AND chain = '$chain'";
                                $retval = $::dbh->do($sql);
                                last;
                            }
                        }
                        last WORD;
                    }
                }
            }
        }
    }

    undef @contents;
}
