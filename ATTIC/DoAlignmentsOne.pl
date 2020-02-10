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

# External programs
$::ssearch = "$ACRMPerlVars::ssearch -a -q -E 1000 -m 10";

# Initialize variables
%::throne = ('ALA' => 'A',
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
             'TYR' => 'Y',
             'HYP' => 'P');

# Names for temporary files
$::tmp1 = "/tmp/DA.$$._temp1.faa";
$::tmp2 = "/tmp/DA.$$._temp2.faa";
$::tmp3 = "/tmp/DA.$$._temp3.faa";
$::tmp4 = "/tmp/DA.$$._temp4.faa";

#DoProcessing();
#ProcessEntry("101m", " ", "P02185", 
#             "VLSEGEWQLVLHVWAKVEADVAGHGQDILIRLFKSHPETLEKFDRFKHLKTEAEMKASEDLKKHGVTVLTALGAILKKKGHHEAELKPLAQSHATKHKIPIKYLEFISEAIIHVLHSRHPGDFGADAQGAMNKALELFRKDIAAKYKELGYQG",
#             $::tmp1, $::tmp2, $::tmp3, $::tmp4);
#ProcessEntry("1bv0", "D", "P11540", 
#             "KKAVINGEQIRSISDLHQTLKKELALPEYYGENLDALWDCLTGWVEYPLVLEWRQFEQSKQLTENGAESVLQVFREAKAEGCDITIILS",
#             $::tmp1, $::tmp2, $::tmp3, $::tmp4);
ProcessEntry("1a7m", " ", "P15018", 
"SPLPITPVNATCAIRHPCHGNLMNQIKNQLAQLNGSANALFISYYTAQGEPFPNNLDKLCGPNVTDFPPFHANGTEKAKLVELYRMVAYLSASLTNITRDQKVLNPSAVSLHSKLNATIDVMRGLLSNVLCRLCNKYRVGHVDVPPVPDHSDKEVFQKKKLGCQLLGTYKQVISVVVQAF",
             $::tmp1, $::tmp2, $::tmp3, $::tmp4);
ProcessEntry("1a7m", " ", "P09056", 
"SPLPITPVNATCAIRHPCHGNLMNQIKNQLAQLNGSANALFISYYTAQGEPFPNNLDKLCGPNVTDFPPFHANGTEKAKLVELYRMVAYLSASLTNITRDQKVLNPSAVSLHSKLNATIDVMRGLLSNVLCRLCNKYRVGHVDVPPVPDHSDKEVFQKKKLGCQLLGTYKQVISVVVQAF",
             $::tmp1, $::tmp2, $::tmp3, $::tmp4);
unlink($::tmp1);
unlink($::tmp2);
unlink($::tmp3);
unlink($::tmp4);

#*************************************************************************
sub DoProcessing
{
    my($sql, $sth, $rv, @results, $seq);

    $sql = "SELECT pdb, chain, ac FROM pdbsws WHERE valid = 't' AND aligned = 'f'";
    $sth = $::dbh2->prepare($sql);
    $rv = $sth->execute;
    while(@results = $sth->fetchrow_array)
    {
        $sql   = "SELECT sequence FROM sprot WHERE ac = '$results[2]'";
        ($seq) = $::dbh->selectrow_array($sql);
        ProcessEntry($results[0], $results[1], $results[2], $seq,
                     $::tmp1, $::tmp2, $::tmp3, $::tmp4);
    }
}


