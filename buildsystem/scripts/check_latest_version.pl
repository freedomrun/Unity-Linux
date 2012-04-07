use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;
use Data::Dumper;
use version;
use DBI();

my $help = 0;
my $do_perl = 0;
my $do_mandy = 0;
my $do_gnome = 0;
my $repo_base = "";
my $altrepo_base = "";
my $repo_dir = "";
my $db = 0;
my $type = '';

GetOptions(
	'help'          => \$help,
	'perl!'         => \$do_perl,
	'mandy!'        => \$do_mandy,
	'gnome!'        => \$do_gnome,
	'svnbase=s'     => \$repo_base,
	'altsvnbase=s'  => \$altrepo_base,
	'repodir=s'     => \$repo_dir,
	'db!'           => \$db,
);

$help = 1 unless (-d $repo_base && -d $altrepo_base && -d $repo_dir);

if ($help) {
	die "Usage: $0 <--repodir=s> <--svnbase=s> <--altsvnbase=s> [--perl] [--mandy] [--gnome] [--db]\n";
}

chdir($repo_base) || die "Cannot chdir to $repo_base: $!\n";

if ($do_perl) {
	$type = 'perl';

	unless ($db) {
		print "==================================================\n";
		print "            Analyzing Perl modules                \n";
		print "==================================================\n";
	}
	
	foreach my $d (<*>) {
		next unless -d $d;
		next unless ($d =~ /^perl-(.*)/);

		my $perl_module_name = $1;
		my %pkg_info = ('pkgname' => $d, 'localver' => 'unknown', 'remotever' => 'unknown', 'smartver' => 'unknown', 'arch' => 'unknown');

		# get the remote info
		my $q=HTTP::Request->new(GET=>"http://search.cpan.org/dist/$perl_module_name/");
		my $ua=LWP::UserAgent->new;
		my $r=$ua->request($q);
		my $cpan_contents = $r->content();
	
		if ($cpan_contents =~ /$perl_module_name-(\S+)\<\/td\>/) {
			$pkg_info{remotever} = `rpm -E'%perl_convert_version $1'`;
			chomp($pkg_info{remotever});
		}

		# get smart info
		$pkg_info{smartver} = get_repo_info($d);
	
		# get the local info
		my $specfile = "$d/F/$d.spec";
		unless (-f $specfile) {
			$specfile = "$altrepo_base/$d/current/SPECS/$d.spec";
			unless (-f $specfile) {
				print_pkg_info(\%pkg_info);
				next;
			}
		}
        
        my %spec_info;
        parse_spec($specfile, \%spec_info);
		$pkg_info{localver} = $spec_info{version};
		$pkg_info{arch} = $spec_info{arch};
		
		# print out the results
		print_pkg_info(\%pkg_info);
	}
}

if ($do_mandy) {
	$type = 'mandy';

	unless ($db) {
		print "==================================================\n";
		print "        Analyzing Mandriva Cooker Packages        \n";
		print "==================================================\n";
	}
	
	my @draklist = qw(ldetect drak3d drakconf draklive-install drakx-installer-binaries drakx-net drakbackup drakfax drakwizard drakx-kbd-mouse-x11 drakxtools ldetect-lst rpm-mandriva-setup rpm-manbo-setup rpm-helper spec-helper);

	my $q=HTTP::Request->new(GET=>"http://mirrors.kernel.org/mandrake/Mandrakelinux/devel/cooker/SRPMS/main/release/");
	my $ua=LWP::UserAgent->new;
	my $r=$ua->request($q);
	my $mdv_contents = $r->content();
	
	foreach my $d (@draklist) {
		my %pkg_info = ('pkgname' => $d, 'localver' => 'unknown', 'remotever' => 'unknown', 'smartver' => 'unknown', 'arch' => 'unknown');
		
		# get smart info
		$pkg_info{smartver} = get_repo_info($d);

		# get the local info
		my $specfile = "$d/F/$d.spec";
		unless (-f $specfile) {
			$specfile = "$altrepo_base/$d/current/SPECS/$d.spec";
			unless (-f $specfile) {
				print_pkg_info(\%pkg_info);
				next;
			}
		}

		my %spec_info;
        parse_spec($specfile, \%spec_info);
		$pkg_info{localver} = $spec_info{version};
		$pkg_info{arch} = $spec_info{arch};

		# parse the remote info
		unless ($mdv_contents =~ /$d-([^\-]+)-\d+\S+\.src\.rpm/) {
			print_pkg_info(\%pkg_info);
			next;
		}
		$pkg_info{remotever} = $1;

		# print out the results
		print_pkg_info(\%pkg_info);
	}
}

