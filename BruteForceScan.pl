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

# Grab the name of the Swissprot/trEMBL file
$::sprottrembl = shift(@ARGV);

if(defined($::h) || !defined($::sprottrembl))
{
    print STDERR "\nUsage: BruteForceScan [-pdbc=pdbc] [-dbname=dbname] [-dbhost=dbhost] sprotrembl.faa\n";
    exit 0;
}

# External programs
$::pdb2pir  = "$::ACRMPerlVars::bindir/pdb2pir -f -x";
$::getchain = "$::ACRMPerlVars::bindir/getchain";

# Names for temporary files
$::tmp1 = "/tmp/MSD.$$._temp1.faa";
$::tmp2 = "/tmp/MSD.$$._temp2.faa";

# How many days old a non-exact hit should be before re-scanning it
$::daysold = 30;

if(defined($::pdbc))
{
    ForceScanEntry($::pdbc, $::sprottrembl);
}
else
{
    print "\nINFO: *** Trying to update non-exact hits done > $::daysold days ago ***\n";
    DoNonExactUpdateProcessing($::daysold);
    print "\nINFO: *** Updating hits which didn't match anything on last run ***\n";
    DoUpdateProcessing();
    print "\n\nINFO: *** Main brute-force scan ***\n";
    DoMainProcessing($::sprottrembl);
}

unlink($::tmp1);
unlink($::tmp2);

##########################################################################
#                                                                        #
# Routines for forcing a run                                             #
#                                                                        #
##########################################################################
#*************************************************************************
# Forces scanning of an entry specified on the command line
sub ForceScanEntry
{
    my($pdbc, $fullsprot) = @_;
    my($pdb, $chain);

    $pdb = substr($pdbc, 0, 4);
    $chain = ((length($pdbc) == 5) ? substr($pdbc, 4, 1) : " ");

    print "INFO: Scanning individual entry: $pdb chain '$chain' against $fullsprot\n";

    BuildPDBChainSequenceFile($pdb, $chain, $::tmp1);
    doScan($::tmp1, $pdb, $chain, $fullsprot);
}

##########################################################################
#                                                                        #
# Routines for non-exact updates                                         #
#                                                                        #
##########################################################################
#*************************************************************************
# Main routine for handling non-exact entries. Takes an 'age' in days as
# input. This routine runs an update only on entries which do have a match
# but the match isn't very good. It only does so on entries which haven't
# been checked already in the specified number of days
sub DoNonExactUpdateProcessing
{
    my($age) = @_;
    my(@pdbcs, $pdbc, $pdb, $chain);
    my($sprot, $source, @results, $date);

    $sprot = $::tmp2;

    # Get list of PDB/chain combinations which need processing
    (@pdbcs) = GetPDBChainListNonExact($age);

    if(@pdbcs > 0)
    {
        $date = GetNonExactDate($age);
        print "INFO: Building sequence database of entries dated since $date\n";
        if(BuildSprotFileDate($date, $sprot))
        {
            foreach $pdbc (@pdbcs)
            {
                ($pdb, $chain) = split(/\s+/, $pdbc);

                print "INFO: Updating $pdb chain '$chain'\n";
                BuildPDBChainSequenceFile($pdb, $chain, $::tmp1);
                doScan($::tmp1, $pdb, $chain, $sprot);
            }
        }
        else
        {
            print "INFO: No new entries found\n";
        }
    }
    else
    {
        print "INFO: No PDB chains need updating\n";
    }
}

#*************************************************************************
# Extracts a list of PDBCs for entries which have been processed with
# BruteForceScan at least $age days ago, but which have found non-exact hits
sub GetPDBChainListNonExact
{
    my($age) = @_;
    my($sql, $sth, $rv, @pdbcs);
    my(@results);
    
    $sql = "SELECT pdb, chain FROM pdbsws WHERE valid = 't' AND source = 'brute' AND (identity < 100.0 OR fracoverlap < 0.9) AND date < current_date - integer '$age'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @pdbcs, "$results[0] $results[1]";
    }
    return(@pdbcs);
}

#*************************************************************************
# Gets the oldest date of any entries which have non-exact matches and
# need to be rechecked. This date is used to build the sequence database
sub GetNonExactDate
{
    my($age) = @_;
    my($sql, $date);

    # Get the oldest date for which an update needs to be done
    $sql = "SELECT DISTINCT date FROM pdbsws WHERE valid = 't' AND source = 'brute' AND (identity < 100.0 OR fracoverlap < 0.9) AND date < current_date - integer '$age' ORDER BY date LIMIT 1";
    ($date) = $::dbh->selectrow_array($sql);

    return($date);
}

