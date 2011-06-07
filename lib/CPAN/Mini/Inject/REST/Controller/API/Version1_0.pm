package CPAN::Mini::Inject::REST::Controller::API::Version1_0;

use 5.010;
use Moose;
use Archive::Extract;
use File::Copy;
use File::Find::Rule;
use File::Spec::Functions qw/splitpath/;
use File::Temp;
use Parse::CPAN::Meta;
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
    
    # Check to see if the file already exists
    $c->model('CMI')->readlist;
    unless ($c->model('CMI')->{modulelist} && grep {m!L/LO/LOCAL/$dist!} @{$c->model('CMI')->{modulelist}}) {
        if ($c->req->upload('file')->filename =~ /([^\/]*)-([0-9._]+)\.tar\.gz$/) {
            my $module = $1;
            my $version = $2;
            $module =~ s/-/::/g;
            
            my $ftmp    = File::Temp->new();
            my $tmpdir  = $ftmp->newdir();
            my $newfile = $tmpdir. "/" . $c->req->upload('file')->filename;
            copy($c->req->upload('file')->tempname, $newfile);
            
            $c->model('CMI')->add(
                module   => $module,
                version  => $version,
                authorid => 'LOCAL',
                file     => $newfile,
            );
            
            # Add all modules listed in META.json / META.yml
            if (my $meta = _load_meta($newfile)) {
                while (my ($module, $details) = each %{$meta->{provides}}) {
                    $c->model('CMI')->add(
                        module   => $module,
                        version  => $details->{version} // 'undef',
                        authorid => 'LOCAL',
                        file     => $newfile,
                    );
                }
            }
            
            $c->model('CMI')->writelist;
            $c->model('CMI')->inject;
            
            $self->status_created(
                $c,
                location => $c->req->uri->as_string,
                entity   => {
                    filename => $c->req->upload('file')->filename,
                    type     => $c->req->upload('file')->type,
                    tempname => $c->req->upload('file')->tempname,
                }
            );
        }
    } else {
        $self->status_bad_request(
            $c,
            message => "File $dist already exists",
        );
    }
}

sub _load_meta {
    my $filename = shift;
    my ($vol, $dir, $file) = splitpath($filename);
    my $archive = Archive::Extract->new(archive => $filename);
    $archive->extract(to => "$vol/$dir");
    
    if (my @meta = File::Find::Rule->file->name('META.json')->in("$vol/$dir")) {
        return Parse::CPAN::Meta->load_file(shift @meta);
    }

    if (my @meta = File::Find::Rule->file->name('META.yml')->in("$vol/$dir")) {
        return Parse::CPAN::Meta->load_file(shift @meta);
    }
}

=head1 AUTHOR

Jon Allen (JJ) <jj@jonallen.info>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
