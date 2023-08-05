package TestApp::Utils;
use strict;
use warnings;

require Carp;

sub new
{
    my $class = shift;
    my (%params) = @_;

    my $self = bless \%params, $class;

    return $self;
}

sub checkRequiredParams
{
    my $self = shift;
    my ($params, @required_field) = @_;

    my @errors;

    for my $field (@required_field) {
        next if (exists($params->{$field}) && defined($params->{$field}) && $params->{$field} ne '');

        push @errors, $field;
    }

    Carp::croak(join "\n", map { "Field '$_' is required" } @errors) if @errors;

    return 1;
}

1;