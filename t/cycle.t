#!/usr/bin/env perl

use strict;
use warnings;

use Test::Requires 'Test::Memory::Cycle';

use Test::More;
use Plack::Test::Agent;
use Test::Memory::Cycle;

my $app = sub
{
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
};

my $agent = Plack::Test::Agent->new(
    app    => $app,
    server => 'HTTP::Server::PSGI',
);

memory_cycle_ok(
    $agent,
    'no memory cycles in the Plack::Test::Agent object'
);

done_testing;
