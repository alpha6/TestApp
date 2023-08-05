package TestApp::Parser;
use strict;
use warnings;


sub new
{
    my $class = shift;
    my (%params) = @_;

    my $self = bless \%params, $class;

    return $self;
}

sub parse_file
{
    my $self = shift;
    my ($file_path) = @_;

    ...
}

sub parse_line
{
    my $self = shift;
    my ($line) = @_;

    ...
}

1;