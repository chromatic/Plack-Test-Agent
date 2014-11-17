package Plack::Test::Agent;
# ABSTRACT: OO interface for testing low-level Plack/PSGI apps

use strict;
use warnings;

use Test::TCP;
use Plack::Loader;
use HTTP::Response;
use HTTP::Message::PSGI;
use HTTP::Request::Common;
use Scalar::Util qw( weaken );
use Test::WWW::Mechanize;

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

    my $ua     = $self->ua ? $self->ua : $self->ua( $self->get_mech );
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
    $self->server( weaken $server );
}

sub execute_request
{
    my ($self, $req) = @_;

    my $res = $self->server
            ? $self->ua->request( $req )
            : HTTP::Response->from_psgi( $self->app->( $req->to_psgi ) );

    $res->request( $req );
    return $res;
}

sub get
{
    my ($self, $uri) = @_;
    my $req          = GET $self->normalize_uri($uri);
    return $self->execute_request( $req );
}

sub post
{
    my ($self, $uri, @args) = @_;
    my $req                 = POST $self->normalize_uri($uri), @args;
    return $self->execute_request( $req );
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

sub get_mech
{
    my $self = shift;
    return Test::WWW::Mechanize::Bound->new(
        bound_uri => $self->normalize_uri( '/' )
    );
}

package
   Test::WWW::Mechanize::Bound;

    use parent 'Test::WWW::Mechanize';

    sub new
    {
        my ($class, %args) = @_;
        my $bound_uri      = delete $args{bound_uri};
        my $self           = $class->SUPER::new( %args );
        $self->bound_uri( $bound_uri );
        return $self;
    }

    sub bound_uri
    {
        my ($self, $base_uri) = @_;
        $self->_elem( bound_uri => $base_uri ) if @_ == 2;
        return $self->_elem( 'bound_uri' );
    }

    sub prepare_request
    {
        my $self  = shift;
        my ($req) = @_;
        my $uri   = $req->uri;
        my $base  = $self->bound_uri;

        unless ($uri->scheme)
        {
            $uri->scheme( $base->scheme );
            $uri->host( $base->host );
            $uri->port( $base->port );
        }
        return $self->SUPER::prepare_request( @_ );
    }

1;

__END__

=head2 SYNOPSIS

    use Test::More;
    use Plack::Test::Agent;

    my $app          = sub { ... };
    my $local_agent  = Plack::Test::Agent->new( app => $app );
    my $server_agent = Plack::Test::Agent->new(
                        app    => $app,
                        server => 'HTTP::Server::Simple' );

    my $local_res    = $local_agent->get( '/' );
    my $server_res   = $server_agent->get( '/' );

    ok $local_res->is_success,  'local GET / should succeed';
    ok $server_res->is_success, 'server GET / should succeed';

=head2 DESCRIPTION

C<Plack::Test::Agent> is an OO interface to test PSGI applications. It can
perform GET and POST requests against PSGI applications either in process or
over HTTP through a L<Plack::Handler> compatible backend.

B<NOTE:> This is an experimental module and its interface may change.

=head2 CONSTRUCTION

The C<new> constructor creates an instance of C<Plack::Test::Agent>. This
constructor takes one mandatory named argument and several optional arguments.

=over 4

=item * C<app> is the mandatory argument. You must provide a PSGI application
to test.

=item * C<server> is an optional argument. When provided, C<Plack::Test::Agent>
will attempt to start a PSGI handler and will communicate via HTTP to the
application running through the handler. See L<Plack::Loader> for details on
selecting the appropriate server.

=item * C<host> is an optional argument representing the name or IP address for
the server to use. The default is C<localhost>.

=item * C<port> is an optional argument representing the TCP port to for the
server to use. If not provided, the service will run on a randomly selected
available port outside of the IANA reserved range. (See L<Test::TCP> for
details on the selection of the port number.)

=item * C<ua> is an optional argument of something which conforms to the
L<LWP::UserAgent> interface such that it provides a C<request> method which
takes an L<HTTP::Request> object and returns an L<HTTP::Response> object. The
default is an instance of C<LWP::UserAgent>.

=back

=head2 METHODS

This class provides several useful methods:

=head3 C<get>

This method takes a URI and makes a C<GET> request against the PSGI application
with that URI. It returns an L<HTTP::Response> object representing the results
of that request.

=head3 C<post>

This method takes a URI and makes a C<POST> request against the PSGI
application with that URI. It returns an L<HTTP::Response> object representing
the results of that request. As an optional second parameter, pass an array
reference of key/value pairs for the form content:

    $agent->post( '/edit_user',
        [
            shoe_size => '10.5',
            eye_color => 'blue green',
            status    => 'twin',
        ]);

=head3 C<execute_request>

This method takes an L<HTTP::Request>, performs it against the bound app, and
returns an L<HTTP::Response>. This allows you to craft your own requests
directly.

=head2 CREDITS

Thanks to Zbigniew E<0x141>ukasiak and Tatsuhiko Miyagawa for suggestions.
