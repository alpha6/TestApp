#!/usr/bin/perl
use strict;
use warnings;

use lib 'lib';

use Test::More;

use TestApp::Parser;

new_ok( 'TestApp::Parser' );

subtest 'parse arrival line' => sub {
    my $parser = _buildParser();

    my $arrival_line = q{2012-02-13 14:39:22 1RwtJa-0009RI-7W <= tpxmuwr@somehost.ru H=mail.somehost.com [84.154.134.45] P=esmtp S=2229 id=120213143628.DOMAIN_FEEDBACK_MAIL.503141@whois.somehost.ru};

    my $expected_result = {
        date       => '2012-02-13',
        time       => '14:39:22',
        int_id     => '1RwtJa-0009RI-7W',
        flag       => '<=',
        address    => 'tpxmuwr@somehost.ru',
        other_info => '1RwtJa-0009RI-7W <= tpxmuwr@somehost.ru H=mail.somehost.com [84.154.134.45] P=esmtp S=2229 id=120213143628.DOMAIN_FEEDBACK_MAIL.503141@whois.somehost.ru',
        id         => '120213143628.DOMAIN_FEEDBACK_MAIL.503141@whois.somehost.ru',
    };

    my $result = $parser->parse_line($arrival_line);

    is_deeply($result, $expected_result, 'Parse arrival string');
};

subtest 'parse delayed line' => sub {
    my $parser  = _buildParser();

    my $delayed_line = q{2012-02-13 14:39:22 1RookS-000Pg8-VO == udbbwscdnbegrmloghuf@london.com R=dnslookup T=remote_smtp defer (-44): SMTP error from remote mail server after RCPT TO:<udbbwscdnbegrmloghuf@london.com>: host mx0.gmx.com [74.208.5.90]: 450 4.3.2 Too many mails (mail bomb), try again in 1 hour(s) 25 minute(s) and see ( http://portal.gmx.net/serverrules ) {mx-us011}};

    my $expected_result = {
        date       => '2012-02-13',
        time       => '14:39:22',
        int_id     => '1RookS-000Pg8-VO',
        flag       => '==',
        address    => 'udbbwscdnbegrmloghuf@london.com',
        other_info => '1RookS-000Pg8-VO == udbbwscdnbegrmloghuf@london.com R=dnslookup T=remote_smtp defer (-44): SMTP error from remote mail server after RCPT TO:<udbbwscdnbegrmloghuf@london.com>: host mx0.gmx.com [74.208.5.90]: 450 4.3.2 Too many mails (mail bomb), try again in 1 hour(s) 25 minute(s) and see ( http://portal.gmx.net/serverrules ) {mx-us011}',
        id         => '',
    };

    my $result = $parser->parse_line($delayed_line);

    is_deeply($result, $expected_result, 'Parse delayed string');
};

subtest 'parse blackhole line' => sub {
    my $parser  = _buildParser();

    my $delayed_line = q{2012-02-13 14:39:22 1RwtJa-000AFB-07 => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router};

    my $expected_result = {
        date       => '2012-02-13',
        time       => '14:39:22',
        int_id     => '1RwtJa-000AFB-07',
        flag       => '=>',
        address    => 'tpxmuwr@somehost.ru',
        other_info => '1RwtJa-000AFB-07 => :blackhole: <tpxmuwr@somehost.ru> R=blackhole_router',
        id         => '',
    };

    my $result = $parser->parse_line($delayed_line);

    is_deeply($result, $expected_result, 'Parse blackhole string');
};

subtest 'parse send failed line' => sub {
    my $parser  = _buildParser();

    my $delayed_line = q{2012-02-13 14:39:22 1Rm0kE-00027I-IY ** fwxvparobkymnbyemevz@london.com: retry timeout exceeded};

    my $expected_result = {
        date       => '2012-02-13',
        time       => '14:39:22',
        int_id     => '1Rm0kE-00027I-IY',
        flag       => '**',
        address    => 'fwxvparobkymnbyemevz@london.com',
        other_info => '1Rm0kE-00027I-IY ** fwxvparobkymnbyemevz@london.com: retry timeout exceeded',
        id         => '',
    };

    my $result = $parser->parse_line($delayed_line);

    is_deeply($result, $expected_result, 'Parse failed to send string');
};

subtest 'parse line without flag' => sub {
    my $parser  = _buildParser();

    my $delayed_line = q{2012-02-13 14:39:22 1RwtJa-000AFB-07 Completed};

    my $expected_delayed_result = {
        date       => '2012-02-13',
        time       => '14:39:22',
        int_id     => '1RwtJa-000AFB-07',
        flag       => '',
        address    => '',
        other_info => '1RwtJa-000AFB-07 Completed',
        id         => '',
    };

    my $result = $parser->parse_line($delayed_line);

    is_deeply($result, $expected_delayed_result, 'Parse completed string');

    my $timeout_line = q{2012-02-13 14:40:04 1Rvhdw-000Btn-G5 formen.cbg.ru [109.70.26.36] Operation timed out};

    my $expected_timeout_result = {
        date       => '2012-02-13',
        time       => '14:40:04',
        int_id     => '1Rvhdw-000Btn-G5',
        flag       => '',
        address    => '',
        other_info => '1Rvhdw-000Btn-G5 formen.cbg.ru [109.70.26.36] Operation timed out',
        id         => '',
    };

    my $timeout_result = $parser->parse_line($timeout_line);

    is_deeply($timeout_result, $expected_timeout_result, 'Parse timeout string');

    my $no_id_line = q{2012-02-13 14:46:10 SMTP connection from [109.70.26.4] (TCP/IP connection count = 1)};

    my $expected_no_id_line_result = {
        date       => '2012-02-13',
        time       => '14:46:10',
        int_id     => '',
        flag       => '',
        address    => '',
        other_info => 'SMTP connection from [109.70.26.4] (TCP/IP connection count = 1)',
        id         => '',
    };

    my $no_id_result = $parser->parse_line($no_id_line);

    is_deeply($no_id_result, $expected_no_id_line_result, 'Parse no id string');
};

subtest 'parse additional address line' => sub {
    my $parser  = _buildParser();

    my $delayed_line = q{2012-02-13 14:39:57 1RwtJY-0009RI-E4 -> ldtyzggfqejxo@mail.ru R=dnslookup T=remote_smtp H=mxs.mail.ru [94.100.176.20] C="250 OK id=1RwtK9-0004SS-Fm"};

    my $expected_result = {
        date       => '2012-02-13',
        time       => '14:39:57',
        int_id     => '1RwtJY-0009RI-E4',
        flag       => '->',
        address    => 'ldtyzggfqejxo@mail.ru',
        other_info => '1RwtJY-0009RI-E4 -> ldtyzggfqejxo@mail.ru R=dnslookup T=remote_smtp H=mxs.mail.ru [94.100.176.20] C="250 OK id=1RwtK9-0004SS-Fm"',
        id         => '',
    };

    my $result = $parser->parse_line($delayed_line);

    is_deeply($result, $expected_result, 'Parse additional address string');
};

done_testing();

sub _buildParser
{
    return TestApp::Parser->new();
}
