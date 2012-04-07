use warnings;
use strict;
use LWP::UserAgent;
use HTTP::Request;
use Getopt::Long;

my $help = 0;
my $repo_base = '';
my $package = '';
my $newversion = '';
my $oldversion = '';

GetOptions(
    'help'          => \$help,
    'repobase=s'    => \$repo_base,
    'package=s'     => \$package,
    'newversion=s'  => \$newversion,
    'oldversion=s'  => \$oldversion,
);

$help = 1 unless ((-d $repo_base) && ($package ne '') && ($oldversion ne '') && ($newversion ne ''));
if ($help) {
    die "Usage: $0 --repobase=s --package=s --newversion=s --oldversion=s\n";
}

$package=$1 if ($package =~ /^perl-(.*)$/);

my $q=HTTP::Request->new(GET=>"http://search.cpan.org/dist/$package/");
my $ua=LWP::UserAgent->new;
my $r=$ua->request($q);
my $cpan_contents = $r->content();

unless ($cpan_contents =~ /<a href="(.*\/($package-$newversion)(.tar.gz))">/) {
    die "Could not extract CPAN download for $package-$newversion\n";
}
my $URL="http://search.cpan.org/$1";
my $filename=$2;
my $extension=$3;

chdir("$repo_base/perl-$package/S") || die "Cannot chdir: $!\n";
`wget $URL`;
`tar xzf $filename$extension`;
`tar cJf $filename.tar.xz $filename`;
`\\rm -rf $filename $filename$extension`;
`svn del $package-$oldversion.*`;
`svn add $filename.tar.xz`;

print "\nNow modify your $repo_base/perl-$package/F/perl-$package.spec file\n";


