#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;
use DateTime;

use lib 'lib';

use TestApp::Db;
use Config::Tiny;


my $int_ids_count = 1_000;
my $records_count = 1_000_000;
my $config_file = 'config.ini';

GetOptions (
    "int_ids_count=i" => \$int_ids_count,
    "records_count=i" => \$records_count,
    "config=s"        => \$config_file,
) or die("Invalid arguments\n");


my $config = Config::Tiny->read( $config_file ) or die 'Config read error: '.$!."\n";

my $model = _buildModel($config->{db});

my $ids = _buildIntIds($int_ids_count);

_buildRecords($ids, $records_count);

sub _buildModel
{
    my ($db_config) = @_;

    my $model = TestApp::Db->new();

    $model->connect(%$db_config);

    return $model;
}


sub _buildIntIds
{
    my ($ids_count) = @_;

    my $ids_array = [];

    for (1..$ids_count) {
        my $i = $_;

        push(@$ids_array, {
            int_id => sprintf('int_id_%s', $i),
            address => sprintf('user_%s@test.mail', $i),
        });
    }

    return $ids_array;
}

sub _getRandomIntId
{
    my ($ids) = @_;

    my $id = $ids->[int(rand($int_ids_count))];

    my @chars = ("A".."Z", "a".."z", '0'..'9');
    my $int_id;
    $int_id .= $chars[rand @chars] for 1..10;

    return( $int_id, $id->{address});
}

sub _buildRecords
{
    my ($ids_list, $total_records) = @_;

    my $dbh = $model->getDbh();

    $dbh->{AutoCommit} = 0;

    my $commit_pack_size = 3000;
    my $records_to_commit = 0;

    for my $i (1..$total_records) {
        my $current_time = _getDateTime();
        my ($int_id, $address) = _getRandomIntId($ids_list);

        $records_to_commit++;

        $model->save_message_record({
            created => $current_time,
            id      => sprintf('record_%s_id', $i),
            int_id  => $int_id,
            str     => sprintf('str record from message %s', $i),
        });

        $model->save_log_record({
            created => $current_time,
            int_id  => $int_id,
            str     => sprintf('str record from log %s', $i),
            address => $address,
        });

        $model->save_log_record({
            created => $current_time,
            int_id  => $int_id,
            str     => sprintf('str record without address from log %s', $i),
            address => '',
        });

        if ($records_to_commit >= $commit_pack_size) {
            $dbh->commit();
            $records_to_commit = 0;
        }
    }

}

sub _getDateTime
{
    my $dt = DateTime->now();

    return $dt->strftime('%Y-%m-%d %T')
}