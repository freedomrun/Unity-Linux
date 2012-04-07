use warnings;
use strict;
use RPM::Header;
use RPM::Constant;

die "Usage: $0 /path/to/file.rpm [tag] [tag] ..." unless -f $ARGV[0];

my $hdr = rpm2header($ARGV[0]);

if (scalar(@ARGV) > 1) {
	for (1 .. scalar(@ARGV)-1) {
		my $value = _getRpmTagValue($hdr, $ARGV[$_]);
		defined $value ? print "$value\n" : print "Unknown\n";
	}
} else {
	foreach my $context (listallcontext()) {
		foreach my $tag (listcontext($context)) {
			my $value = _getRpmTagValue($hdr, $tag);
			next unless defined $value;
			$value =~ s/[^[:print:]]/ /g;
			print "$context.$tag: $value\n";
		}
	}
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

