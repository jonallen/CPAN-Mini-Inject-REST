package CPAN::Mini::Inject::REST::Model::CMI;

use Moose;
use CPAN::Mini::Inject;

BEGIN { extends 'Catalyst::Model'; }

sub COMPONENT {
    my ($self, $c) = $_;
    
    return CPAN::Mini::Inject->new->loadcfg($self->{config_file})->parsecfg;
}

1;