##########################################################################
#                                                                        #
# Routines for doing updates - previous non-matches                      #
#                                                                        #
##########################################################################
#*************************************************************************
# Main routine to handle re-scanning of entries which previously hit
# nothing.
sub DoUpdateProcessing
{
    my(@pdbcs, $pdbc, $pdb, $chain);
    my($sprot, $source, @results, $date);

    $sprot = $::tmp2;

    # Get list of PDB/chain combinations which need processing
    (@pdbcs) = GetPDBChainListNeedsUpdate();

    if(@pdbcs > 0)
    {
        $date = GetUpdateDate();
        print "INFO: Building sequence database of entries dated since $date\n";

        if(BuildSprotFileDate($date, $sprot))
        {
            foreach $pdbc (@pdbcs)
            {
                ($pdb, $chain) = split(/\s+/, $pdbc);

                print "INFO: Updating $pdb chain '$chain'\n";
                BuildPDBChainSequenceFile($pdb, $chain, $::tmp1);
                doScan($::tmp1, $pdb, $chain, $sprot);
            }
        }
        else
        {
            print "INFO: No new entries found\n";
        }
    }
    else
    {
        print "INFO: No PDB chains need updating\n";
    }
}

#*************************************************************************
# Get a list of chains which have previously been processed but hit
# nothing
sub GetPDBChainListNeedsUpdate
{
    my($sql, $sth, $rv, @pdbcs);
    my(@results);

    
    $sql = "SELECT pdb, chain FROM pdbsws WHERE valid = 'f' AND source = 'brute'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @pdbcs, "$results[0] $results[1]";
    }
    return(@pdbcs);
}

#*************************************************************************
# Get the earliest datestamp on entries which have previously been 
# processed, but hit nothing. This is used to generate the sequence
# database with only newer entries
sub GetUpdateDate
{
    my($sql, $date);

    # Get the oldest date for which an update needs to be done
    $sql = "SELECT DISTINCT date FROM pdbsws WHERE valid = 'f' AND source = 'brute' ORDER BY date LIMIT 1";
    ($date) = $::dbh->selectrow_array($sql);

    return($date);
}

##########################################################################
#                                                                        #
# Routines for processing of new entries                                 #
#                                                                        #
##########################################################################
#*************************************************************************
# This is the main routine to handle new entries which have not yet been
# processed
sub DoMainProcessing
{
    my($fullsprot) = @_;
    my(@pdbcs, $pdbc, $pdb, $chain);
    my($sprot, $source, @results);

    # Get list of PDB/chain combinations which need processing
    (@pdbcs) = GetPDBChainListUnprocessed();

    if(@pdbcs > 0)
    {
        $sprot = $fullsprot;

        foreach $pdbc (@pdbcs)
        {
            ($pdb, $chain) = split(/\s+/, $pdbc);
            
            print "INFO: Processing $pdb chain '$chain' : ";
            BuildPDBChainSequenceFile($pdb, $chain, $::tmp1);
            doScan($::tmp1, $pdb, $chain, $sprot);
        }
    }
    else
    {
        print "INFO: No new PDB chains that need processing\n";
    }
}

#*************************************************************************
# Gets a list of entries which have not previously been scanned. These
# need to be scanned against the full SwissProt/trEMBL database
sub GetPDBChainListUnprocessed
{
    my($sql, $sth, $rv, @pdbcs);
    my(@results);

    
    $sql = "SELECT pdb, chain FROM pdbsws WHERE valid = 'f' AND source != 'brute'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @pdbcs, "$results[0] $results[1]";
    }
    return(@pdbcs);
}

##########################################################################
#                                                                        #
# General routines used by all the above                                 #
#                                                                        #
##########################################################################
#*************************************************************************
# Creates a FASTA format file of SwissProt/trEMBL entries newer than
# specified date
#
sub BuildSprotFileDate
{
    my ($date, $sprotfile) = @_;
    my($sql, $sth, $rv, @results, $count);

    open(FILE, ">$sprotfile") || die "Can't write $sprotfile";
    $sql = "SELECT ac, sequence FROM sprot WHERE date >= '$date'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    $count = 0;
    while(@results = $sth->fetchrow_array)
    {
        print FILE ">$results[0]\n";
        print FILE "$results[1]\n";
        $count++;
    }
    close(FILE);
    return($count);
}

#*************************************************************************
# This is the routine which does the main work of testing a sequence,
# scanning it and storing the results
sub doScan
{
    my($seqfile, $pdb, $chain, $sprot) = @_;
    my($best, $ident, $overlap, $len);

    $len=IsProtein($seqfile);
    if($len >= 10)
    {
        ($best, $ident, $overlap) = BruteFASTA($seqfile, $sprot);
        if((($overlap >= 30) && ($ident >= 90.0)) ||
           (($overlap >= 15) && ($ident >= (100*14/15))) ||
           (($overlap == $len) && ($ident >= 99.9)))
        {
            StoreData($pdb, $chain, $best, $ident, $overlap, $len);
        }
        elsif($ident == -999)
        {
            print "ERROR: FASTA Failed on $pdb chain '$chain' (probably unknown residues or very short chain)\n";
            SetValid($pdb, $chain, "ERROR");
        }
        else
        {
            print "INFO: Best sequence ID for $pdb chain '$chain' was only $ident over $overlap of $len aa ($best)\n";
            SetProcessed($pdb, $chain);
        }
    }
    elsif($len > 0)
    {
        print "INFO: $pdb chain '$chain' too short ($len residues)\n";
        SetValid($pdb, $chain, "SHORT");
    }
    else
    {
        print "INFO: $pdb chain '$chain' identified as DNA/RNA\n";
        SetValid($pdb, $chain, "DNA");
    }

}

