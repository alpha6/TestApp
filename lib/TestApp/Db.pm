package TestApp::Db;
use strict;
use warnings;

require Carp;
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

    $self->{dbh}->do('INSERT INTO `message` (`created`, `id`, `int_id`, `str`) values (?,?,?,?)', undef, ($record->{created}, $record->{id}, $record->{int_id}, $record->{str}) );

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

sub find_by_address
{
    my $self = shift;
    my ($address, $results_limit) = @_;

    Carp::croak("Address is required") unless $address;

    $results_limit ||= 100;

# select SQL_CALC_FOUND_ROWS u.created, u.int_id, u.str from (select created, int_id, str from log as l union select created, int_id, str from message as m) as u, (select int_id from log where address = 'user@another.mail') as ia where u.int_id = ia.int_id;
# SELECT FOUND_ROWS()

    my $select = q{select SQL_CALC_FOUND_ROWS u.created as created, u.int_id as int_id, u.str as str from (select created, int_id, str from log as l union select created, int_id, str from message as m) as u, (select int_id from log where address = ?) as ia where u.int_id = ia.int_id limit ?};
    my $found_rows_select = q{SELECT FOUND_ROWS()};

    my $rows = $self->{dbh}->selectall_arrayref( $select, { Slice => {} }, $address, $results_limit);

    my ($total) = $self->{dbh}->selectrow_array($found_rows_select);

    return {
        rows          => $rows,
        total_records => $total,
    };
}

sub getDbh
{
    my $self = shift;

    return $self->{dbh};
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