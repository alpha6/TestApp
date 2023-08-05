#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Output;
use Test::MonkeyMock;

use File::Temp qw/tempfile/;

use lib 'lib';

use TestApp::ParserRunner;

new_ok( 'TestApp::ParserRunner' => [config => _getTestConfig()] );

subtest 'build builders with corrects args' => sub {
    my (undef, $tmp_log) = _makeTmpFile();

    my $db_adapter_mock = _buildDbAdapterMock();
    my $parser_mock = _buildParserMock();

    my $runner  = _buildRunnerMock(parser => $parser_mock, db_adapter => $db_adapter_mock);

    $runner->run(log_file => $tmp_log);

    my ($db_adapter_args) = $runner->mocked_call_args('_buildDbAdapter');
    is_deeply(_getTestConfig()->{db}, $db_adapter_args, 'DB Adapter agrs');

    my (%parser_args) = $runner->mocked_call_args('_buildParser');
    is($db_adapter_mock, $parser_args{db}, 'Build parser with db adapter');

    my (%parser_run_args) = $parser_mock->mocked_call_args('parse_file');
    ok($tmp_log eq $parser_run_args{log_path}, 'Run parser with log_path');
};

subtest 'run parser with corrects args' => sub {
    my (undef, $tmp_log) = _makeTmpFile();

    my $db_adapter_mock = _buildDbAdapterMock();
    my $parser_mock = _buildParserMock();

    my $runner  = _buildRunnerMock(parser => $parser_mock, db_adapter => $db_adapter_mock);

    $runner->run(log_file => $tmp_log);

    my (%parser_run_args) = $parser_mock->mocked_call_args('parse_file');
    ok($tmp_log eq $parser_run_args{log_path}, 'Run parser with log_path');
};

subtest 'throw correct errors' => sub {
    my $runner = _buildRunnerMock();

    throws_ok { $runner->run(log_file => 'file_not.exists')} qr/^file is not exists/, 'throws on no file';

    my (undef, $tmp_log) = _makeTmpFile(PERMS => 0111);

    throws_ok { $runner->run(log_file => $tmp_log)} qr/^file is not readable/, 'throws on not readable file';
};

subtest 'print correct statistic' => sub {
    my $parser_mock = _buildParserMock(stat => {total => 123});

    my $runner = _buildRunnerMock(parser => $parser_mock);

    my (undef, $tmp_log) = _makeTmpFile();

    stdout_is(sub {$runner->run(log_file => $tmp_log)},"Total lines: 123\n",'Test statistic ');

};

done_testing();

sub _buildRunner
{
    return TestApp::ParserRunner->new(config => _getTestConfig());
}

sub _buildRunnerMock
{
    my (%params) = @_;

    my $runner = _buildRunner();

    my $db_adapter_mock = $params{db_adapter} || _buildDbAdapterMock();
    my $parser_mock     = $params{parser}     || _buildParserMock();

    $runner = Test::MonkeyMock->new($runner);
    $runner->mock('_buildParser' => sub { $parser_mock });
    $runner->mock('_buildDbAdapter' => sub { $db_adapter_mock });

    return $runner;
}

sub _makeTmpFile
{
    my (@params) = @_;

    return tempfile(@params);
}

sub _getTestConfig
{
    return {
        db => {
            host     => 'localhost',
            port     => 3306,
            login    => 'login',
            password => 'password',
        }
    }
}

sub _buildParserMock
{
    my (%params) = @_;

    my $stat = $params{stat} || { total => 0 };

    my $mock = Test::MonkeyMock->new();
    $mock->mock(parse_file => sub { $stat });

    return $mock;
}

sub _buildDbAdapterMock
{
    my $mock = Test::MonkeyMock->new();
    $mock->mock(save_lines => sub { 1 });

    return $mock;
}
