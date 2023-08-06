package TestApp::Parser;
use strict;
use warnings;

use Email::Address;


sub new
{
    my $class = shift;
    my (%params) = @_;

    my $self = bless \%params, $class;

    return $self;
}

sub parse_line
{
    my $self = shift;
    my ($line) = @_;

    my $log_string = $line;
    (undef, undef, $log_string) = split /\s/, $log_string, 3;

    my ($date, $time, $int_id, $flag, $log) = split /\s/, $line, 5;

    if (!$self->_isRealIntId($int_id)) {
        $log = join ' ', ( map {defined ? $_ : ''} ($int_id, $flag, $log));

        ($flag, $int_id) = ('', '');
    }

    if (!$self->_isRealFlag($flag) ) {
        $log = join ' ', ( map {defined ? $_ : ''} ($flag, $log));

        $flag = '';
    }

    my $address = $self->_findAddress($log) || '';
    my $id      = $self->_findId($log) || '';

    return {
        date       => $date,
        time       => $time,
        int_id     => $int_id,
        flag       => $flag,
        address    => $address,
        other_info => $log_string,
        id         => $id,
    }
}

sub _isRealFlag
{
    my $self = shift;
    my ($flag) = @_;

    # тут можно было бы проверять то, что значение flag принадлежит к возможным из списка.
    # но в примере лога на этом месте нет ни одного двухсимвольного значениа
    # так что я решил пренебречь полноценной проверкой, т.к. вероятность колизии считаю низкой
    return 1 if length($flag) == 2;

    return 0;
}

sub _isRealIntId
{
    my $self = shift;
    my ($int_id) = @_;

    return 1 if ($int_id =~ /[0-9a-zA-Z]{6}-[0-9a-zA-Z]{6}-[0-9a-zA-Z]{2}/);

    return 0;
}

sub _findAddress
{
    my $self = shift;
    my ($log) = @_;

    my ($address) = Email::Address->parse($log);

    return $address;
}

sub _findId
{
    my $self = shift;
    my ($log) = @_;

    return if $log =~ m/C=".* id=.*"/;

    my ($id) = $log =~ m/id=(.*)$/;

    return $id;
}

1;