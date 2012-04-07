use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use Net::FTP;
use Getopt::Long;
use Data::Dumper;
use version;

local $| = 1; # turn on autoflushing of output
my $help = 0;
my $repo_base = "";
my $list = "";
my $only = "";
my $save = ".";
my $restart = 0;
my $default_ver = '0.0.0.0';

GetOptions(
    'help!'      => \$help,
    'repobase=s' => \$repo_base,
    'list=s'     => \$list,
    'only=s'     => \$only,
    'save:s'     => \$save,
    'restart!'   => \$restart,
);

$help = 1 unless (-d $repo_base);
$help = 1 if (($list ne '') && ($only ne ''));

if ($help) {
    print "Usage: $0 <--repobase=s> [options]\n";
    print "Valid options are:\n";
    print "   --help     Print this message and exit.\n";
    print "   --list=s   Run script only on the packages listed in the specified file. Cannot be used with --only.\n";
    print "   --only=s   Run script only on the packages specified here. Cannot be used with --list.\n";
    print "   --save=s   Directory where to save the 'save file'.\n";
    print "  --restart   Restart, overwriting the contents of 'save file'.\n";
    
    exit;
}

$SIG{INT} = sub {
	close(SAVE);
	exit;
};

# build the list of processed packages
my @processed = ();
my $savefile = "$save/.$0.progress";
if ($restart) {
	open (SAVE, ">$savefile") || die "Cannot create a save file: $!\n";
} else {
	if (-f $savefile) {
		open (SAVE, "$savefile") || die "Cannot open save file for reading: $!\n";
		foreach (<SAVE>) {
			chomp;
			push @processed, $1 if (/. (.*)/);
		}
		close(SAVE);
	}
	open (SAVE, ">>$savefile") || die "Cannot create a save file: $!\n";
}

# build a list of SPEC files to analyze. This could be from a --list option or all spec file in SVN
my @list = ();
if (($list ne '') && (-f $list)) {
    open(LIST, $list) || die "Can't open $list for reading:$!\n";
    foreach(<LIST>) {
        chomp;
        push @list, "$repo_base/$_/F/$_.spec";
    }
    close(LIST);
} elsif ($only ne '') {
    foreach(split(/,/,$only)) {
        push @list, "$repo_base/$_/F/$_.spec";
    }
} else {
    @list = glob("$repo_base/*/F/*.spec");
}
die "Nothing to do: Empty list of packages. Exiting.\n" unless scalar(@list);

# go through the requested list of SPEC files and do the analsys
foreach my $spec (@list) {
	$spec =~ /F\/(.*)\.spec$/;
	my $package = $1;
	
	if (!$restart) {
		next if (grep(/$package/, @processed));
	}
    if (-f $spec) {
		my ($spec_version, $remote_version, $result);
    	my $status = ProcessSpecFile($spec, \$spec_version, \$remote_version);
		if ($status) {$result = 'S'} else {$result = 'F'}
		$result .= " $package";
		$result .= " $spec_version $remote_version" if $status;
		print SAVE "$result\n";
    }
}
close(SAVE);
exit;

sub ProcessSpecFile
{
    my $spec = shift;
	my $spec_ver =shift;
	my $remote_ver = shift;
    my %spec_info;
    my %remote_info;
    my $verbose = 0;
    $remote_info{package_version} = $default_ver;

    print "\nProcessing $spec\n" if $verbose;
    
    parse_spec($spec, \%spec_info);
    my $status = check_version_by_source(\%spec_info, \%remote_info);
    if ($status == 0) {
        $status = check_version_by_url(\%spec_info, \%remote_info);
    }

    $$spec_ver = $spec_info{spec_version};
    $$remote_ver = $remote_info{package_version};

    if (($status == 0) || ($$remote_ver eq $default_ver)) {
        print "$spec: Could not extract remote package version.\n";
        return 0;
    } else {
        print "$spec: specfile=$$spec_ver and remote=$$remote_ver\n";
        return 1;
    }
}

