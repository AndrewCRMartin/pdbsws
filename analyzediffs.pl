#!/usr/bin/perl
use strict;

@::additions = ();
@::deletions = ();
@::changes   = ();

my(@lines);

@lines = ();
while(<>)
{
    if(/^\d/)
    {
        HandleBlock(@lines);
        @lines = ();
    }
    else
    {
        push @lines, $_;
    }
}

print "Additions\n=========\n";
PrintData(@::additions);
print "Deletions\n=========\n";
PrintData(@::deletions);
print "Changes\n=======\n";
PrintData(@::changes);

sub PrintData
{
    my(@array) = @_;
    my($line);

    foreach $line (@array)
    {
        print $line;
    }
}
sub HandleBlock
{
    my(@lines) = @_;
    my($line, $del, $add, @old, @new, $i, $count);

    if(@lines > 0)
    {
        $del = $add = 0;
        foreach $line (@lines)
        {
            if($line =~ /^\</)
            {
                $del = 1;
            }
            elsif($line =~ /^\>/)
            {
                $add = 1;
            }
        }
        if($del && $add)
        {
            # It's a change
            foreach $line (@lines)
            {
                chomp $line;
                if($line =~ /^\</)
                {
                    push @old, $line;
                }
                elsif($line =~ /^\>/)
                {
                    push @new, $line;
                }
            }
            $count = @old > @new ? @old : @new;
            for ($i=0; $i<$count; $i++)
            {
                if(substr($old[$i],2,6) eq substr($new[$i],2,6))
                {
                    push @::changes, "$old[$i]\tREPLACED BY\t$new[$i]\n";
                }
                else
                {
                    if(defined($old[$i]))
                    {
                        push @::deletions, $line;
                    }
                    elsif(defined($new[$i]))
                    {
                        push @::additions, $line;
                    }
                }
            }
        }
        elsif($add)
        {
            # It's an addition
            foreach $line (@lines)
            {
                push @::additions, $line;
            }
        }
        elsif($del)
        {
            # It's a deletion
            foreach $line (@lines)
            {
                push @::deletions, $line;
            }
        }
    }
}
