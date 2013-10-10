package XML::OpenXMLFormats::Package::_2006::Relationships::Relationships;
use strictures 1;

sub get_by_id {
  my ($self, $id) = @_;

  for my $rel (@{$self->Relationship}) {
    if ($rel->Id eq $id) {
      return $rel;
    }
  }

  die "Couldn't find a relationship with id $id";
}

$<;

