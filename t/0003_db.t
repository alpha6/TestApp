#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Test::More;
use Test::Exception;
use Test::MonkeyMock;

use TestApp::Db;


new_ok( 'TestApp::Db' );

subtest 'check required fields on connect' => sub {
    my $model = _buildModel();

    for my $key (qw/host user password database/) {
        my %params = _getTestConfig();

        delete $params{$key};

        throws_ok { $model->connect(%params)} qr/Field '${key}' is required/, "throws on no ${key}";
    }
};

subtest 'call _buildDbh with params' => sub {
    my $model = _buildModel();

    $model->connect(_getTestConfig());

    my $expected_params = {
        database => 'database',
        host     => 'host',
        port     => 3307,
        user     => 'login',
        password => 'password',
    };

    my (%params) = $model->mocked_call_args('_buildDbh');

    is_deeply($expected_params, \%params, 'Call _buildDbh with valid params');
};

subtest 'check required fields on save message' => sub {
    my $model = _buildModel();

    for my $key (qw/created id int_id str/) {
        my $record = {
            created => '2023-01-01 02:03:04',
            id      => 'record_id',
            int_id  => 'record_int_id',
            str     => 'record str',
        };

        delete $record->{$key};

        throws_ok { $model->save_message_record($record)} qr/Field '${key}' is required/, "throws on no ${key}";
    }
};

subtest 'call dbh with params on save message' => sub {
    my $record = {
        created => '2023-01-01 02:03:04',
        id      => 'record_id',
        int_id  => 'record_int_id',
        str     => 'record str',
    };

    my $dbh_mock = _buildDbhMock();

    my $model = _buildModel(dbh_mock => $dbh_mock);

    $model->connect(database => 'database', host => 'host', user => 'user', password => 'password');
    $model->save_message_record($record);

    my (@args) = $dbh_mock->mocked_call_args('do');

    my @expected_values = ('2023-01-01 02:03:04', 'record_id', 'record_int_id', 'record str');

    my $query = shift(@args);
    shift @args;

    ok(q{INSERT INTO `messages` (`created`, `id`, `int_id`, `str`) values (?,?,?,?)} eq $query, 'Check correct query');

    is_deeply(\@expected_values, \@args, 'Check correct values');
};

subtest 'check required fields on save log' => sub {
    my $model = _buildModel();

    for my $key (qw/created int_id/) {
        my $record = {
            created => '2023-01-01 02:03:04',
            int_id  => 'record_int_id',
        };

        delete $record->{$key};

        throws_ok { $model->save_log_record($record)} qr/Field '${key}' is required/, "throws on no ${key}";
    }
};

subtest 'call dbh with params on save log' => sub {
    my $record = {
        created => '2023-01-01 02:03:04',
        id      => 'record_id',
        int_id  => 'record_int_id',
        str     => 'log record str',
        address => 'user@e.mail',
    };

    my $dbh_mock = _buildDbhMock();

    my $model = _buildModel(dbh_mock => $dbh_mock);

    $model->connect(database => 'database', host => 'host', user => 'user', password => 'password');
    $model->save_log_record($record);

    my (@args) = $dbh_mock->mocked_call_args('do');

    my @expected_values = ('2023-01-01 02:03:04', 'record_id', 'record_int_id', 'log record str');

    my $query = shift(@args);
    shift @args;

    ok(q{INSERT INTO `messages` (`created`, `id`, `int_id`, `str`) values (?,?,?,?)} eq $query, 'Check correct query');

    is_deeply(\@expected_values, \@args, 'Check correct values');
};

done_testing();

sub _buildDbhMock
{
    my $dbh_mock = Test::MonkeyMock->new();
    $dbh_mock->mock(do => sub { 1 });

    return $dbh_mock;
}

sub _buildModel
{
    my (%params) = @_;

    my $dbh_mock = delete $params{dbh_mock} || _buildDbhMock();

    my $model = Test::MonkeyMock->new(TestApp::Db->new());
    $model->mock(_buildDbh => sub { $dbh_mock });

    return $model;
}

sub _getTestConfig
{
    return (
        database => 'database',
        host     => 'host',
        port     => 3307,
        user     => 'login',
        password => 'password',
    );
}
