use warnings;
use strict;

my $unity_mirrors = '/home/mdawkins/src/unity-linux/packages/smart-channels-unity/S/mirror.list';
my $countries_list = '/home/mdawkins/src/unity-linux/projects/mirmon/countries.list';

open(COUNTRIES, $countries_list) || die "Can't open $countries_list for reading: $!\n";
my %countries;
while(<COUNTRIES>) {
	chomp;
	next if (/^#/);
	/^(..) (.*)$/;
	$countries{$2} = $1;
}
close(COUNTRIES);

open(IN_MIR, $unity_mirrors) || die "Can't open $unity_mirrors for reading: $!\n";
while(<IN_MIR>) {
	chomp;
	my ($label, $country, $continents, $url) = split(/\|/);
	$url .= '/' unless /\/$/;
	print $countries{lc($country)} . " $url\n";
}
close(IN_MIR);
