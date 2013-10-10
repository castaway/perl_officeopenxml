package XML::RelaxNG::Annotation;
use Moose;

has ('annotation',
     is => 'ro');

has ('of',
     is => 'ro',
    );

our $AUTOLOAD;
sub AUTOLOAD {
  my ($self, @args) = @_;

  my $full_name = $AUTOLOAD;
  my ($package, $name) = $full_name =~ m/^(.*)::(.*?)$/;

  if ($self->of->can($name)) {
    return $self->of->$name(@args);
  }

  die "Annotation can't $name, and neither can it's of (".$self->of.")";
}

1;