#*************************************************************************
sub ProcessEntry
{
    my($pdb, $chain, $ac, $sequence, $swsseqfile, $pdbseqfile, $idmap, $alignout) = @_;
    my($swsaln, $pdbaln,@swsarray,@pdbarray,$i,@resid,@resnam,@seq);
    my($pdbcount, $swscount);

    print "INFO: Running alignment for $pdb chain '$chain' with $ac\n";

    WriteFASTA($swsseqfile, $ac, $sequence);
    WritePDBSequence($pdbseqfile, $idmap, $pdb, $chain);
    ($swsaln, $pdbaln) = DoAlign($swsseqfile, $pdbseqfile, $alignout);

    @swsarray = split(//, $swsaln);
    @pdbarray = split(//, $pdbaln);

    GetIDMap($idmap, \@resid, \@resnam, \@seq);

#    DeleteCurrentAlignment($pdb, $chain, $ac);

    $pdbcount = -1;
    $swscount = -1;
    for($i=0; $i<@swsarray; $i++)
    {
        $pdbcount++ if($pdbarray[$i] ne "-");
        $swscount++ if($swsarray[$i] ne "-");

        if(($pdbarray[$i] ne "-") && ($swsarray[$i] ne "-"))
        {
            DeleteRecord($pdb, $chain, $pdbcount+1);
            StoreData($pdb, $chain, $pdbcount+1, $resnam[$pdbcount],
                      $seq[$pdbcount],
                      $resid[$pdbcount], $ac, $swsarray[$i], $swscount+1);
        }
        elsif($pdbarray[$i] ne "-")
        {
            DeleteRecord($pdb, $chain, $pdbcount+1);
            StoreData($pdb, $chain, $pdbcount+1, $resnam[$pdbcount],
                      $seq[$pdbcount],
                      $resid[$pdbcount], "", "", 0);
        }
    }

    MarkAsAligned($pdb, $chain, $ac);
}

#*************************************************************************
sub DeleteCurrentAlignment
{
    my($pdb, $chain, $ac) = @_;
    my($sql);
    
    $sql = "DELETE FROM alignment WHERE pdb = '$pdb' AND chain = '$chain' AND (ac = '$ac' OR ac = '')";
    $::dbh->do($sql);
}

#*************************************************************************
sub DeleteRecord
{
    my($pdb, $chain, $pdbcount) = @_;
    my($sql);
    
    $sql = "DELETE FROM alignment WHERE pdb = '$pdb' AND chain = '$chain' AND pdbcount = $pdbcount";
    $::dbh->do($sql);
}

#*************************************************************************
sub StoreData
{
    my($pdb, $chain, $pdbcount, $resnam, $pdbaa, $resid, $ac, $swsaa, $swscount) = @_;
    my($sql);

    $sql = "INSERT INTO alignment VALUES ('$pdb', '$chain', $pdbcount, '$resnam', '$pdbaa', '$resid', '$ac', '$swsaa', $swscount)";
    $::dbh->do($sql);
}

#*************************************************************************
sub MarkAsAligned
{
    my($pdb, $chain, $ac) = @_;
    my($sql);

    $sql = "UPDATE pdbsws SET aligned = 't' WHERE pdb = '$pdb' AND chain = '$chain' AND ac = '$ac'";
    $::dbh->do($sql);
}

#*************************************************************************
sub GetIDMap
{
    my($idmap, $resid_p, $resnam_p, $seq_p) = @_;
    my(@fields);

    open(FILE, $idmap) || die "Can't read PDB ID map $idmap";
    while(<FILE>)
    {
        chomp;
        s/^\s+//;
        s/\s+$//;
        @fields = split;
        push @$resid_p,  @fields[0];
        push @$resnam_p, @fields[1];
        push @$seq_p,    @fields[2];
    }
    close(FILE);
}

#*************************************************************************
sub WritePDBSequence
{
    my($fastafile, $idmap, $pdb, $chain) = @_;
    my($lastresid, $chainid, $resnam, $resid, $pdbfile);

    $chain = substr($chain, 0, 1);
    $pdb   = substr($pdb,   0, 4);

    $pdbfile = $ACRMPerlVars::pdbprep . $pdb . $ACRMPerlVars::pdbext;

    open(PDB, $pdbfile)        || die "Can't read $pdbfile";
    open(FASTA, ">$fastafile") || die "Can't write FASTA file $fastafile";
    open(IDMAP, ">$idmap")     || die "Can't write ID map file $idmap";

    print FASTA ">$pdb$chain\n";

    $chain = " " if($chain eq "");
    $lastresid = "";
    while(<PDB>)
    {
        $resnam  = substr($_, 17, 3);
        if(/^ATOM  / || (/^HETATM/ && defined($::throne{$resnam})))
        {
            $chainid = substr($_, 21, 1);
            $resid   = substr($_, 22, 5);

            if($chain eq $chainid)
            {
                if($resid ne $lastresid)
                {
                    if(defined($::throne{$resnam}))
                    {
                        print FASTA $::throne{$resnam};
                        print IDMAP "$resid $resnam $::throne{$resnam}\n";
                    }
                    $lastresid = $resid;
                }
            }
        }
        elsif(/^ENDMDL/)
        {
            last;
        }
    }
    print FASTA "\n";
    close PDB;
    close FASTA;
    close IDMAP;
}

#*************************************************************************
sub DoAlign
{
    my($file1, $file2, $results) = @_;
    my(@ids, $id, $EntryNumber, @seqs);

    # Run the alignment
    `$::ssearch $file1 $file2 > $results`;

    # Grab the alignment out of the file
    open(FILE, $results) || die "Can't read alignment results: $results";
    while(<FILE>)
    {
        chomp;
        if(/^>[0-9A-Za-z]/)
        {
            $id = $_;
            $id =~ s/\s.*//;
            $id =~ s/^>//;
            push @ids, $id;
            $seqs[$EntryNumber++] = "";
        }
        elsif(/^>>><<</)
        {
            last;
        }
        elsif($EntryNumber)
        {
            if(!/^\; /)
            {
                $seqs[$EntryNumber-1] .= $_;
            }
        }
    }
    close FILE;

    # Pad the shorter sequence
    if(length($seqs[0]) < length($seqs[1]))
    {
        $seqs[0] .= "-" x (length($seqs[1]) - length($seqs[0]));
    }
    elsif(length($seqs[0]) > length($seqs[1]))
    {
        $seqs[1] .= "-" x (length($seqs[0]) - length($seqs[1]));
    }

    return($seqs[0], $seqs[1]);
}

#*************************************************************************
sub WriteFASTA
{
    my($file, $ac, $seq) = @_;

    open(FILE, ">$file") || die "Can't write $file";
    print FILE ">$ac\n";
    print FILE "$seq\n";
    close(FILE);
}


