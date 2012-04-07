#!/usr/bin/perl
#
# This script is passed two svn revs and a file name.
# It pulls all the commits betwen the two revs and fetches
# all the info from them.  commiter, time, what pkg
# and then outputs that to a file that is read by another
# script and puts that info into the db table for
# the avail.php to display.
# This is split into two scripts so it's easier to
# go between svn,git, polling and hook script.

use warnings;
use strict;
use Data::Dumper;

my $debug = 0;

if (scalar(@ARGV) < 4) {
	print "Usage: $0 <svn_path> <start_rev> <stop_rev> <outfile> [debug]\n";
	print "   This script loops through svn from revision <start_rev> to <stop_rev>\n";
	print "   and gathers all the info and writes it out to <outfile>\n";
	print "\n";
	exit 1;
}

print "------------------------------\nExecuting '$0 " . join(" ", @ARGV) . "'\n";

sub END { print "End of $0\n------------------------------\n" };

my $svn_path = $ARGV[0];
my $start_ver= $ARGV[1];
my $stop_ver = $ARGV[2];
my $outfile  = $ARGV[3];
$debug = $ARGV[4] if (defined($ARGV[4]));

my $is_unity = 0;
my $is_mdv = 0;
my $cntr = -1;
my ($msglinecntr, $pkgcntr);
my @revinfo;
my %pkginfo;

foreach my $line (`svn -r$start_ver:$stop_ver -v log $svn_path 2>/dev/null`) # loop thru revision info one line at a time
{
	chomp $line;
	print "$0: '$line'\n" if $debug;

	# every revision begins with a line of dashes
	if ( $line =~ /^\-+$/) {
		$msglinecntr = 0;
		$pkgcntr = 0;
		$cntr++;
	} elsif ( $line eq '') {
		# skip the blank lines
		next;
	} elsif ( $line =~ /^Changed paths/) {
		# do nothing, we just toss this line out.
		next;
	} elsif ($line =~ /^r(\d+)/) { # only the first line beginning with 'r'
		# This is the rev# and info we want. It is in the format of
		# r552934 | anssi | 2010-07-13 13:57:21 -0600 (Tue, 13 Jul 2010) | 2 lines
		print "\tfetch_revs.pl: found REV line: '$line'\n" if $debug;
		my @tmp = split(/\s+\|\s+/, $line);

		# get just the numeric portion of the revision
		$revinfo[$cntr]{"rev"} = $1;
		$revinfo[$cntr]{"committer"} = $tmp[1];

		# format the date as we want
		@tmp = split(/\s+/, $tmp[2]);
		$revinfo[$cntr]{"commitdate"} = $tmp[0];
		$revinfo[$cntr]{"committime"} = $tmp[1];
		$revinfo[$cntr]{"committz"} = $tmp[2];
	} elsif ( $line =~ /^   . \/packages\/([^\/]+)\/(.*)$/ ) { # if change path contains "packages", then it's a Unity Linux package
		$is_unity = 1;
		$revinfo[$cntr]{"pkgs"}[$pkgcntr] = $1;
		$revinfo[$cntr]{"pkgdetails"}[$pkgcntr] = $2;
		if ($revinfo[$cntr]{"pkgdetails"}[$pkgcntr] =~ /pkginfo/) {
			$pkginfo{$revinfo[$cntr]{"pkgs"}[$pkgcntr]} = 1;
		}
		$pkgcntr++;
		$revinfo[$cntr]{"pkgcnt"} = $pkgcntr;
	} elsif ( $line =~ /\/cooker\/([^\/]+?)\/current/ ) { # if the change path contains "cooker/blah/current", then it's a MDV package
		$is_mdv = 1;
		$revinfo[$cntr]{"pkgs"}[$pkgcntr] = $1;
		$pkgcntr++;
		$revinfo[$cntr]{"pkgcnt"} = $pkgcntr;
	} else { # assuming the rest is the commit msg.
		# which also means we have all our pkgs, so we can uniq them
		$revinfo[$cntr]{"msg"}[$msglinecntr] = $line;
		$msglinecntr++;
		$revinfo[$cntr]{"msglinecnt"} = $msglinecntr;
	}
}

# write the output to file
open(OUTP, ">" . $outfile) or die("Cannot open $outfile for writing: $!\n");

if ($is_unity) {
	foreach (keys(%pkginfo)) {
		print "FOUND MDV pkginfo in Unity's SVN for $_. Importing ...\n";
		my @mdv_co = `altsvn.sh $_`;
		print $_ foreach @mdv_co;
	}
}

foreach my $commit (@revinfo) {
	print Dumper($commit) if $debug;

	my (%seen, @uniq, $msg);
	foreach my $pkgname (@{$$commit{"pkgs"}}) {
		unless ($seen{$pkgname}++) {
			push @uniq, $pkgname;
		}
	}

	$msg = join(" ", @{$$commit{"msg"}});
	# just in case the delimiter char shows up in the msg, we replace with space.
	$msg =~ s/\|/ /g;

	foreach my $line (@uniq) { # loop thru committed packages one at a time
		my $specfile = '';
		if ($is_unity) {
			# most Unity spec files will be in this format
			$specfile = "$svn_path/$line/F/$line.spec";
			if (! -e $specfile) {
				# but sometimes, the files can be in this format ;-)
				$specfile = "$svn_path/$line/$line.spec";
			}
		} elsif ($is_mdv) {
			$specfile = "$svn_path/$line/current/SPECS/$line.spec";
		}

		if (-e $specfile) {
			$$commit{"pkgver"} = GetSpecFileTag('version', $specfile, 1);
			$$commit{"pkgrel"} = GetSpecFileTag('release', $specfile, 1);
			$$commit{"pkgsummary"} = GetSpecFileTag('summary', $specfile); 
		} else {
			$$commit{"pkgrel"} = "Unknown";
			$$commit{"pkgver"} = "Unknown";
			$$commit{"pkgsummary"} = "Spec file ($specfile) not found.";
		}

		print OUTP $$commit{"rev"} . " | ";
		print OUTP $$commit{"pkgver"} . " | ";
		print OUTP $$commit{"pkgrel"} . " | ";
		print OUTP $$commit{"committer"} . " | ";
		print OUTP $$commit{"commitdate"} . " | ";
		print OUTP $$commit{"committime"} . " | ";
		print OUTP $$commit{"committz"} . " | ";
		print OUTP $line . " | ";
		print OUTP $$commit{"pkgsummary"} . " | ";
		print OUTP $msg . "\n";
	}
}

close(OUTP);
exit 0;

sub GetSpecFileTag {
	my $tag = shift;
	my $specfile = shift;
	my $numlines = shift;
	# limit the output to 10 lines unless otherwise specified
	$numlines = 10 unless defined $numlines;

	my @value = `rpm -q --specfile --qf '%{$tag}\n' $specfile 2>/dev/null | head -$numlines`;
	my $value = '';
	foreach (@value) {
		chomp;
		$value .= "$_ ";
	}
	$value =~ s/\|/ /g;

	return $value;
}
