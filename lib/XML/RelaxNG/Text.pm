package XML::RelaxNG::Text;
use strictures 1;
use Moose;
use XML::LibXML;

sub as_debug_string {
  return '__text__';
}

sub node_type {
  XML_TEXT_NODE;
}

sub is_arrayref {
  0;
}

sub add_attributes_for_class {
}

sub get_relaxng_thing_for {
  return undef;
}
"\N{EMPTY SET}";
