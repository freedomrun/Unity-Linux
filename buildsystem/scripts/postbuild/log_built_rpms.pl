#!/usr/bin/perl

use warnings;
use strict;
use DBI();

die "Usage: $0 pkg jobid jobfile svnver user target\n" unless (scalar(@ARGV) == 6);
my ($pkg, $jobid, $jobfile, $svnver, $user, $target) = @ARGV;

# Connect to the database.
my $dbh = DBI->connect("DBI:mysql:database=BS;host=localhost", 'insertevent', 'insertevent', {'RaiseError' => 1});

# using the jobfile, figure out which RPMs were generated
open(FIL, "$jobfile.o$jobid") || die "Cannot open jobfile for reading: $!\n";
my @joblog = <FIL>;
close(FIL);

my $arch = '';
foreach (@joblog) {
	chomp;

	if (/Entering 32bit chroot/) {
		$arch = 'i586';
		next;
	}
	if (/Entering 64bit chroot/) {
		$arch = 'x86_64';
		next;
	}
	next unless (/Wrote:/);

	my @chunks = split(/\//);
	my $thearch = $chunks[6];
	if ($thearch eq 'noarch') {
		$thearch = "$arch/noarch";
	}

	# the exact RPM may already have existed (a rebuild of the same verion-revion)
	my $is_exact_rebuild = 0;
	my $sth = $dbh->prepare("SELECT * FROM rpms WHERE RpmName='$chunks[7]' AND arch='$thearch'");
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref()) {
		$is_exact_rebuild = 1;
		$dbh->do("UPDATE rpms SET LastModifiedBy='$user', LastModifiedOn=NOW(), LastMod='rebuilt', JobID='$jobid' WHERE RpmName='$chunks[7]' AND arch='$thearch'");
	}
	$sth->finish();

	# if this is a newly recorded RPM then create a new entry for it
	if (!$is_exact_rebuild) {
		$dbh->do("INSERT INTO rpms (RpmName,arch,JobID,CreatedBy,CreatedOn) VALUES('$chunks[7]', '$thearch', '$jobid', '$user', NOW())");
	}

	# schedule the move of this RPM to the target channel in the repo
	my $pending_action_cmd = "\\mv /home/builduser/pkgs/$arch/$chunks[7] \$repo_path/$arch/$target " . '2>&1' . "\n";
	`php -r 'require_once("/var/www/secure/BS/settings.php"); write_pending_action("$pending_action_cmd");'`;
}

# Disconnect from the database.
$dbh->disconnect();

