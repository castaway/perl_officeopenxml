package XML::OpenXMLFormats::PresentationML::_2006::Main::presentation;
use strictures 1;

use Data::Dumper;

sub slide_ids {
  my ($self) = @_;

  print Dumper($self);
  print Dumper($self->meta);

  return @{ $self->sldIdLst->sldId };
}

sub slides {
  my ($self) = @_;

  my @slide_ids = $self->slide_ids;

  my $attr_name = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id';
  my @slides = map { $_->$attr_name->dereference } @slide_ids;

  return @slides;
}

1;
