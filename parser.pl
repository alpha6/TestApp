#!/usr/bin/env perl
use strict;
use warnings;
use feature qw/say/;

use lib 'lib';
use Getopt::Long;
use Config::Tiny;
use File::Spec;

use TestApp::ParserRunner;
use TestApp::Utils;


my $log_file_name;
my $config_file = 'config.ini';
my $show_help = 0;

GetOptions (
    "log_file=s" => \$log_file_name,
    "config=s"   => \$config_file,
    "help"       => \$show_help
) or die("Invalid arguments\n");

if ($show_help || !$log_file_name) {
    _showHelp();

    exit 0;
}

my $log_file_path = File::Spec->rel2abs($log_file_name);

my $config = Config::Tiny->read( $config_file ) or die 'Config read error: '.$!."\n";

my $runner = TestApp::ParserRunner->new(config => $config);
$runner->run(log_file => $log_file_path);

sub _showHelp
{
    my $help_text = << 'EOF';
parser.pl --log_file=log.txt --config=config.ini
    --log_file - required, path to log file
    --config   - optional, path to config
    --help     - show this help
EOF

    say $help_text;
}