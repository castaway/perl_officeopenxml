package XML::RelaxNG::PartialType;
use Moose;
use MooseX::StrictConstructor;
use Data::Dump::Streamer 'Dump', 'Dumper';
use Scalar::Util 'blessed';
use XML::OpenXMLFormats::Reference;

=head1 NAME

XML::RelaxNG::PartialType

=head1 DESCFRIPTION

An incompletely defined type, RelaxNG can define types across multiple lines, eg:

a_CT_TextBulletSizePercent =
  attribute val { a_ST_TextBulletSizePercent }
a_CT_TextBulletSizePercent |=
  attribute more { Stuff }

=head1 ATTRIBUTES

=head2 op

=head2 name

=head2 values

The values attribute contains an arrayref of the actual definitions, which could be almost anything, a Group, an Element, an Attribute etc.

=cut

has 'op', is => 'rw', required => 1;
has 'name', is => 'rw', required => 1;
has 'values', is => 'rw', required => 1;

sub class {
  return $_[0]->values->[0]->class;
}

sub node_type {
  # Quietly assumes all the children are of the same node_type (which is required by the spec, IIRC, but not checked by the parser).
  if (not blessed $_[0]->values->[0]) {
    Dump $_[0]->values;
    die "Unblessed thingy inside PartialType";
  }
  $_[0]->values->[0]->node_type;
}

sub xml_name {
  # This, OTOH, is *not* required by the spec, and is probably wrong.
  $_[0]->values->[0]->xml_name;
}

sub merge {
  my ($left, $right) = @_;
  
  print "PartialType merge of $left, $right\n";

  # Er, both the same?  No need to do anything.
  if ($left == $right) {
    return $left;
  } else {
    print(Dumper([$left, $right]));
    die "Need to merge";
  }
}

sub result_name {
    return $_[0]->values->[0]->result_name($_[1]);
}

sub is_arrayref {
  my ($self, $dom) = @_;
  
  $self->values->[0]->is_arrayref($dom);
}

sub add_attributes_for_class {
  my ($self, $class, $element) = @_;

  $self->values->[0]->add_attributes_for_class($class, $element);
}

sub get_relaxng_thing_for {
  my ($self, $long_name) = @_;

  return $self->values->[0]->get_relaxng_thing_for($long_name);
}

sub from_dom {
  my ($type, $dom, $rest) = @_;

  # FIXME: This belongs in a much higher level.
  if ($type->name eq 'r_ST_RelationshipId') {
    my $real = $type->values->[0]->from_dom($dom, $rest);
    
    return XML::OpenXMLFormats::Reference->new(rid => $real, rest => $rest);
    #return XML::OpenXMLFormats::Reference->new(rid => $real);
  }

  print "partialtype from_dom: ", $type->name, "\n";
  if ($type->op eq '=') {
    $type = $type->values->[0];
  } else {
    die "FIXME: partial type with operator ", $type->op;
  }

  if (not blessed $type) {
    Dump $type;
    die "Partial type of an unblessed?";
  }

  print STDERR "$type\n";
  
  $type->from_dom($dom, $rest);
}

sub to_dom {
  my ($self, $value, $document) = @_;
  
  print "to_dom($self, $value)\n";
  $self->values->[0]->to_dom($value, $document);
}

1;
