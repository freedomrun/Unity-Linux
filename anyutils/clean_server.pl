use warnings;
use strict;
use File::Glob ':globally';
use Getopt::Long;
use Data::Dumper;
use Cwd;
use version 0.77;
use RPM::Header;
use RPM::Constant;

my $VERSION = "1.8";
my $devel_dups = 0;
my $repopath = undef;
my $repo32 = undef;
my $repo64 = undef;
my $help = 0;
my $version = 0;
my @dups = (0,0);
my $location = 0;
my $notexist = 0;
my $findsibs = undef;
my $ignoretest = 0;
my $ignoreunstable = 0;
my $listokdups = 0;
my $vercheck = 0;
my $path_separator = '/';

use Carp;
$SIG{ __DIE__ } = sub { Carp::confess( @_ ) };


# This is the list of duplicates which are OK. Exactly one revision of each of these versions can co-exist and not be called a duplicate
my %okdups = (
	'automake'                      => ['1.10.2', '1.11'],
	'bash'                          => ['3.2.48', '4.0'],
	'bash-doc'                      => ['3.2.48', '4.0'],
	'jpeg-progs'                    => ['6',      '7b'],
	'maven-surefire'                => ['1.5.3',  '2.3'],
	'maven-surefire-javadoc'        => ['1.5.3',  '2.3'],
	'maven-surefire-booter'         => ['1.5.3',  '2.3'],
	'maven-surefire-booter-javadoc' => ['1.5.3',  '2.3'],
	'squashfs-tools'                => ['3.4',    '4.0'], # needed for lzma
	'enchant'		        => ['1.4.2',  '1.5.0'], # needed for sylpheed
	'libenchant-devel'              => ['1.4.2',  '1.5.0'], # needed for sylpheed
	'libenchant1'                   => ['1.4.2',  '1.5.0'], # needed for sylpheed
	'lib64enchant1'                 => ['1.4.2',  '1.5.0'], # needed for sylpheed
);

GetOptions(
	'devel!'      => \$devel_dups,
	'repopath=s'  => \$repopath,
	'repo32:s'    => \$repo32,
	'repo64:s'    => \$repo64,
	'help'        => \$help,
	'version'     => \$version,
	'dups32!'     => \$dups[0],
	'dups64!'     => \$dups[1],
	'location!'   => \$location,
	'ignoretest+' => \$ignoretest,
	'ignoreunstable+' => \$ignoreunstable,
	'listokdups!' => \$listokdups,
	'notexist!'   => \$notexist,
	'vercheck!'   => \$vercheck,
	'findsibs=s@' => \$findsibs,
);

$help = 1 unless ( 
	defined($findsibs) || 
	$vercheck || 
	$notexist || 
	$location || 
	$dups[0] || 
	$dups[1] 
);

# deal with deprecated --repo32 and --repo64 options if specified
if (!defined($repo32) && !defined($repo64)) {
	if (defined $repopath) {
		$repo32 = $repopath . $path_separator . 'i586';
		$repo64 = $repopath . $path_separator . 'x86_64';
	} else {
		$help = 1;
	}
}

if ($version) {
	print "$0 " . version->parse($VERSION)->normal . "\n";
	exit;
}

if ($help) {
	print "Usage: $0 [options] [actions]\n\n";
	print "Possible Options:\n";
	print "--help        print this message and exit.\n";
	print "--version     print the script version number and exit.\n";
	print "--devel       treat devel package names with major version in the name as though\n";
	print "              the major version was not in the name.\n";
	print "--repo32=path DEPRECATED BY 'repopth': specify path to 32-bit repo (default $repo32).\n";
	print "--repo64=path DEPRECATED BY 'repopth': specify path to 64-bit repo (default $repo64).\n";
	print "--repopath=s  The path to the repo (without arch specific extension).\n";
	print "--ignoretest  do not treat packages as duplicates if at least one version is in test channel (default FALSE).\n";
	print"               This option can be specified several times to increase its affectiveness.\n";
	print "--ignoreunstable  do not treat packages as duplicates if at least one version is in unstable channel (default FALSE)\n";
	print"               This option can be specified several times to increase its affectiveness.\n";

	print "--listokdups  list duplicates which have been explicitly defined as OK duplicates (default FALSE)\n";
	print "\n";
	print "Possible Actions:\n";
	print "--dups32      identify duplicate packages within the 32-bit repo\n";
	print "--dups64      identify duplicate packages within the 64-bit repo\n";
	print "--location    identify packages not residing in same section b/w 32/64 bit repos\n";
	print "--notexist    identify packages that do not exist in both 32 and 64 bit repos\n";
	print "--vercheck    identify packages that have different version/revision in both 32/64 bit repos\n";
	print "--findsibs=s  identify packages that are related to specified RPM(s) (specify arch/channel/file.rpm)\n";
	exit(0);
}

