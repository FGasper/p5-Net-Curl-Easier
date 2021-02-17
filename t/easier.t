package t::easier;

use strict;
use warnings;
use autodie;

use Test::More;
use Test::FailWarnings;

use parent 'Test::Class::Tiny';

use Socket;
use File::Temp;

use Net::Curl::Easier;

__PACKAGE__->new()->runtests() if ! caller;

sub SKIP_CLASS {
    return "No UNIX sockets available (OS = $^O)!" if !Socket->can('AF_UNIX');

    return;
}

sub _create_server {
    my ($end_re) = @_;

    die 'list!' if !wantarray;

    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $path = "$dir/sock";

    socket my $psock, AF_UNIX, SOCK_STREAM, 0;
    bind $psock, Socket::pack_sockaddr_un($path);
    listen $psock, 1;

    pipe my $pr, my $cw;

    my $pid = fork or do {
        close $pr;

        my $csock;
        accept $csock, $psock;
        close $psock;

        my $got = q<>;
        while ($got !~ $end_re) {
            read $csock, $got, 512, length $got;
        }

        close $csock;

        print {$cw} $got;
        close $cw;

        exit;
    };

    close $cw;

    return ($path, $pr, $pid);
}

sub T2_escape {
    my $str = "épée";

    utf8::downgrade($str);

    my $escaped1 = Net::Curl::Easier->new()->escape($str);

    ok($escaped1, 'escape() returns something');

    utf8::upgrade($str);

    my $escaped2 = Net::Curl::Easier->new()->escape($str);

    is( $escaped1, $escaped2, 'escape() doesn’t care about internals' );

    return;
}

sub T3_lotta_stuff {
    my $self = shift;

    my ($sockpath, $sent_pipe, $pid) = _create_server(qr<thepostdata\z>);

    my $easy = Net::Curl::Easier->new(
        UNIX_SOCKET_PATH => $sockpath,
    );

    my $url = "http://localhost/épée";
    utf8::upgrade($url);

    is(
        $easy->set( url => $url, copypostfields => 'thepostdata' ),
        $easy,
        'set() returns $easy',
    );

    my $hdr = "X-épée: épée";
    utf8::upgrade($hdr);

    is(
        $easy->push( httpheader => [$hdr, "X-¡hola: ¡hola"] ),
        $easy,
        'push() returns $easy',
    );

    $easy->pushopt(
        Net::Curl::Easy::CURLOPT_HTTPHEADER,
        [ utf8::upgrade( my $v = "X-Käse: Käse" ) ],
    );

    $easy->setopt(
        Net::Curl::Easy::CURLOPT_USERAGENT,
        utf8::upgrade( my $ua = "Très-Bien" ),
    );

    is( $easy->perform(), $easy, 'perform() returns the object' );

    my $sent = do { local $/; <$sent_pipe> };

    diag $sent;

    waitpid $pid, 0;

    return;
}

1;
