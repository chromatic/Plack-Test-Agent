# NAME

Plack::Test::Agent - OO interface for testing low-level Plack/PSGI apps

# VERSION

version 1.3

## SYNOPSIS

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

## DESCRIPTION

`Plack::Test::Agent` is an OO interface to test PSGI applications. It can
perform GET and POST requests against PSGI applications either in process or
over HTTP through a [Plack::Handler](https://metacpan.org/pod/Plack::Handler) compatible backend.

**NOTE:** This is an experimental module and its interface may change.

## CONSTRUCTION

The `new` constructor creates an instance of `Plack::Test::Agent`. This
constructor takes one mandatory named argument and several optional arguments.

- `app` is the mandatory argument. You must provide a PSGI application
to test.
- `server` is an optional argument. When provided, `Plack::Test::Agent`
will attempt to start a PSGI handler and will communicate via HTTP to the
application running through the handler. See [Plack::Loader](https://metacpan.org/pod/Plack::Loader) for details on
selecting the appropriate server.
- `host` is an optional argument representing the name or IP address for
the server to use. The default is `localhost`.
- `port` is an optional argument representing the TCP port to for the
server to use. If not provided, the service will run on a randomly selected
available port outside of the IANA reserved range. (See [Test::TCP](https://metacpan.org/pod/Test::TCP) for
details on the selection of the port number.)
- `ua` is an optional argument of something which conforms to the
[LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent) interface such that it provides a `request` method which
takes an [HTTP::Request](https://metacpan.org/pod/HTTP::Request) object and returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object. The
default is an instance of `LWP::UserAgent`.

## METHODS

This class provides several useful methods:

### `get`

This method takes a URI and makes a `GET` request against the PSGI application
with that URI. It returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object representing the results
of that request.

Any arguments you pass after the URI will be sent to the HTTP request constructor untouched.

### `post`

This method takes a URI and makes a `POST` request against the PSGI
application with that URI. It returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response) object representing
the results of that request. As an optional second parameter, pass an array
reference of key/value pairs for the form content:

    $agent->post( '/edit_user',
        [
            shoe_size => '10.5',
            eye_color => 'blue green',
            status    => 'twin',
        ]);

### `execute_request`

This method takes an [HTTP::Request](https://metacpan.org/pod/HTTP::Request), performs it against the bound app, and
returns an [HTTP::Response](https://metacpan.org/pod/HTTP::Response). This allows you to craft your own requests
directly.

## CREDITS

Thanks to Zbigniew Łukasiak and Tatsuhiko Miyagawa for suggestions.

# AUTHORS

- chromatic <chromatic@wgz.org>
- Dave Rolsky <autarch@urth.org>

# CONTRIBUTOR

Dave Rolsky <drolsky@maxmind.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2014 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
