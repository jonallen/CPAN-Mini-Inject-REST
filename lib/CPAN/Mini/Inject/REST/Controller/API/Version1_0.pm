package CPAN::Mini::Inject::REST::Controller::API::Version1_0;
use Moose;
use File::Copy;
use File::Temp;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    namespace => 'api/1.0',
    default   => 'application/json',
);

=head1 NAME

CPAN::Mini::Inject::REST::Controller::API::Version1_0 - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched CPAN::Mini::Inject::REST::Controller::API::Version1_0 in API::Version1_0.');
}

=head2 add

=cut

sub dist :Local :Args(1) :ActionClass('REST') {}

sub dist_POST {
    my ($self, $c, $dist) = @_;
    
    if ($c->req->upload('file')->filename =~ /([^\/]*)-([0-9._]+)\.tar\.gz$/) {
        my $module = $1;
        my $version = $2;
        $module =~ s/-/::/g;
        
        my $ftmp    = File::Temp->new();
        my $tmpdir  = $ftmp->newdir();
        my $newfile = $tmpdir. "/" . $c->req->upload('file')->filename;
        copy($c->req->upload('file')->tempname, $newfile);
        
        $c->model('CMI')->readlist;
        $c->model('CMI')->add(
            module   => $module,
            version  => $version,
            authorid => 'LOCAL',
            file     => $newfile,
        );
        $c->model('CMI')->writelist;
        $c->model('CMI')->inject;
    }
    
    $self->status_created(
        $c,
        location => $c->req->uri->as_string,
        entity   => {
            filename => $c->req->upload('file')->filename,
            type     => $c->req->upload('file')->type,
            tempname => $c->req->upload('file')->tempname,
        }
    )
}


=head1 AUTHOR

Jon Allen (JJ) <jj@jonallen.info>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
