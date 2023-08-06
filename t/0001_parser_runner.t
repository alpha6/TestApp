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
    my ($tmp_fh, $tmp_log) = _makeTmpFile();
    print $tmp_fh 'test string';
    close $tmp_fh;

    my $db_adapter_mock = _buildDbAdapterMock();
    my $parser_mock     = _buildParserMock();

    my $runner  = _buildRunnerMock(parser => $parser_mock, db_adapter => $db_adapter_mock);

    $runner->run(log_file => $tmp_log);

    my ($db_adapter_args) = $runner->mocked_call_args('_buildDbAdapter');
    is_deeply(_getTestConfig()->{db}, $db_adapter_args, 'DB Adapter agrs');

    is(1, $runner->mocked_called('_buildParser'), 'Build parser');
};

subtest 'run parser with corrects args' => sub {
    my ($tmp_fh, $tmp_log) = _makeTmpFile();
    print $tmp_fh 'test string';
    close $tmp_fh;

    my $db_adapter_mock = _buildDbAdapterMock();
    my $parser_mock = _buildParserMock();

    my $runner  = _buildRunnerMock(parser => $parser_mock, db_adapter => $db_adapter_mock);

    $runner->run(log_file => $tmp_log);

    my @parser_run_args = $parser_mock->mocked_call_args('parse_line');
    ok('test string' eq $parser_run_args[0], 'Run parser with string');
};

subtest 'throw correct errors' => sub {
    my $runner = _buildRunnerMock();

    throws_ok { $runner->run(log_file => 'file_not.exists')} qr/^file is not exists/, 'throws on no file';

    my (undef, $tmp_log) = _makeTmpFile(PERMS => 0111);

    throws_ok { $runner->run(log_file => $tmp_log)} qr/^file is not readable/, 'throws on not readable file';
};

subtest 'print correct statistic' => sub {
    my ($tmp_fh, $tmp_log) = _makeTmpFile();
    print $tmp_fh "test string\n" for (0..2);
    close $tmp_fh;

    my $parser = Test::MonkeyMock->new();
    $parser->mock(parse_line => sub {{int_id => '1RwtJa-0009RI-7W', flag => '<='}},  frame => 0);
    $parser->mock(parse_line => sub {{int_id => '1RwtJa-0009RI-7W', flag => '==',}}, frame => 1);
    $parser->mock(parse_line => sub {{int_id => '', flag => ''}},                    frame => 2);

    my $runner = _buildRunnerMock(parser => $parser);

    stdout_is(sub {$runner->run(log_file => $tmp_log)},"Total: 3, messages: 1, log: 1, other: 1\n",'Test statistic ');
};

done_testing();

sub _buildParser
{
    return TestApp::ParserRunner->new(config => _getTestConfig());
}

sub _buildRunnerMock
{
    my (%params) = @_;

    my $runner = _buildParser();

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

    my $stat = $params{result} || {
        date       => '2012-02-13',
        time       => '14:39:22',
        int_id     => '1RwtJa-0009RI-7W',
        flag       => '<=',
        address    => 'tpxmuwr@somehost.ru',
        other_info => '1RwtJa-0009RI-7W <= tpxmuwr@somehost.ru H=mail.somehost.com [84.154.134.45] P=esmtp S=2229 id=120213143628.DOMAIN_FEEDBACK_MAIL.503141@whois.somehost.ru',
        id         => '120213143628.DOMAIN_FEEDBACK_MAIL.503141@whois.somehost.ru',
    };

    my $mock = Test::MonkeyMock->new();
    $mock->mock(parse_line => sub { $stat });

    return $mock;
}

sub _buildDbAdapterMock
{
    my $mock = Test::MonkeyMock->new();
    $mock->mock(save_message_record => sub { 1 });
    $mock->mock(save_log_record => sub { 1 });

    return $mock;
}
