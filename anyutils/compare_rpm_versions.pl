#!/usr/bin/perl

use warnings;
use strict;
use RPM::Header;

if (scalar(@ARGV) != 2) {
	my $usage = "Wrong number of arguments given!\n\n";
	$usage .= "\tUsage: $0 /path/to/file1.rpm /path/to/file2.rpm\n\n";
	$usage .= "This script will compare the versions of file1.rpm with file2.rpm and print to STDOUT\n";
	$usage .= "\t  1 if file1.rpm > file2.rpm\n";
	$usage .= "\t  0 if file1.rpm = file2.rpm\n";
	$usage .= "\t -1 if file1.rpm < file2.rpm\n";
	$usage .= "The script exists with 0 on success and -1 on failure.\n";

	print $usage;
	exit -1;
}

my $hdr1 = rpm2header($ARGV[0]);
my $hdr2 = rpm2header($ARGV[1]);

exit -1 unless (defined($hdr1) && defined($hdr2));
print $hdr1->compare($hdr2) . "\n";

exit 0;
