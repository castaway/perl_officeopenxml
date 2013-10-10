package XML::RelaxNG::Ref;
use Moose;
use Scalar::Util 'blessed';

has 'ref', is => 'ro';
has 'top', is => 'ro';
has('resolve',
    is => 'ro',
    lazy => 1,
    handles => ['node_type', 'xml_name', 'name', 'class', 'add_attributes_for_class', 'get_relaxng_thing_for', 'to_dom'],
    default => sub {
      my ($self) = @_;

      $self->top->get_type($self->ref);
    });

sub is_arrayref {
  my ($self, $dom) = @_;

  $self->resolve->is_arrayref($dom);
}

sub result_name {
    return $_[0]->resolve->result_name($_[1]);
}

sub as_debug_string {
  my ($self) = @_;

  return "ref to ".$self->ref;
}

sub from_dom {
  my ($self, $dom, $rest) = @_;

  print "ref from_dom: ", $self->ref, "\n";
  my $res = $self->resolve;
  if (not blessed $res) {
    Dump $res;
    die "Ref to an unblessed type";
  }

  $res->from_dom($dom, $rest);
}

1;
