package TestApp::Db;
use strict;
use warnings;

use DBI;
use DBD::mysql;

use TestApp::Utils;


sub new
{
    my $class = shift;
    my (%params) = @_;

    my $self = bless \%params, $class;

    return $self;
}

sub connect
{
    my $self = shift;
    my (%params) = @_;

    TestApp::Utils->checkRequiredParams(\%params, qw/host user password database/);

    my $port = $params{port} || 3306;

    my $dbh = $self->_buildDbh(
        database => $params{database},
        host     => $params{host},
        port     => $port,
        user     => $params{user},
        password => $params{password},
    );

    $self->{dbh} = $dbh;

    return 1;
}

sub save_message_record
{
    my $self = shift;
    my ($record) = @_;

    TestApp::Utils->checkRequiredParams($record, qw/created id int_id str/);

    $self->{dbh}->do('INSERT INTO `messages` (`created`, `id`, `int_id`, `str`) values (?,?,?,?)', undef, ($record->{created}, $record->{id}, $record->{int_id}, $record->{str}) );

    return 1;
}

sub save_log_record
{
    my $self = shift;
    my ($record) = @_;

    TestApp::Utils->checkRequiredParams($record, qw/created int_id/);

    $record->{str}     ||= '';
    $record->{address} ||= '';

    $self->{dbh}->do('INSERT INTO `log` (`created`, `int_id`, `str`, `address`) values (?,?,?,?)', undef, ($record->{created}, $record->{int_id}, $record->{str}, $record->{address}) );

    return 1;
}

sub _buildDbh
{
    my $self = shift;
    my (%params) = @_;

    my $dsn = sprintf("DBI:mysql:database=%s;host=%s;port=%s", $params{database}, $params{host}, $params{port});
    my $dbh = DBI->connect($dsn, $params{user}, $params{password}, {'RaiseError' => 1});

    return $dbh;
}

1;