# Get the directory listing of all components
my @components = split(/\s+/, `/usr/sbin/unity_repo_details.sh -c`);
my %list;

for my $prefix (($repo32, $repo64)) {
	foreach (@components) {
		my $curdir = cwd();
		my $dirname = $prefix . $path_separator . $_;
		chdir($dirname) || die "Can't change directories to $dirname: $!\n";
		@{$list{$dirname}} = <*>;
		chdir($curdir);
	}
}

my %packages;
foreach my $dirname (keys %list) {
	my $full_dir = $dirname . $path_separator;;
	$dirname =~ /(.*)\/+\S+/;
	my $prefix = $1;
	foreach my $package (@{$list{$dirname}}) {
		# skip the metafile directories
		next if ($package =~ /^media_info$/ || $package =~ /^repodata$/);

		my ($name, $ver, $rev, $dist, $arch, $srpm);
		next unless ParsePkgName($full_dir . $package, \$name, \$ver, \$rev, \$dist, \$arch, \$srpm);

		push @{$packages{$name}{$prefix}}, {$package => {'comp'=>$dirname, 'ver'=>$ver, 'rev'=>$rev, 'dist'=>$dist, 'arch'=>$arch, 'sibling'=>$srpm} };

		if ($devel_dups && ($name =~ /(.+)\d+-devel$/) ) {
			$name = $1 . '-devel'; # drop the version number and add to list for duplicates detection
			push @{$packages{$name}{$prefix}}, {$package => {'comp'=>$dirname, 'ver'=>$ver, 'rev'=>$rev, 'dist'=>$dist, 'arch'=>$arch} };
		}
	}
}

if ($dups[0] || $dups[1]) {
	print "Repo Duplicates Report\n";
	my %version_id = ('version_id_max' => 0);
	foreach my $pkgname (sort keys %packages) {

		for my $i (0 .. 1) {
			next unless $dups[$i];
			my $repotype = $i ? $repo64 : $repo32;

			next unless exists $packages{$pkgname}{$repotype};
			next unless (scalar(@{$packages{$pkgname}{$repotype}}) > 1);

			if ($ignoretest) {
				my $num_in_test = 0;
				foreach my $entry (@{$packages{$pkgname}{$repotype}}) {
					foreach my $filename (keys %{$entry}) {
						$num_in_test++ if (${$$entry{$filename}}{comp} =~ /test/);
					}
				}
				next if (($ignoretest == 1) && ($num_in_test == 1));
				next if (($ignoretest > 1) && $num_in_test);
			}

			if ($ignoreunstable) {
				my $num_in_unstable = 0;
				foreach my $entry (@{$packages{$pkgname}{$repotype}}) {
					foreach my $filename (keys %{$entry}) {
						$num_in_unstable++ if (${$$entry{$filename}}{comp} =~ /unstable/);
					}
				}
				next if (($ignoreunstable == 1) && ($num_in_unstable == 1));
				next if (($ignoreunstable > 1) && $num_in_unstable);
			}

			# don't treat PLF version of packages are duplicates
			my $num_PLF = 0;
			foreach my $entry (@{$packages{$pkgname}{$repotype}}) {
				foreach my $filename (keys %{$entry}) {
					$num_PLF++ if (${$$entry{$filename}}{dist} =~ /plf/);
				}
			}
			next if ($num_PLF == 1);


			if (!$listokdups && exists $okdups{$pkgname}) {
				my %found_instances;
				foreach my $entry (@{$packages{$pkgname}{$repotype}}) {
					foreach my $filename (keys %{$entry}) {
						push @{$found_instances{$$entry{$filename}{ver}}}, $$entry{$filename}{rev};
					}
				}

				# if there are just as many version of this package in the repos as what's listed in OKDUPS list
				if ( scalar(keys(%found_instances)) == scalar(@{$okdups{$pkgname}}) ) {
					my $count = 0;
					foreach (keys(%found_instances)) {
						$count++ if (scalar(@{$found_instances{$_}}) == 1);
					}
					# if there is only one revision of each version, then we are OK to not list it as DUP
					next if ($count == scalar(keys(%found_instances)));
				}
			}

			# print Dumper(\@{$packages{$pkgname}{$repotype}});
			print_package_details(\@{$packages{$pkgname}{$repotype}}, $pkgname, \%version_id);
		}
	}
}

