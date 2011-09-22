package Plack::Test::Agent;
# ABSTRACT: OO interface for testing low-level Plack/PSGI apps

use strict;
use warnings;

use Test::TCP;
use Plack::Loader;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Message::PSGI;
use HTTP::Request::Common;

use Plack::Util::Accessor qw( app host port server ua );

sub new
{
    my ($class, %args) = @_;

    my $self = bless {}, $class;

    $self->app(  delete $args{app}  );
    $self->ua(   delete $args{ua}   );
    $self->host( delete $args{host} || 'localhost' );
    $self->port( delete $args{port} );

    $self->start_server( delete $args{server} ) if $args{server};

    return $self;
}

sub start_server
{
    my ($self, $server_class) = @_;

    my $ua     = $self->ua ? $self->ua : $self->ua( LWP::UserAgent->new );
    my $server = Test::TCP->new(
        code => sub
        {
            my $port = shift;
            $self->port( $port );
            Plack::Loader->auto( port => $port, host => $self->host )
                         ->run( $self->app );
        },
    );

    $self->port( $server->port );
    $self->server( $server );
}

sub execute_req
{
    my ($self, $req) = @_;

    return $self->ua->request( $req ) if $self->server;
    return HTTP::Response->from_psgi( $self->app->( $req->to_psgi ) );
}

sub get
{
    my ($self, $uri) = @_;
    my $req          = GET $self->normalize_uri($uri);
    my $res          = $self->execute_req( $req );

    $res->request( $req );
    return $res;
}

sub post
{
    my ($self, $uri, @args) = @_;
    my $req                 = POST $self->normalize_uri($uri), @args;
    my $res                 = $self->execute_req( $req );
    $res->request( $req );
    return $res;
}

sub normalize_uri
{
    my ($self, $uri) = @_;
    my $normalized   = URI->new( $uri );
    my $port         = $self->port;

    $normalized->scheme( 'http' )      unless $normalized->scheme;
    $normalized->host(   'localhost' ) unless $normalized->host;
    $normalized->port( $port )         if $port;

    return $normalized;
}

1;
