package TestProtocol::pseudo_http;

# this is a more advanced protocol implementation. While using a
# simplistic socket communication, the protocol uses an almost
# complete HTTP AAA (access and authentication, but not authorization,
# which can be easily added) provided by mod_auth (but can be
# implemented in perl too)
#
# see the protocols.pod document for the explanations of the code

use strict;
use warnings FATAL => 'all';

use Apache::Connection ();
use Apache::RequestUtil ();
use Apache::HookRun ();
use Apache::Access ();
use APR::Socket ();

use Apache::Const -compile => qw(OK DONE DECLINED);

my @cmds = qw(date quit);
my %commands = map { $_, \&{$_} } @cmds;

sub handler {
    my $c = shift;
    my $socket = $c->client_socket;

    if ((my $rc = greet($c)) != Apache::OK) {
        $socket->send("Say HELO first\n");
        return $rc;
    }

    if ((my $rc = login($c)) != Apache::OK) {
        $socket->send("Access Denied\n");
        return $rc;
    }

    $socket->send("Welcome to " . __PACKAGE__ .
                  "\nAvailable commands: @cmds\n");

    while (1) {
        my $cmd;
        next unless $cmd = getline($socket);

        if (my $sub = $commands{$cmd}) {
            last unless $sub->($socket) == Apache::OK;
        }
        else {
            $socket->send("Commands: @cmds\n");
        }
    }

    return Apache::OK;
}

sub greet {
    my $c = shift;
    my $socket = $c->client_socket;

    $socket->send("HELO\n");
    my $reply = getline($socket) || '';

    return $reply eq 'HELO' ?  Apache::OK : Apache::DECLINED;
}

sub login {
    my $c = shift;

    my $r = Apache::RequestRec->new($c);
    $r->location_merge(__PACKAGE__);

    for my $method (qw(run_access_checker run_check_user_id
                       run_auth_checker)) {

        my $rc = $r->$method();

        if ($rc != Apache::OK and $rc != Apache::DECLINED) {
            return $rc;
        }

        last unless $r->some_auth_required;

        unless ($r->user) {
            my $socket = $c->client_socket;

            my $username = prompt($socket, "Login");
            my $password = prompt($socket, "Password");

            $r->set_basic_credentials($username, $password);
        }
    }

    return Apache::OK;
}

sub getline {
    my $socket = shift;

    my $line;
    $socket->recv($line, 1024);
    return unless $line;
    $line =~ s/[\r\n]*$//;

    return $line;
}

sub prompt {
    my($socket, $msg) = @_;

    $socket->send("$msg:\n");
    getline($socket);
}

sub date {
    my $socket = shift;

    $socket->send("The time is: " . scalar(localtime) . "\n");

    return Apache::OK;
}

sub quit {
    my $socket = shift;

    $socket->send("Goodbye\n");

    return Apache::DONE
}

1;
__END__
<NoAutoConfig>
  <VirtualHost TestProtocol::pseudo_http>

    PerlProcessConnectionHandler TestProtocol::pseudo_http

    <Location TestProtocol::pseudo_http>
        <IfModule mod_access.c>
            Order Deny,Allow
            Allow from @servername@
            Require user stas
            Satisfy any
            # htpasswd -bc basic-auth stas foobar
            AuthUserFile @ServerRoot@/htdocs/protocols/basic-auth
        </IfModule>
    </Location>

  </VirtualHost>
</NoAutoConfig>
