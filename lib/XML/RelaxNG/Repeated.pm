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

sub get_relaxng_thing_for {
  my ($self, $long_name) = @_;

  print "get_relaxng_thing_for(repeated): Looking for $long_name, at ". $self->of, ", ", $self->of->as_debug_string, "\n";
  return $self->of->get_relaxng_thing_for($long_name);
}

# OBSOLETE, remove once properly vcsed?
# sub from_dom_multi {
#   my ($self, $dom, $rest) = @_;

#   print "repeated from_dom (not single) ", ref $self->of, " with ", $dom->toString, "\n";

#   my @children = $dom->childNodes;

#   if (!blessed $self->of) {
#     Dump $self->of;
#     die "Repeated of an unblessed";
#   }

#   my @res = map {$self->of->from_dom($_)} @children;

#   my $count = @res;
#   if ($count > $self->max_repeat) {
#     die "Too many thingies, got $count, wanted at most ".$self->max_repeat."?";
#   }
#   if ($count < $self->min_repeat) {
#     die "Not enough thingies, got $count, wanted at least ".$self->min_repeat."?";
#   }

#   return \@res;
# }


1;
