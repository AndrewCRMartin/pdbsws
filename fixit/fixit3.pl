#!/acrm/usr/local/bin/perl
while(<>)
{
    $pdb = substr($_,1,4);
    $chain = substr($_,8,1);
    $ac = substr($_,16,6);
    $count = substr($_,25,5);

    if((substr($_,0,1) eq " ") &&
       ($ac ne "      ") && 
       ($count > 5))
    {
        $sql = "UPDATE pdbsws SET ac = '$ac' where pdb = '$pdb' and chain = '$chain'";
        print "$sql;\n";
    }
}

# Anything still flagged as ac='DNA' and aligned='t' is wrong and
# shouldn't be marked as aligned.
$sql = "UPDATE pdbsws SET aligned = 'f' where ac='DNA' and aligned='t'";
print "$sql;\n";