if ($location || $notexist || $vercheck) {
	print "32/64 bit repo package location/existance report:\n";
	foreach (sort keys %packages) {
		unless (exists($packages{$_}{$repo32}[0]) && exists($packages{$_}{$repo64}[0])) {
			if ($notexist) {
				print "package $_ does not exist in both repos.\n";
				print Dumper(\%{$packages{$_}});
			}
			next;
		}

		my $r32_pkgname = join('', keys(%{${$packages{$_}{$repo32}}[0]}));
		my $r64_pkgname = join('', keys(%{${$packages{$_}{$repo64}}[0]}));

		${$packages{$_}{$repo32}}[0]{$r32_pkgname}{comp} =~ /^$repo32(.*)$/;
		my $r32_comp = $1;
		${$packages{$_}{$repo64}}[0]{$r64_pkgname}{comp} =~ /^$repo64(.*)$/;
		my $r64_comp = $1;

		if ($r32_comp ne $r64_comp) {
			if ($location) {
				print "package $_ is not in the same component between repos.\n";
				print Dumper(\%{$packages{$_}});
			}
		} else {
			if ($vercheck) {
				if ( (${$packages{$_}{$repo32}}[0]{$r32_pkgname}{ver} ne ${$packages{$_}{$repo64}}[0]{$r64_pkgname}{ver}) || 
					(${$packages{$_}{$repo32}}[0]{$r32_pkgname}{rev} ne ${$packages{$_}{$repo64}}[0]{$r64_pkgname}{rev}) ) {
					print "package $_ is not at same version/revision in both repos.\n";
					print Dumper(\%{$packages{$_}});
				}
			}
		}
	}
	print "\n";
}

if (defined($findsibs)) {
	my %foundsibs;

	foreach (@$findsibs) {
		if (/,/) {
			foreach (split(/,/, $_)) {
				FindSibsFor($_, \%foundsibs);
			}
		} else {
			FindSibsFor($_, \%foundsibs);
		}
	}
}

sub print_package_details {
	my $r = shift;
	my $pkgname = shift;
	my $ver_r = shift;
	my $r_foundsibs = shift;

	foreach my $detail (@$r) {
		foreach my $filename (keys %$detail) {

			my $ver_rev = ${$$detail{$filename}}{ver} . '-' . ${$$detail{$filename}}{rev} . '-' . ${$$detail{$filename}}{dist};
			if (!exists($$ver_r{$ver_rev})) {
				$$ver_r{$ver_rev} = $$ver_r{version_id_max}++;
			}
			$ver_rev = $$ver_r{$ver_rev};

			my $sib_unique_name = ${$$detail{$filename}}{arch} . '-' . ${$$detail{$filename}}{comp} . '-' . $filename;
			if (defined($r_foundsibs)) {
				if (exists $$r_foundsibs{$sib_unique_name}) {
					next;
				} else {
					$$r_foundsibs{$sib_unique_name} = 1;
				}
			}

			printf("%s::%s::%s::%s::", ${$$detail{$filename}}{sibling}, $pkgname, $ver_rev, $filename);
			print ${$$detail{$filename}}{comp} . "::";
			print ${$$detail{$filename}}{ver} . "::";
			print ${$$detail{$filename}}{rev} . "::";
			print ${$$detail{$filename}}{dist} . "::";
			print ${$$detail{$filename}}{arch};
			print "\n";
		}
	}
}

