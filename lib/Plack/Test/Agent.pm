package Plack::Test::Agent;
# ABSTRACT: OO interface for testing low-level Plack/PSGI apps

use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;

use Plack::Util::Accessor qw( app );

sub new
{
    my ($class, %args) = @_;

    my $self = bless {}, $class;
    $self->app( delete $args{app} );

    return $self;
}

sub get
{
    my ($self, $uri) = @_;
    my $req          = HTTP::Request->new( GET => $uri );
    my $env          = $req->to_psgi;
    my $app          = $self->app;

    return HTTP::Response->from_psgi( $app->( $env ) );
}

1;
