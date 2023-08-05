package TestApp::Db;
use strict;
use warnings;


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

    ...
}

sub save_line
{
    my $self = shift;

    ...
}

1;