my %sibling_id = ('sibling_id_max' => 0);

sub ParsePkgName {
	my $package = shift;
	my $name_r = shift;
	my $ver_r = shift;
	my $rev_r = shift;
	my $dist_r = shift;
	my $arch_r = shift;
	my $sourcerpm_r = shift;

	my $header = rpm2header($package);
	unless (defined($header)) {
		warn "Cannot extract header from '$package'\n";
		return 0;
	}

	$$name_r = _getRpmTagValue($header, 'NAME');
	$$ver_r  = _getRpmTagValue($header, 'VERSION');
	$$rev_r  = _getRpmTagValue($header, 'RELEASE');
	my $disttag = _getRpmTagValue($header, 'DISTTAG');
	my $distepoch = _getRpmTagValue($header, 'DISTEPOCH');
	if (defined($disttag) && defined($distepoch)) {
		$$dist_r = "$disttag$distepoch";
	} else {
		# in the case of the old RPMs where there was no dash between revision and disttag, RPM methods will fail
		# resort to old meothds :-)
		if ($package =~ /-([^\-]+)-?((?:mnb2|(?:unity|plf|mdv|synergy|tmlinux|unity_plf)20(?:09|10|11|11\.0)))\.(.*)\.rpm$/) {
			$$rev_r = $1;
			$$dist_r = $2;
		} else {
			$$rev_r = undef;
			$$dist_r = undef;
		}
	}
	$$arch_r = _getRpmTagValue($header, 'ARCH');
	if ($$arch_r eq 'noarch') {
		my $pattern = $repopath . $path_separator . '([^/]+)' . $path_separator;
		if ($package =~ /$pattern/) {
			$$arch_r = $1 . $path_separator . $$arch_r;
		}
	}
	$$sourcerpm_r =_getRpmTagValue($header, 'SOURCERPM');

	$$sourcerpm_r =~ /^(.*)-$$ver_r-$$rev_r.*.src.rpm$/x;
	my $sibling_name = $1;

	if (!exists($sibling_id{$sibling_name})) {
		$sibling_id{$sibling_name} = $sibling_id{sibling_id_max}++;
	}
	$$sourcerpm_r = $sibling_id{$sibling_name};

	# treat 64-bit lib names as 32-bit lib names
	$$name_r = "lib$1" if ($$name_r =~ /^lib64(.*)/);

	return 1;
}

sub _getRpmTagValue {
	my $header = shift;
	my $tagname = shift;

	my $tagnumber = getvalue('rpmtag', $tagname);
	if ($header->hastag($tagnumber)) {
		return $header->tag($tagnumber);
	} else {
		return undef;
	}
}

sub FindSibsFor {
	my $name = $repopath . $path_separator . shift;
	my $r_foundsibs = shift;

	die "File $name does not exist\n" unless (-f $name);

	my ($rpmname, $ver, $rev, $dist, $arch, $sibling_id);
	return unless ParsePkgName($name, \$rpmname, \$ver, \$rev, \$dist, \$arch);
	foreach my $filename (keys %{${$packages{$rpmname}{$repo32}}[0]}) {
		$sibling_id = ${$packages{$rpmname}{$repo32}}[0]{$filename}{sibling};
	}
	unless (defined($sibling_id)) {
		foreach my $filename (keys %{${$packages{$rpmname}{$repo64}}[0]}) {
			$sibling_id = ${$packages{$rpmname}{$repo64}}[0]{$filename}{sibling};
		}
	}
	unless (defined($sibling_id)) {
		print Dumper(\$packages{$rpmname});
		exit;
	}

	my $ver_rev = $ver . '-' . $rev . '-' . $dist;
	my %version_id = ('version_id_max' => 1);
	$version_id{$ver_rev} = 0;

	foreach my $pkgname (keys %packages) {
		for my $repotype (($repo32, $repo64)) {
			foreach my $entry (@{$packages{$pkgname}{$repotype}}) {
				foreach my $filename (keys %{$entry}) {
					if ($$entry{$filename}{sibling} == $sibling_id) {
						print_package_details(\@{$packages{$pkgname}{$repotype}}, $pkgname, \%version_id, $r_foundsibs);
					}
				}
			}
		}
	}
}

