package Apache::Resource;

use strict;
use vars qw($Debug);
use BSD::Resource qw(setrlimit getrlimit get_rlimits);

$Debug ||= 0;
$Apache::Resource::VERSION = (qw$Revision$)[1];

sub MB ($) { 
    my $num = shift;
    if($num < (1024 * 1024)) {
	return $num*1024*1024;
    }
    $num;
}

sub DEFAULT_RLIMIT_DATA  () { 64 } #data (memory) size
sub DEFAULT_RLIMIT_CPU   () { 60*3 } #cpu time in milliseconds
sub DEFAULT_RLIMIT_CORE  () { 0  } #core file size
sub DEFAULT_RLIMIT_RSS   () { 16 } #resident set size
sub DEFAULT_RLIMIT_FSIZE () { 10 } #file size 
sub DEFAULT_RLIMIT_STACK () { 20 } #stack size

my %is_mb = map {$_,1} qw{DATA RSS STACK FSIZE};

sub debug { print STDERR @_ if $Debug }

sub install_rlimit ($$$) {
    my($res, $soft, $hard) = @_;

    my $name = $res;

    my $cv = \&{"BSD::Resource::RLIMIT_${res}"};
    eval { $res = $cv->() };
    return if $@;

    unless ($soft) { 
	my $defval = \&{"DEFAULT_RLIMIT_${name}"};
	if(defined &$defval) {
	    $soft = $defval->();
	}
	else {
	    warn "can't find default for `$defval'\n";
	}
    }

    $hard ||= $soft;

    debug "Apache::Resource: attempting to set `$name'=$soft:$hard ...";

    ($soft, $hard) = (MB $soft, MB $hard) if $is_mb{$name};

    return setrlimit $res, $soft, $hard;
}

sub handler {
    while(my($k,$v) = each %ENV) {
	next unless $k =~ /^PERL_RLIMIT_(\w+)$/;
	$k = $1;
	next if $k eq "DEFAULTS";
	my($soft, $hard) = split ":", $v, 2; 
	$hard ||= $soft;

	my $set = install_rlimit $k, $soft, $hard;
	debug "not " unless $set;
	debug "ok\n";
	debug $@ if $@;
    }

    0;
}

sub default_handler {
    while(my($k,$v) = each %Apache::Resource::) {
	next unless $k =~ s/^DEFAULT_/PERL_/;
	$ENV{$k} = "";
    }
    handler();
}

sub status_rlimit {
    my $lim = get_rlimits();
    my @retval = ("<table border=1><tr>", 
		  (map "<td><b>$_</b></td>", qw(Resource Soft Hard)),
		  "</tr>");

    for my $res (keys %$lim) {
	my $val = eval "&BSD::Resource::${res}()";
	push @retval, 
	"<tr>",
	(map { "<td>$_</td>" } $res, getrlimit $val),
	"</tr>";
    }

    push @retval, "</table>";

    return \@retval;
}

if($ENV{MOD_PERL}) {
    if($ENV{PERL_RLIMIT_DEFAULTS}) {
	Apache->push_handlers(PerlChildInitHandler => \&default_handler);
    }

    Apache::Status->menu_item(rlimit => "Resource Limits", 
			    \&status_rlimit)
      if Apache->module("Apache::Status");
}

#perl Apache/Resource.pm
++$Debug, default_handler unless caller();

1;

__END__

=pod

=head1 NAME

Apache::Resource - Limit resources used by httpd children

=head1 SYNOPSIS

 #set memory limit in megabytes
 #default is 64 Meg
 PerlSetEnv PERL_DATA_LIMIT 35

 #set cpu limit in milliseconds
 #default is 60 milliseconds
 PerlSetEnv PERL_RLIMIT_CPU 120

 PerlChildInitHandler Apache::Resource

=head1 DESCRIPTION

B<Apache::Resource> uses the B<BSD::Resource> module, which 
uses the C function C<setrlimit> to set limits on
system resources such as memory and cpu usage.

Any B<RLIMIT> operation available to limit on your system can be set
by defining that operation as an envrionment variable with a B<PERL_>
prefix.  If no value is set a reasonable default is used if defined.
See your system C<setrlimit> manpage for available resources which 
can be limited.
 
By default, C<PERL_RLIMIT_DATA> is set to 64 megabytes if it does
not exist in the current environment. 

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

BSD::Resource(3), setrlimit(2)

=cut
