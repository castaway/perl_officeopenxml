package XML::RelaxNG::Repeated;
use Moose;
use Data::Dump::Streamer 'Dump';
use Scalar::Util 'blessed';

has 'of', is => 'ro', handles => ['node_type', 'xml_name', 'name', 'to_dom', 'long_name', 'add_attributes_for_class'];
has 'min_repeat', is => 'ro';
has 'max_repeat', is => 'ro';

sub as_debug_string {
  my ($self) = @_;

  my $of_string = $self->of->as_debug_string;

  return "(".$of_string."){".$self->min_repeat."..".$self->max_repeat."}";
}

sub is_arrayref {
  my ($self, $dom) = @_;

  return ($self->max_repeat > 1);
}

sub result_name {
    return $_[0]->xml_name;
}

sub from_dom {
  my ($self, $dom, $rest) = @_;

  print "repeated from_dom ", ref $self->of, " with ", $dom->toString, "\n";

  $self->of->from_dom($dom, $rest);
}

1;
