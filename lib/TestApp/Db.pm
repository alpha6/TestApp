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

    #     DROP TABLE IF EXISTS `int_ids_by_address`;
    #     CREATE TEMPORARY TABLE int_ids_by_address select int_id from log where address='udbbwscdnbegrmloghuf@london.com';
    #     select coalesce(l.created, m.created) as created, coalesce(l.int_id, m.int_id) as int_id, coalesce(l.str, m.str) as str from int_ids_by_address ia left join log l on ia.int_id = l.int_id left join message m on m.int_id = ia.int_id order by coalesce(l.created, m.created), coalesce(l.int_id, m.int_id) ASC limit 10;
    #     select count(*) from int_ids_by_address ia left join log l on ia.int_id = l.int_id left join message m on m.int_id = ia.int_id;

    $self->{dbh}->do(q{DROP TABLE IF EXISTS `int_ids_by_address`;});
    $self->{dbh}->do(q{CREATE TEMPORARY TABLE int_ids_by_address select int_id from log where address=?;}, undef, $address);

    my $select = <<'END';
select
   coalesce(l.created, m.created) as created,
   coalesce(l.str, m.str) as str
from int_ids_by_address ia
   left join log l on ia.int_id = l.int_id
   left join message m on m.int_id = ia.int_id
order by
   coalesce(l.int_id, m.int_id),
   coalesce(l.created, m.created) DESC
limit ?;
END

    my $rows = $self->{dbh}->selectall_arrayref( $select, { Slice => {} }, $results_limit);

    my ($total) = $self->{dbh}->selectrow_array(q{select count(*) from int_ids_by_address ia left join log l on ia.int_id = l.int_id left join message m on m.int_id = ia.int_id;});

    return {
        rows          => $rows,
        total_records => $total,
    };
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