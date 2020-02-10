#!/usr/bin/perl -s

# RE-DO the ERROR entries now that we use -x with pdb2pir

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

if(defined($::pdbc))
{
    ForceScanEntry($::pdbc, $::sprottrembl);
}
else
{
    print "\n\nINFO: *** Main brute-force scan ***\n";
    DoMainProcessing($::sprottrembl);
}

unlink($::tmp1);
unlink($::tmp2);

#*************************************************************************
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

#*************************************************************************
sub DoMainProcessing
{
    my($fullsprot) = @_;
    my(@pdbcs, $pdbc, $pdb, $chain, $GotSeqs);
    my($sprot, $source, @results);

    # Get list of PDB/chain combinations which need processing
    (@pdbcs) = GetPDBChainList();

    foreach $pdbc (@pdbcs)
    {
        ($pdb, $chain) = split(/\s+/, $pdbc);

        print "INFO: Processing $pdb chain '$chain' : ";

        print "scanning against full SwissProt/TrEMBL\n";
        $sprot = $fullsprot;
        BuildPDBChainSequenceFile($pdb, $chain, $::tmp1);

        doScan($::tmp1, $pdb, $chain, $sprot);
    }
}

#*************************************************************************
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
            print "ERROR: FASTA Failed on $pdb chain '$chain' (probably unknown residue types)\n";
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
        print "INFO: $pdb chain '$chain' identified as DNA\n";
        SetValid($pdb, $chain, "DNA");
    }

}

#*************************************************************************
sub NeedsUpdate
{
    my($pdb, $chain) = @_;
    my($sql, $source);

    $sql = "SELECT source FROM pdbsws WHERE pdb = '$pdb' AND chain = '$chain'";
    ($source) = $::dbh->selectrow_array($sql);
    if($source =~ /brute/)
    {
        return(1);
    }
    return(0);
}

#*************************************************************************
# Creates a FASTA format file of SwissProt/trEMBL entries newer than
# the date stored in PDBSWS for $pdb/$chain
#
sub BuildSprotFile
{
    my ($pdb, $chain, $sprotfile) = @_;
    my($sql, $sth, $rv, @results, $count);

    open(FILE, ">$sprotfile") || die "Can't write $sprotfile";
    $sql = "SELECT s.ac, s.sequence FROM sprot s, pdbsws p WHERE p.pdb = '$pdb' AND p.chain = '$chain' AND s.date > p.date";
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
sub SetValid
{
    my($pdb, $chain, $ac) = @_;
    my($sql);
    $sql = "UPDATE pdbsws SET ac = '$ac', valid = 't', source = 'brute', date = 'now' WHERE pdb = '$pdb' AND chain = '$chain'";
    $::dbh->do($sql);
}

#*************************************************************************
# Sets flags to say an entry has been processed, though no hit found
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
    $seqcp =~ s/[atcguATCGU\s]//g;  # Remove ATCG and white space
    if(!length($seqcp))           # If nothing left, it's DNA
    {
        return(0);
    }
    return(length($seq));
}

#*************************************************************************
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
sub GetPDBChainList
{
    my($sql, $sth, $rv, @pdbcs);
    my(@results);

    
    $sql = "SELECT pdb, chain FROM pdbsws WHERE valid = 't' AND ac = 'ERROR'";
    $sth = $::dbh->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        push @pdbcs, "$results[0] $results[1]";
    }
    return(@pdbcs);
}

#*************************************************************************
sub BuildPDBChainSequenceFile
{
    my($pdb, $chain, $tmp) = @_;
    my($pdbfile);
    $pdbfile = $ACRMPerlVars::pdbprep . $pdb . $ACRMPerlVars::pdbext;
    $chain = "0" if(($chain eq " ") || ($chain eq ""));
    `$::getchain $chain $pdbfile | $::pdb2pir > $tmp`;
}


#*************************************************************************
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