#*************************************************************************
# Build a sequence file for a PDB chain
sub BuildPDBChainSequenceFile
{
    my($pdb, $chain, $tmp) = @_;
    my($pdbfile);
    $pdbfile = $ACRMPerlVars::pdbprep . $pdb . $ACRMPerlVars::pdbext;
    $chain = "0" if(($chain eq " ") || ($chain eq ""));
    `$::getchain $chain $pdbfile | $::pdb2pir > $tmp`;
}

#*************************************************************************
# Sets an entry as being valid and processed now. The required AC (which
# may also be one of the special indicators like 'DNA' or 'SHORT') is
# passed into the routine.
sub SetValid
{
    my($pdb, $chain, $ac) = @_;
    my($sql);
    $sql = "UPDATE pdbsws SET ac = '$ac', valid = 't', aligned = 't', source = 'brute', date = 'now' WHERE pdb = '$pdb' AND chain = '$chain'";
    $::dbh->do($sql);
}

#*************************************************************************
# Sets flags to say an entry has been processed, though no hit found
# Thus the 'valid' flag is not set since we don't have a valid accession
sub SetProcessed
{
    my($pdb, $chain) = @_;
    my($sql);
    $sql = "UPDATE pdbsws SET source = 'brute', date = 'now' WHERE pdb = '$pdb' AND chain = '$chain'";
    $::dbh->do($sql);
}

#*************************************************************************
# If it's DNA returns 0, if protein returns the number of aas
sub IsProtein
{
    my($file) = @_;
    my($seq, $seqcp);
    $seq = "";

    open(FILE, $file) || die "Can't read $file";
    while(<FILE>)
    {
        chomp;
        if(!/^>/)
        {
            $seq .= $_;
        }
    }
    close FILE;
    $seqcp = $seq;
    $seqcp =~ s/[atcguATCGU\s]//g;  # Remove ATCGU and white space
    if(!length($seqcp))             # If nothing left, it's DNA
    {
        return(0);
    }
    return(length($seq));
}

#*************************************************************************
# Stores the match in the database, setting the valid flag and date
sub StoreData
{
    my($pdb, $chain, $ac, $ident, $overlap, $len) = @_;
    my($sql, $rv, $fo);

    # If the hit came from SwissProt rather than from trEMBL, it will have
    # and ID rather than an AC, so we convert
    if($ac =~ /[A-Za-z0-9]+\_[A-Za-z0-9]+/)
    {
        my($id) = $ac;
        $sql = "SELECT ac FROM idac WHERE id = '$ac'";
        ($ac) = $::dbh->selectrow_array($sql);
        print "INFO: Scan for $pdb chain '$chain' returned SwissProt ID $id. Found accession $ac\n";
    }

    $fo = $overlap / $len;
    print "INFO: Setting accession for $pdb chain '$chain' to $ac (identity: $ident, overlap: $overlap of $len)\n";
    $sql = "UPDATE pdbsws SET ac = '$ac', valid = 't', source = 'brute', date = 'now', identity = $ident, overlap = $overlap, length = $len, fracoverlap = $fo, aligned = 'f' WHERE pdb = '$pdb' AND chain = '$chain'";
    $::dbh->do($sql);
}

#*************************************************************************
# Runs the actual scan with FASTA
# 12.08.97 Original   By: ACRM
#          Based on Alex Michie's routine
sub BruteFASTA
{
    my($probefile, $sprot) = @_;
    my($ident,$bestident,$id,$bestid,$bestoverlap,$overlap);

    $ident     = -999;
    $bestident = -999;
    $bestid    = "0";

    open(FASTA,"$ACRMPerlVars::fasta -q $probefile $sprot |") || die "Cannot run $ACRMPerlVars::fasta\n";
    
FLOOP:
    while(<FASTA>) 
    {
        if(/^>>(\S+)\s+/)
        {
            $id = $1;
        }

        elsif(/\s+(\S+)%\s+identity\s+in\s+(\S+)\s+aa/)
        {
            $ident = $1;
            $overlap = $2;
            if($ident > $bestident)
            {
                $bestident   = $ident;
                $bestid      = $id;
                $bestoverlap = $overlap;
            }
            elsif(($ident == $bestident) && ($overlap > $bestoverlap))
            {
                $bestident   = $ident;
                $bestid      = $id;
                $bestoverlap = $overlap;
            }
        }
    }
    close(FASTA);

    unlink("/tmp/a.$$");

    return($bestid,$bestident,$bestoverlap);
}

