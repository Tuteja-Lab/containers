#!/usr/bin/perl
use strict;
use warnings;
# Removes the soft mask
if(not defined $ARGV[0])
	{
	print "usage: faUnmask.pl <input.fa>\n";
	exit(0);
	}
my $first = 0;
open(file1, $ARGV[0]) or die "Unable to read file [$ARGV[0]]\n";
while (my $line1 = <file1>) {
    if ($line1 =~/\>.*/) {
        print $line1;
    }else{
        print uc($line1);
    }
}
close(file1);
