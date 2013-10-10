package XML::RelaxNG::Attribute;

use Moose;
use XML::LibXML;
use diagnostics;
use Data::Dump::Streamer 'Dump', 'Dumper';

has 'rnc_file', is => 'ro';
has 'top', is => 'ro';
has name => ( is => 'ro');
has full_name => ( is => 'ro');
has pattern => ( is => 'ro');

sub namespace_uri {
  my ($self) = @_;
  my $full = $self->full_name;

  if ($full eq '*') {
    ### This is almost certianly full of shit.
    return 'http://example.com/shit/';
  }
  
  $full =~ m/^\{(.*?)\}(.*)$/ or die "Can't parse $full";

  my ($ns, $local) = ($1, $2);
  return $ns;
}

sub long_name {
  $_[0]->full_name;
}

sub as_debug_string {
  my ($self) = @_;

  "attribute ".$self->name." = ".$self->pattern->as_debug_string;
}

sub result_name {
    return $_[0]->full_name;
}

sub xml_name {
  $_[0]->full_name;
}

sub node_type {
  XML_ATTRIBUTE_NODE;
}

sub is_arrayref {
  0;
}

sub from_dom {
  my ($self, $dom, $rest) = @_;

  print "attribute from_dom ", $self->name, "\n";

  if ($self->full_name ne XML::RelaxNG::Utils::full_name($dom) &&
     $self->name ne $dom->localname) {
    die "Wanted an attribute ".$self->name.", got ".$dom->toString." ".$self->full_name." ".XML::RelaxNG::Utils::full_name($dom);
  }
  
  return $self->pattern->from_dom($dom->value, $rest);
}

sub add_attributes_for_class {
  my ($self, $class, $element) = @_;
  
  print "Attribute add_attributes_for_class: ", $self->as_debug_string, "\n";

  my $short_name = $self->name;
  my $long_name = $self->full_name;

  print "Attribute $long_name, Predicate: has_${short_name}\n";
  my $mma = $class->add_attribute($long_name, {
                                               is => 'rw',
                                               accessor => $long_name,
                                               init_arg => $long_name,
                                               predicate => "has_$long_name",
                                               # isa, default, lazy
                                              });
  $element->add_attribute($long_name, $mma, $self);

  return $mma;
}

my $namespaces = {};
my $last_namespace = 0;
sub to_dom {
  my ($self, $value, $document) = @_;

  if ($self->full_name eq '*') {
    print "*** Trying to to_dom an Attribute *, value=\n";
    Dump ($value);
    die;

    return {ns => 'http://example.com/shit/', name => 'FIXME', value => 'attribute *'};
  }

  my $ns = $self->namespace_uri;
  my $prefix = $namespaces->{$ns};
  if (!$prefix) {
    $prefix = "ns".$last_namespace++;
    $namespaces->{$ns} = $prefix;
  }

  #my $node = XML::LibXML::Attr->new($prefix.":".$self->name, $value);
  #my $node = XML::LibXML::Attr->new($self->name, $value);
  #$node->setNamespace($self->namespace_uri, $prefix, 1);
  #print "Trying to create attribute, ns=", $self->namespace_uri, " name=", $self->name, "\n";
  #return $document->createAttributeNS($self->namespace_uri, $self->name, $value);
  #return $document->createAttribute($self->name, $value);

  # Return a random fake thingy, because we need to do the actual creation in Element.pm
  return {ns => $self->namespace_uri, name => $self->name, value => $value};
}

1;