if ($do_gnome) {
	$type = 'gnome';

	unless ($db) {
		print "==================================================\n";
		print "         Analyzing Gnome packages                 \n";
		print "==================================================\n";
	}

	my $baseurl = "http://ftp.acc.umu.se/pub/GNOME/sources/";
	my $q=HTTP::Request->new(GET=>$baseurl);
	my $ua=LWP::UserAgent->new;
	my $r=$ua->request($q);
	my $contents = $r->content();

	foreach (split(/\n/,$contents)) {
		if (/^\<a href="(\S+?)\/"\>/) {
			my $package = $1;
			my %pkg_info = ('pkgname' => $package, 'localver' => 'unknown', 'remotever' => 'unknown', 'smartver' => 'unknown', 'arch' => 'unknown');

			# get the remote version
			$q=HTTP::Request->new(GET=>"$baseurl/$package/");
			$r=$ua->request($q);
			$contents = $r->content();

			my $g_version = version->new("v0.0.0");
			foreach (split(/\n/,$contents)) {
				if (/^\<a href="(\S+?)\/"\>/) {
					$g_version = version->parse("v$1") if ($g_version < version->parse("v$1") );
				}
			}
			$g_version =~ s/^v//;

			$q=HTTP::Request->new(GET=>"$baseurl/$package/$g_version/");
			$r=$ua->request($q);
			$contents = $r->content();
			foreach (split(/\n/,$contents)) {
				if (/^\<a href="LATEST-IS-(\S+?)"\>/) {
					$g_version = $1;
					last;
				}
			}
			
			$pkg_info{remotever} = $g_version;

			# get smart info
			$pkg_info{smartver} = get_repo_info($package);

			# get the local info
			my $specfile = "$package/F/$package.spec";
			unless (-f $specfile) {
				$specfile = "$altrepo_base/$package/current/SPECS/$package.spec";
				unless (-f $specfile) {
					print_pkg_info(\%pkg_info);
					next;
				}
			}

			my %spec_info;
			parse_spec($specfile, \%spec_info);
			$pkg_info{localver} = $spec_info{version};
			$pkg_info{arch} = $spec_info{arch};

			#print out the info
			print_pkg_info(\%pkg_info);
		}
	}
}

sub parse_spec {
    my $spec = shift;
    my $info = shift;

	$$info{name} = `rpm -q --specfile --qf '%{name}\n' $spec 2> /dev/null | head -1`;
	$$info{version} = `rpm -q --specfile --qf '%{version}\n' $spec 2> /dev/null | head -1`;
	$$info{arch} = `rpm -q --specfile --qf '%{arch}\n' $spec 2> /dev/null | head -1`;

	chomp($$info{$_}) foreach (keys(%$info));
}

sub get_repo_info {
	my $pkg = shift;

	my $out = `find $repo_dir -name '$pkg-[0-9]*' | head -1`;
	if ($out =~ /$pkg-([^\-]+)-/) {
		return $1;
	}
	return 'unknown';
}

my $dbh = undef;
sub print_pkg_info {
	my $info = shift;

	if ($db) {
		if (!defined($dbh)) {
			$dbh = DBI->connect("DBI:mysql:database=BS;host=localhost", 'update_pkgs', 'update_pkgs', {'RaiseError' => 1});
			$dbh->do("DELETE FROM pkg_perl_mdv_gnome WHERE type='$type'");
		}

		$dbh->do("INSERT INTO pkg_perl_mdv_gnome (pkg_name, localsvn, localrepo, remote, arch, type) VALUES ('$$info{pkgname}', '$$info{localver}', '$$info{smartver}', '$$info{remotever}', '$$info{arch}', '$type')");
	} else {
		print "$$info{pkgname}:$$info{remotever}:$$info{localver}:$$info{smartver}:$$info{arch}\n";
	}
}
