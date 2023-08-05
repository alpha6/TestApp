package TestApp::ParserRunner;
use strict;
use warnings;
use feature qw/say/;

require Carp;
use Error qw/:try/;

use TestApp::Parser;
use TestApp::Db;
use TestApp::Utils;


sub new
{
    my $class = shift;
    my (%params) = @_;

    TestApp::Utils->checkRequiredParams(\%params, qw/config/);

    my $self = bless \%params, $class;

    return $self;
}

sub run
{
    my $self = shift;
    my (%params) = @_;

    TestApp::Utils->checkRequiredParams(\%params, qw/log_file/);

    my $log_file_path = $params{log_file};

    $self->_checkLogFile($log_file_path);

    my $db_adapter = $self->_buildDbAdapter($self->{config}->{db});

    my $parser = $self->_buildParser(db => $db_adapter);
    my $results = $parser->parse_file(log_path => $log_file_path);

    $self->_printStatistic($results);
}

sub _checkLogFile
{
    my $self = shift;
    my ($file_name) = @_;

    Carp::croak('file is not exists')   unless (-e $file_name);

    Carp::croak('file is not readable') unless (-r $file_name);

    return 1;
}

sub _buildParser
{
    my $self = shift;
    my ($db_adapter) = @_;

    return TestApp::Parser->new(db => $db_adapter);
}

sub _buildDbAdapter
{
    my $self = shift;
    my ($config) = @_;

    return TestApp::Db->new($config);
}

sub _printStatistic
{
    my $self = shift;
    my ($results) = @_;

    say sprintf('Total lines: %s', $results->{total});
}

1;