package TestApache::conftree;

use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestConfig ();
use Apache::Directive ();

sub handler {
    my $r = shift;

    my $cfg = Apache::TestConfig->thaw;
    plan $r, tests => 7;

    ok $cfg;

    my $vars = $cfg->{vars};

    ok $vars;


    my $tree = Apache::Directive->conftree;

    ok $tree;

    my $port = find_config_val($tree, 'Listen');

    ok $port;

    ok $port == $vars->{port};

    my $serverroot = find_config_val($tree, 'ServerRoot');

    ok $serverroot;

    ok $serverroot eq qq("$vars->{serverroot}");

    0;
}

sub find_config_val {
    my($tree, $directive) = @_;

    while ($tree) {
        if ($directive eq $tree->directive) {
            return $tree->args;
        }

        if (my $kid = $tree->first_child) {
            $tree = $kid;
        } elsif (my $next = $tree->next) {
            $tree = $next;
        }
        else {
            if (my $parent = $tree->parent) {
                $tree = $parent->next;
            }
            else {
                $tree = undef;
            }
        }
    }
}

1;
