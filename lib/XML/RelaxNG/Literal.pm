package XML::RelaxNG::Literal;
use Moose;
use XML::LibXML;

has 'text', is => 'ro';

sub as_debug_string {
  '"' . $_[0]->text . '"';
}

sub node_type {
  XML_TEXT_NODE;
}

sub get_relaxng_thing_for {
  my ($self, $long_name) = @_;

  return $self if $long_name eq '__text__';

  return undef;
}

'1';
