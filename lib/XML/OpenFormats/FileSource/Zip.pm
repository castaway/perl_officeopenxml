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

sub save_file {
  my ($self, $data, $filename) = @_;

  $filename->parent->mkpath;
  open(my $out_fh, ">", $filename) or die "Can't open $filename for writing: $!";
  $out_fh->print($data->toString);
  $out_fh->close;
}

"¡Ándele! ¡Ándele! ¡Arriba! ¡Arriba! ¡Epa! ¡Epa! ¡Epa! Yeehaw!";
