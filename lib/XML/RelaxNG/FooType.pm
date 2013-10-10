package XML::RelaxNG::FooType;
use Moose;
use XML::LibXML;
use URI;

has 'type',
  is => 'ro';
has 'params',
  is => 'ro';

sub as_debug_string {
  my ($self) = @_;

  return "FooType(".$self->type.")";
}

sub result_name {
    # ???
    return $_[0]->type;
}

sub is_arrayref {
  return 0;
}

sub long_name {
  '__text__';
}

sub add_attributes_for_class {
  my ($self, $class) = @_;

  $class->add_attribute('__text__', {
                                     is => 'rw',
                                    });
}

sub get_relaxng_thing_for {
  my ($self, $long_name) = @_;

  return $self if $self->long_name eq $long_name;

  return undef;

}

sub node_type {
  my ($self) = @_;

  if ($self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}string' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}anyURI' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}ID' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}boolean' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}unsignedInt' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}int' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}hexBinary' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}long' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}byte'
     ) {
    return XML_TEXT_NODE;
  } else {
    die "Need node_type for FooType ".$self->type;
  }
}

sub from_dom {
  my ($self, $dom, $rest) = @_;

  my $effective_value;
  if (not ref $dom) {
    $effective_value = $dom;
  } else {
    $effective_value = $dom->nodeValue;
  }

  my $effective_type;
  if (not ref $effective_type) {
    $effective_type = XML_TEXT_NODE;
  } else {
    $effective_type = $dom->nodeType;
  }
  
  if ($effective_type != $self->node_type) {
    my $debug_string = $self->as_debug_string;
    die "Trying to match a $debug_string against a ".$self->node_type;
  }

  if ($self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}string' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}ID' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}unsignedInt' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}int' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}hexBinary' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}long' or
      $self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}byte') {
    return $effective_value;
  } elsif ($self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}boolean' and 
           ($effective_value eq 'true' or $effective_value eq '1')) {
    return 1;
  } elsif ($self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}boolean' and 
           ($effective_value eq 'false' or $effective_value eq '0')) {
    return 0;
  } elsif ($self->type eq '{http://www.w3.org/2001/XMLSchema-datatypes}anyURI') {
    return URI->new($effective_value);
  } else {
    die "Unknown FooType type ". $self->type." with value $effective_value";
  }
}

1;
