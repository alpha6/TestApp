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
        ->content_like(qr/On page limit: 1234/);
};

subtest 'Find all records by address' => sub {
    $t->post_ok('/search' => form => { address => 'user@e.mail' })
        ->status_is(200)
        ->content_like(qr/On page limit: 100/)
        ->content_like(qr/Total results: 2/);

    my $app_config = Mojolicious::Plugin::INIConfig->load('config.ini');
    $app_config->{web}{display_results} = 1;

    my $app = Test::Mojo->new(curfile->dirname->sibling('test-web'), $app_config);

    $app->post_ok('/search' => form => { address => 'user@another.mail' })
        ->status_is(200)
        ->content_like(qr/On page limit: 1/)
        ->content_like(qr/Total results: 3/);
};

done_testing();

sub _initDB
{
    my $model = TestApp::Db->new();
    $model->connect(%{$config->{db}});

    my $dbh = $model->getDbh();

    $dbh->do('TRUNCATE TABLE `message`');
    $dbh->do('TRUNCATE TABLE `log`');

    $model->save_message_record({
        created => '2023-01-01 02:03:04',
        id      => 'record_1_id',
        int_id  => 'record_1_int_id',
        str     => 'message record 1 str',
    });

    $model->save_message_record({
        created => '2023-01-01 02:03:05',
        id      => 'record_2_id',
        int_id  => 'record_2_int_id',
        str     => 'message record 2 str',
    });

    $model->save_log_record({
        created => '2023-01-01 02:03:04',
        int_id  => 'record_1_int_id',
        str     => 'log record 1 str',
        address => 'user@e.mail',
    });

    $model->save_log_record({
        created => '2023-01-01 02:03:05',
        int_id  => 'record_2_int_id',
        str     => 'log record 2 str',
        address => 'user@another.mail',
    });

    $model->save_log_record({
        created => '2023-01-01 02:03:05',
        int_id  => 'record_2_int_id',
        str     => 'log record 2 str 2',
        address => '',
    });

    return 1;
}