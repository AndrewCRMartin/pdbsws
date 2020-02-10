#!/acrm/usr/local/bin/perl
#*************************************************************************
#
#   Program:    
#   File:       
#   
#   Version:    
#   Date:       11.07.11
#   Function:   
#   
#   Copyright:  (c) UCL / Dr. Andrew C. R. Martin 2011
#   Author:     Dr. Andrew C. R. Martin
#   Address:    Biomolecular Structure & Modelling Unit,
#               Department of Biochemistry & Molecular Biology,
#               University College,
#               Gower Street,
#               London.
#               WC1E 6BT.
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
my $totalchains = GetCount("select count(*) from pdbsws");
print "Total PDB chains in PDBSWS: $totalchains\n";
my $shortpeptides = GetCount("select count(*) from pdbsws where ac = 'SHORT'");
print "  of which, number of short peptides: $shortpeptides\n";
my $dna = GetCount("select count(*) from pdbsws where ac = 'DNA'");
print "  and, number of DNA/RNA chains: $dna\n";
$proteinchains = ($totalchains - ($shortpeptides + $dna));
printf "  (therefore protein chains: %d)\n\n", $proteinchains;

my $pdbXlink = GetCount("select count(*) from pdbsws where ac not in ('?', 'SHORT', 'DNA') and source like 'pdb%'");
print "Cross-links obtained from the PDB: $pdbXlink\n";
my $SPXlink = GetCount("select count(*) from pdbsws where ac not in ('?', 'SHORT', 'DNA') and source = 'sprot'");
print "Cross-links obtained from SwissProt: $SPXlink\n";
my $BruteXlink = GetCount("select count(*) from pdbsws where ac not in ('?', 'SHORT', 'DNA') and source = 'brute'");
print "Cross-links obtained from Brute-force scan: $BruteXlink\n";
printf "   (i.e. an additional %.2f%%)\n\n", 100.0*$BruteXlink/($pdbXlink + $SPXlink);

my $unmatched = GetCount("select count(*) from pdbsws where ac = '?'");
print "Number of unmatched chains: $unmatched\n";
printf "   (i.e. %.2f%% of the protein chains)\n\n", 100.0*$unmatched/$proteinchains;

#*************************************************************************
sub GetCount
{
    my ($sql) = @_;

    my $count = `psql -h acrm8 -tqc \"$sql\" pdbsws`;
    chomp $count;
    $count =~ s/\s//g;
    return($count);
}
