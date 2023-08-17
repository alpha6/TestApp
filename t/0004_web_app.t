#!/usr/bin/env perl
use lib 'lib';

use Mojo::Base -strict;

use Mojo::File qw(curfile);
use Test::Mojo;
use Test::More;

use TestApp::Db;

my $t = Test::Mojo->new(curfile->dirname->sibling('test-web'));

my $config = Mojolicious::Plugin::INIConfig->load('config.ini');

_initDB();

# Perform GET requests and look at the responses
subtest 'App is working' => sub {
    $t->get_ok('/')
        ->status_is(200)
        ->content_like(qr/Log search/);
};

subtest 'Accept valid email' => sub {
    $t->post_ok('/search' => form => { address => 'test@e.mail' })
        ->status_is(200)
        ->content_like(qr/Search results/);
};

subtest 'Validate empty email' => sub {
    $t->post_ok('/search' => form => {address => ''})
        ->status_is(400)
        ->content_like(qr/Request failed: Address is required/);
};

subtest 'Validate invalid email' => sub {
    $t->post_ok('/search' => form => { address => 'not_valid_address' })
        ->status_is(400)
        ->content_like(qr/Request failed: Address is invalid/);
};

subtest 'Set display results from config' => sub {
    my $app_config = Mojolicious::Plugin::INIConfig->load('config.ini');
    $app_config->{web}{display_results} = 1234;

    my $app = Test::Mojo->new(curfile->dirname->sibling('test-web'), $app_config);

    $app->post_ok('/search' => form => { address => 'test@e.mail' })
        ->status_is(200)
        ->content_like(qr/On page: 1234/);
};

done_testing();

sub _initDB
{
    my $model = TestApp::Db->new();
    $model->connect(%{$config->{db}});

    return 1;
}