sub parse_spec {
    my $spec = shift;
    my $info = shift;
    my $verbose = 0;
    
    open(SPEC, $spec) || die "Can't open $spec for reading: $!\n";
    
    my %defines = ('mklibname' => '',
                   'mkrel' => '',
                   'perl_convert_version' => '',
		   'nil' => '',
		   'name' => '', # this is temporary until the SPEC file is parsed
           'major' => '',  # temporary
           'version' => '',  # temporary
    );
    my $spec_version;
    while(<SPEC>) {
        if (/^\%define\s+(\S+)\s+(.*)$/) {
            print "\n   ### Processing $_" if $verbose;
            $defines{$1} = cleanup_macros($2, \%defines);
            print "found new define. Currently all defines are:\n" if $verbose;
            print Dumper(\%defines) if $verbose;
            next;
        }
        elsif (/^[Vv]ersion:\s+(.+)$/) {
            print "\nProcessing Version definition from '$1'\n" if $verbose;
            $spec_version = cleanup_macros($1, \%defines);
            $spec_version =~ s/\s//g;
            $$info{spec_version} = $spec_version;
            $defines{version} = $spec_version;
        }
        elsif (/^[Uu]rl:\s+(.+)$/i) {
            print "\nProcessing URL definition from '$1'\n" if $verbose;
            $$info{url} = cleanup_macros($1, \%defines);
            $defines{url} = $$info{url};
        }
        elsif (/^name:\s+(.+)$/i) {
            print "\nProcessing Name definition from '$1'\n" if $verbose;
            $defines{name} = cleanup_macros($1, \%defines);
            $$info{name} = $defines{name};
        }
        elsif (/^source0?:\s+(.+)$/i) {
            print "\nProcessing Source definition from '$1'\n" if $verbose;
            $$info{source} = cleanup_macros($1, \%defines);
        }
    }
    
    close(SPEC);
}

sub cleanup_macros {
    my $name = shift;
    my $ref_defines = shift;
    my $verbose = 0;
    
    chomp $name;
    
    if ($verbose) {
        print "Defines are: \n";
        print Dumper($ref_defines);
        print "\n";
    }
        
    while ($name =~ /(\%\{?([a-zA-Z_0-9]+)\}?)/) {
        my $macro = $1;
        my $macro_name = $2;
        
        print "  ### name = $name and 1='$macro', 2='$macro_name'\n" if $verbose;
        if (!exists($$ref_defines{$macro_name})) {
            # let's cheat and spit out (possibly) useless info
            my $output = `rpm -E$name 2>/dev/null`;
            $output =~ s/\%//g;
            return $output;
        }
        $name =~ s/$macro\s*/$$ref_defines{$macro_name}/g;
    }
    print "  ### final name = '$name'\n" if $verbose;
    return $name;
}

sub check_version_by_source {
    my $spec = shift;
    my $remote_info = shift;
    my $verbose = 0;
    
    # all perl packages have the annoying perl- prefix. Let's get rid of it
    my $non_perl_spec_name = $$spec{name};
    $non_perl_spec_name = $1 if ($non_perl_spec_name =~ /perl-(.*)/);
    
    if ($$spec{source} =~ /^(http:.*)\/([^\/]+)$/) {
        $$remote_info{http_dir} = $1;
        $$remote_info{package_name} = $2;
        
        my $contents;
        my $status = 0;
        return $status unless GetHTML($$remote_info{http_dir}, \$contents);
        
        foreach (split(/\n/,$contents)) {
            if (/href=".*?$non_perl_spec_name[\-\_](\S+?)"/i) {
                my $partial_link = $1;
                print "Found partial_link='$partial_link'\n" if $verbose;
                $status |= UpdatePackageVersion($remote_info, $partial_link);
            }
        }

        if ($status == 0) {
            # if we have failed so far and the project is from sourceforge, try to get info from there
            if ($$spec{source} =~ /sourceforge\.net/) {
                $status = check_sourceforge_version($$spec{name}, $remote_info);
            }
        }
        
        return $status;
    }
    elsif ($$spec{source} =~ /^ftp:\/\/([^\/]+)\/(.*)\/(.*)$/) {
        $$remote_info{ftp_host} = $1;
        $$remote_info{ftp_dir} = $2;
        $$remote_info{package_name} = $3;
        
        my $ftp = Net::FTP->new($$remote_info{ftp_host}, Debug => 0, Timeout => 10);
        if (!$ftp) { print "Cannot connect to $$remote_info{ftp_host}: $@\n"; return 0; }
        if (!$ftp->login('anonymous','anon@qwerty.com')) { print "Cannot login:" . $ftp->message; return 0; }
        if (!$ftp->cwd($$remote_info{ftp_dir})) { print "Cannot change working directory to $$remote_info{ftp_dir}: " . $ftp->message; return 0; }
        my @contents = $ftp->ls();
        if (!scalar(@contents)) { print "Cannot get directory listing: " . $ftp->message; return 0; }
        $ftp->quit;
        
        my $status = 0;
        foreach (@contents) {
            if (/$non_perl_spec_name[\-\_](.*)/) {
                print "Extracted package version='$1'\n" if $verbose;
                $status |= UpdatePackageVersion($remote_info, $1);
            }
        }
        
        return $status;
    }
    else {
        return 0;
    }
}

