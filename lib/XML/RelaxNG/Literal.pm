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

'1';
