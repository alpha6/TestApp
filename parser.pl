#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;

use lib 'lib';
use Getopt::Long;
use Config::Tiny;
use File::Spec;

use TestApp::ParserRunner;


my $log_file_name;
my $config_file = 'config.ini';
my $show_help = 0;

GetOptions (
    "log_file=s" => \$log_file_name,
    "config=s"   => \$config_file,
    "help"       => \$show_help
) or die("Invalid arguments\n");

if ($show_help) {
    _showHelp();
    exit 0;
}

my $log_file_path = File::Spec->rel2abs($log_file_name);

my $config = Config::Tiny->read( $config_file );

my $runner = TestApp::ParserRunner->new(config => $config);
$runner->run(log_file => $log_file_path);

sub _showHelp
{
    say 'Help!';
}