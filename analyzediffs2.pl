#!/usr/bin/perl 
$InSection = 0;
while(<>)
{
    if(/Changes/)
    {
        $InSection = 1;
    }
    elsif($InSection)
    {
        if(/^</)
        {
            ($old,$new) = split(/\s+REPLACED BY\s+/, $_);
            (@olds) = split(/\s+/, $old);
            (@news) = split(/\s+/, $new);
            if(@olds == 6)
            {
                $oldac = $olds[3];
            }
            elsif(@olds == 5)
            {
                $oldac = $olds[2];
            }
            else
            {
                print STDERR "duhhh...\n";
            }
            if(@news == 6)
            {
                $newac = $news[3];
            }
            elsif(@news == 5)
            {
                $newac = $news[2];
            }
            else
            {
                print STDERR "duhhh...\n";
            }

            if($oldac eq $newac)
            {
                push @ranges, $_;
            }
            else
            {
                push @accessions, $_;
            }
        }
    }
    else
    {
        print;
    }
}

print "Accession change\n";
print "================\n";

foreach $line (@accessions)
{
    print $line;
}

print "\n\nRange change\n";
print "============\n";

foreach $line (@ranges)
{
    print $line;
}

