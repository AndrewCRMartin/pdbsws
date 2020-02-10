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

# External programs
$::pdb2pir = "$::ACRMPerlVars::bindir/pdb2pir -x -f";

my($pdbdir, $pdbfile, @pdbfiles);

# Default variables
$::dbname    = "pdbsws" if(!defined($::dbname));
$::dbhost    = $ACRMPerlVars::pghost if(!defined($::dbhost));

# Connect to the database
$::dbh = DBI->connect("dbi:Pg:dbname=$::dbname;host=$::dbhost");
die "Could not connect to database: $DNI::errstr" if(!$::dbh);

if(defined($::h))
{
    print STDERR "\nUsage: MatchSprotData [-dbname=dbname] [-dbhost=dbhost]\n";
    exit 0;
}

# Names for temporary files
$::tmp1 = "/tmp/MSD.$$._temp1.faa";
$::tmp2 = "/tmp/MSD.$$._temp2.faa";
$::tmp3 = "/tmp/MSD.$$._temp3.faa";

DoProcessing();

unlink($::tmp1);
unlink($::tmp2);
unlink($::tmp3);

#*************************************************************************
sub DoProcessing
{
    my(@pdbs, $pdb, @acs, $ac, @chains);
    # Grab the list of PDB files (from SwissProt) and work through them
    @pdbs = GetPDBList();
    foreach $pdb (@pdbs)
    {
        if(-e "${ACRMPerlVars::pdbprep}${pdb}${ACRMPerlVars::pdbext}")
        {
            BuildPDBSequenceFile($pdb, $::tmp1);
            # Get list of SwissProt accessions which match this PDB file
            @acs = GetSwissProtACReferencingPDB($pdb);
            foreach $ac (@acs)
            {
                BuildSProtSequenceFile($ac, $::tmp2);
                @chains = GetBestChains($::tmp1, $::tmp2);
                foreach my $chain (@chains)
                {
                    print "INFO: Mapping expanded from SwissProt for multi-chain PDB entry: $pdb $chain $ac\n";
                    SetDatabaseEntry($pdb, $chain, $ac);
                }
            }
        }
        else
        {
            print "INFO: Skipped obsolete PDB file: $pdb\n";
            SetPDBACUsed($pdb, '');
        }
    }
}

#*************************************************************************
sub SetPDBACUsed
{
    my($pdb, $ac) = @_;
    my($sql, $retval);

    if($ac eq '')
    {
        $sql = "UPDATE pdbac  SET done = 't' WHERE pdb = '$pdb'";
    }
    else
    {
        $sql = "UPDATE pdbac  SET done = 't' WHERE pdb = '$pdb' AND ac = '$ac'";
    }
    $retval = $::dbh->do($sql);
}

#*************************************************************************
sub SetDatabaseEntry
{
    my($pdb, $chain, $ac) = @_;
    my($sql, $retval);

    $sql = "UPDATE pdbsws SET ac = '$ac', valid = 't', aligned = 'f', source = 'sprot', date = 'now' WHERE pdb = '$pdb' AND chain = '$chain'";
    $retval = $::dbh->do($sql);
    SetPDBACUsed($pdb, $ac);
}

#*************************************************************************
sub GetBestChains
{
    my($dbfile, $scanfile) = @_;
    my($insection, @fields, @labels, @scores, @chains, $i);

    `$ACRMPerlVars::ssearch -q -E 1000 $scanfile $dbfile >$::tmp3`;
    open(FILE, $::tmp3) || die "Can't read $::tmp3";
    $insection = 0;
    @chains = ();
    while(<FILE>)
    {
        chomp;
        if($insection)
        {
            s/^\s+//;
            s/\(\s+/\(/;        # Remove spaces after (
            s/\s+\)/\)/;        # Remove spaces before )
            last if(!length);
            if(/^Chain/)
            {
                s/^Chain//;
                (@fields) = split;
                push @labels, $fields[0];
                push @scores, $fields[2];
            }
        }
        elsif(/^The best scores are/)
        {
            $insection = 1;
        }
    }
    if($insection)              # We found some hits!
    {
        for($i=0; $i<@labels; $i++)
        {
            if($scores[$i] == $scores[0])
            {
                push @chains, $labels[$i];
            }
        }
    }
    close FILE;

    return(@chains);
}

#*************************************************************************
sub BuildSProtSequenceFile
{
    my($ac, $tmp) = @_;
    my($sql, $sequence);
    $sql = "SELECT sequence FROM sprot WHERE ac = '$ac'";
    ($sequence) = $::dbh->selectrow_array($sql);

    open(FILE, ">$tmp") || die "Can't write $tmp";
    print FILE ">$ac\n";
    print FILE "$sequence\n";
    close FILE;
}

#*************************************************************************
sub GetSwissProtACReferencingPDB
{
    my($pdb) = @_;

    my($sql, $sth, $rv, @acs);
    my(@results);

    $sql = "SELECT ac FROM pdbac WHERE pdb = '$pdb' AND done = 'f'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @acs, $results[0];
    }
    return(@acs);
}

#*************************************************************************
sub BuildPDBSequenceFile
{
    my($pdb, $tmp) = @_;
    my($pdbfile);
    $pdbfile = $ACRMPerlVars::pdbprep . $pdb . $ACRMPerlVars::pdbext;
    `$::pdb2pir $pdbfile > $tmp`;
}

#*************************************************************************
# Extracts a list of PDB files for which we have cross-refs from 
# SwissProt/trEMBL for which we haven't yet filled in information
# into the main table. These should all be multi-chain files.
sub GetPDBList
{
    my($sql, $sth, $rv, @pdbs);
    my(@results);

    $sql = "SELECT pdb FROM pdbac WHERE done = 'f'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @pdbs, $results[0];
    }
    return(@pdbs);
}
