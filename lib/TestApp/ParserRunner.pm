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

    my $parser = $self->_buildParser();

    my $stats = {
        total    => 0,
        messages => 0,
        logs     => 0,
        other    => 0,
    };

    open my $log_file, '<', $log_file_path;
    while (my $line = <$log_file> )
    {
        $stats->{total}++;

        my $result = $parser->parse_line($line);

        my $record = $self->_buildRecordData($result);

        if ($result->{flag} eq '<=') {
            $db_adapter->save_message_record($record);

            $stats->{messages}++;

            next;
        }
        if ($result->{int_id}) {
            $db_adapter->save_log_record($record);

            $stats->{logs}++;

            next;
        }

        $stats->{other}++;
    }

    close $log_file;

    $self->_printStatistic($stats);
}

sub _checkLogFile
{
    my $self = shift;
    my ($file_name) = @_;

    Carp::croak('file is not exists')   unless (-e $file_name);

    Carp::croak('file is not readable') unless (-r $file_name);

    return 1;
}

sub _buildRecordData
{
    my $self = shift;
    my ($data) = @_;

    my $created = sprintf('%s %s', $data->{date}, $data->{time});
    delete $data->{date};
    delete $data->{time};

    my $str = delete $data->{other_info}|| '';

    my $record = {
        created => $created,
        %$data,
        $str ? (str => $str) : (),
    };

    return $record;
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

    say sprintf("Total: %s, messages: %s, log: %s, other: %s",
        $results->{total},
        $results->{messages},
        $results->{logs},
        $results->{other},
    );
}

1;