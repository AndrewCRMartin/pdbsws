#!/acrm/usr/local/bin/perl

use CGI;
use LWP::UserAgent;
use ACRMPerlVars;
use strict;

my($id, @ids, $ac);

$|=1;

@ids = ("ARTN_HUMAN",
        "BMNH4_BOMVA",
        "CATS_HUMAN",
        "CO3_BOVIN",
        "CXAA_CONOM",
        "DEOD_BACHK",
        "DJC17_HUMAN",
        "GLNA4_MAIZE",
        "GRFIN_GRISQ",
        "IPKA_PIG",
        "KA156_TITDI",
        "LIMA1_HUMAN",
        "MYSM1_HUMAN",
        "NOSO_BACSU",
        "O05205_STRLA",
        "O07897_THETH",
        "O10647_9POXV",
        "O28769_ARCFU",
        "O30192_ARCFU",
        "O39914_9HEPC",
        "O57883_PYRHO",
        "O58085_PYRHO",
        "O58246_PYRHO",
        "O58493_PYRHO",
        "O66753_AQUAE",
        "O77077_PLAFA",
        "P74846_SALTY",
        "Q1EFN3_CVHSA",
        "Q1GBW8_LACDA",
        "Q1R4E7_ECOUT",
        "Q1XDX7_9ACTO",
        "Q29U70_MEDTR",
        "Q2A5P7_FRATH",
        "Q2AM32_9BACI",
        "Q2I8V6_9RHIZ",
        "Q2IAM1_CHICK",
        "Q323V1_SHIBS",
        "Q3ZDQ7_XANMA",
        "Q3ZDQ8_XANMA",
        "Q3ZDQ9_XANMA",
        "Q3ZDR0_XANMA",
        "Q41560_WHEAT",
        "Q43866_ARATH",
        "Q45040_BORBU",
        "Q46R41_RALEJ",
        "Q4AE23_9RHIZ",
        "Q4AE24_9RHIZ",
        "Q4AE26_9RHIZ",
        "Q4SPJ4_TETNG",
        "Q4U1A6_MICLU",
        "Q4US32_XANC8",
        "Q4V016_XANC8",
        "Q53TV6_HUMAN",
        "Q59718_PSESP",
        "Q59GK8_HUMAN",
        "Q5R774_PONPY",
        "Q5RKJ4_RAT",
        "Q5S3G8_9CNID",
        "Q5SHI0_THET8",
        "Q5SHZ3_THET8",
        "Q5SMG6_THET8",
        "Q62747_RAT",
        "Q6GMX8_HUMAN",
        "Q6L6Q4_BACST",
        "Q6N1A7_RHOPA",
        "Q6NAY9_RHOPA",
        "Q6RCW6_CVHSA",
        "Q6RCY8_CVHSA",
        "Q6RCZ9_CVHSA",
        "Q6RD65_CVHSA",
        "Q6VAA1_CVHSA",
        "Q6WV12_9MAXI",
        "Q72KX2_THET2",
        "Q72LN8_THET2",
        "Q76CT3_ASPKA",
        "Q81WA9_BACAN",
        "Q82SY3_NITEU",
        "Q83883_9CALI",
        "Q874E9_9HETE",
        "Q8BPC1_MOUSE",
        "Q8DQ00_STRR6",
        "Q8DUQ5_STRMU",
        "Q8EEC8_SHEON",
        "Q8GBY1_PSEFL",
        "Q8GSD2_9FABA",
        "Q8KGE0_CHLTE",
        "Q8KNF0_MICEC",
        "Q8PIS1_XANAC",
        "Q8U1H5_PYRFU",
        "Q8XFH3_SALTI",
        "Q91RS4_9HEPC",
        "Q93X60_CICIN",
        "Q98VX2_IBDV",
        "Q99AU2_9HEPC",
        "Q9A097_STRP1",
        "Q9HK62_THEAC",
        "Q9HWC1_PSEAE",
        "Q9I704_PSEAE",
        "Q9M6E9_ABRPR",
        "Q9R9I3_BACSU",
        "Q9REU3_DESVU",
        "Q9RN64_STRNO",
        "Q9S0Z5_ECOLI",
        "Q9WI42_IBDV",
        "Q9WZY5_THEMA",
        "Q9X006_THEMA",
        "Q9XTN4_DROME",
        "Q9Y3V5_HUMAN",
        "TRPB_THET2",
        "UBXD8_HUMAN",
        "UGL_BACGL",
        "VRP2_SALCH",
        "YLII_ECOLI");


foreach $id (@ids)
{
    $ac = GetAC($id);
    InsertEntry($id, $ac) if($ac ne "");
}


sub GetAC
{
    my($id) = @_;
    my($url, $post, $webproxy, $ua, $req, $result, $ac);
    $webproxy = "";

    $id =~ s/\s//g;

    # URL for the page we are accessing
    $url         = "http://www.expasy.org/uniprot/" . $id . ".txt";

    # Data to send to the CGI script, obtained by examining the 
    # submission web page

    $ua = CreateUserAgent($webproxy);
    $req = CreateGetRequest($url);
    $result = GetContent($ua, $req);
    
    if(defined($result))
    {
        my(@lines, $line);
        @lines = split(/\n/, $result);
        foreach $line(@lines)
        {
            if($line =~ /^AC\s/)
            {
                if($line =~ /^AC\s+(\w\w\w\w\w\w);/)
                {
                    $ac = $1;
                }
                last;
            }
        }
        return($ac);
    }
    else
    {
        print STDERR "connection failed\n";
    }

    return("");
}

sub InsertEntry
{
    my($id, $ac) = @_;
    my($sql);
    
    $sql = "DELETE FROM idac WHERE id = '$id';";
    print "$sql\n";

    $sql = "INSERT INTO idac VALUES ('$id', '$ac');";
    print "$sql\n";
}

########################################################################
sub GetContent
{
    my($ua, $req) = @_;
    my($res);

    $res = $ua->request($req);
    if($res->is_success)
    {
        return($res->content);
    }
    return(undef);
}

########################################################################
sub CreateGetRequest
{
    my($url) = @_;
    my($req);
    $req = HTTP::Request->new('GET',$url);
    return($req);
}

########################################################################
sub CreateUserAgent
{                               
    my($webproxy) = @_;

    my($ua);
    $ua = LWP::UserAgent->new;
    if(length($webproxy))
    {
        $ua->proxy(['http', 'ftp'] => $webproxy);
    }
    return($ua);
}