sub check_version_by_url {
    my $spec = shift;
    my $remote_info = shift;
    my $verbose = 0;
    my $status = 0;
    
    # all perl packages have the annoying perl- prefix. Let's get rid of it
    my $non_perl_spec_name = $$spec{name};
    $non_perl_spec_name = $1 if ($non_perl_spec_name =~ /perl-(.*)/);
    
    if ($$spec{url} =~ /sourceforge\.net/) {
        $status = check_sourceforge_version($$spec{name}, $remote_info);
    }
    
    if ($status == 0) {
        if ($$spec{url} =~ /^http:/) {
            my $contents;
            return $status unless GetHTML($$spec{url}, \$contents);
            
            foreach (split(/\n/,$contents)) {
                if (/href=".*?$non_perl_spec_name[\-\_](\S+?)"/i) {
                    my $partial_link = $1;
                    print "Found partial_link='$partial_link'\n" if $verbose;
                    $status |= UpdatePackageVersion($remote_info, $partial_link);
                }
            }
        } elsif ($$spec{url} =~ /^ftp:/) {
            ;
        } else {
            ;
        }
    }
    
    return $status;
}

sub check_sourceforge_version {
    my $name = shift;
    my $remote_info = shift;
    
    my $status = 0;
    my $contents;
    return $status unless GetHTML("http://sourceforge.net/projects/$name/files/", \$contents);
    foreach (split(/\n/,$contents)) {
        if (/\>$name-(.*\.(?:tar.*|zip|tgz|lzma|7zip))\</) {
            $status |= UpdatePackageVersion($remote_info, $1);
        }
    }
    return $status;
}

sub UpdatePackageVersion {
    my $remote_info = shift;
    my $newver = shift; # remaining leftover name, version, suffix, and extension
    my $status = 0;
    my $verbose = 0;
    
    print "UpdatePackageVersion: looking into $newver\n" if $verbose;
    
    if ($newver =~ /(\w+-)?(.+?)(-.*)?\.(?:tar.*|zip|tgz|lzma|7zip)$/) {
        my $prefix = $1;
        
        # we don't do prefixes in version because they usually come out to be leftover parts of the package name itself (i.e. gimp-1.2.3 and gimp-help-1.2.3)
        if (defined $prefix) {
            print "  Exiting because prefix ix '$prefix'\n" if $verbose;
            return $status;
        }
        my $ver = $2;
        my $suffix = $3;
        if ((defined $suffix) && ($suffix =~ /\D/)) {
            $ver .= $suffix;
        }
        if ($ver =~ /(\D*)((?:\d+\.?)+)(\D*)/) {
            my $ver_pre = $1;
            my $ver_extracted = $2;
            my $ver_post = $3;
            my $ver_formatted = version->new("v$ver_extracted");
            
            $$remote_info{package_version} =~ /(\D*)((?:\d+\.?)+)(\D*)/;
            my $remote_pre = $1;
            my $remote_extracted = $2;
            my $remote_post = $3;
            my $remote_formatted = version->new("v$remote_extracted");
            
            print "  Comparing current='$ver_formatted' to remote='$remote_formatted'. Actual remote='$$remote_info{package_version}'\n" if $verbose;
            
            if ($remote_formatted < $ver_formatted) {
                $$remote_info{package_version} = $ver;
                $status = 1;
            } elsif ($remote_formatted == $ver_formatted) {    
                if ($remote_post le $ver_post) {
                    $$remote_info{package_version} = $ver;
                    $status = 1;
                }
            }
        }
    }
    
    return $status;
}

sub GetHTML {
    my $url = shift;
    my $r_contents = shift;
    
    my $q=HTTP::Request->new(GET=>$url);
    my $ua=LWP::UserAgent->new;
    $ua->timeout(10);
    my $r=$ua->request($q);
    return 0 unless $r->is_success;
    $$r_contents = $r->content();
    return 1;
}
