package XML::OpenFormats::FileSource::Zip;
use strictures 1;
use Archive::Zip ':ERROR_CODES';
use Moose;

has 'file', is => 'ro';
has 'archive', is => 'ro', lazy => 1,
  default => sub {
    my ($self) = @_;

    my $archive = Archive::Zip->new;

    $archive->read($self->file) == AZ_OK
      or die "Read error";

    return $archive;
  };


sub get_file {
  my ($self, $name) = @_;

  # stringify Path::Classes, URIs, etc.
  $name = "$name";
  
  return $self->archive->contents($name);
}

"¡Ándele! ¡Ándele! ¡Arriba! ¡Arriba! ¡Epa! ¡Epa! ¡Epa! Yeehaw!";
