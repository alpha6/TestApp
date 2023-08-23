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
        port     => 3306,
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

    ok(q{INSERT INTO `message` (`created`, `id`, `int_id`, `str`) values (?,?,?,?)} eq $query, 'Check correct query');

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

    my @expected_values = ('2023-01-01 02:03:04', 'record_int_id', 'log record str', 'user@e.mail');

    my $query = shift(@args);
    shift @args;

    ok(q{INSERT INTO `log` (`created`, `int_id`, `str`, `address`) values (?,?,?,?)} eq $query, 'Check correct query');

    is_deeply(\@expected_values, \@args, 'Check correct values');
};

subtest 'call dbh with params on find_address' => sub {
    my $dbh_mock = _buildDbhMock();

    my $model = _buildModel(dbh_mock => $dbh_mock);

    $model->connect(database => 'database', host => 'host', user => 'user', password => 'password');
    $model->find_by_address('user@e.mail', 123);


    my (@find_records_call_args) = $dbh_mock->mocked_call_args('selectall_arrayref');

    my @expected_find_values = ('user@e.mail', 'user@e.mail', 123);

    shift(@find_records_call_args);
    shift @find_records_call_args;

    is_deeply(\@expected_find_values, \@find_records_call_args, 'Check correct values');
};

done_testing();

sub _buildDbhMock
{
    my $dbh_mock = Test::MonkeyMock->new();
    $dbh_mock->mock(do => sub { 1 });
    $dbh_mock->mock(selectall_arrayref => sub { [{created => '2012-02-13 14:49:16', str => '1Rb9ul-0008V2-SS == udbbwscdnbegrmloghuf@london.com R=dnslookup T=remote_smtp defer (-44): SMTP error from remote mail server after RCPT TO:<udbbwscdnbegrmloghuf@london.com>: host mx0.gmx.com [74.208.5.90]: 450 4.3.2 Too many mails (mail bomb), try again in 1 hour(s) 14 minute(s) and see ( http://portal.gmx.net/serverrules ) {mx-us017}'}] });
    $dbh_mock->mock(selectrow_array => sub { 1 });

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
        port     => 3306,
        user     => 'login',
        password => 'password',
    );
}
