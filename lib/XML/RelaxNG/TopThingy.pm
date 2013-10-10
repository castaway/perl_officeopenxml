package XML::RelaxNG::TopThingy;
use Moose;
use Data::Dump::Streamer 'Dump', 'Dumper';
use Scalar::Util 'blessed';
use Path::Class;
use strictures 1;

has 'types', is => 'rw', default => sub {+{}};
has 'filename', is => 'rw';
has 'environments', is => 'ro', default => sub {+{}};

# take a prefix:name, and convert into {URI}name
sub resolve_datatype_name {
  my ($self, $in) = @_;
  my ($prefix, $name) = split /:/, $in, 2;
  my $uri = $self->get_datatype_prefix($self->filename, $prefix);
  if (not $uri) {
    die "Use of undeclared prefix $prefix in datatype name $in";
  }
  return "{$uri}$name";
}

# "Document" name, a name that will appear in the final document.
# ?? Includes?
sub resolve_document_name {
  my ($self, $in) = @_;

  #print "Resolving document name $in in filename", $self->filename, "\n";
  # Dump $self->environments;

  if ($in eq '*') {
    # This is a special case, a magic name that matches everything.
    return '*';
  }

  my ($prefix, $name) = split /:/, $in, 2;
  if (!$name) {
    # a name without an explict namespace should get the default.
    my $name = $prefix;
    my $uri = $self->environments->{$self->filename}{default_namespace};
    my $full_name = "{$uri}$name";
    #print "Resolved to $full_name (default)\n";
    return $full_name;
  }
  my $uri = $self->get_namespace_prefix($prefix);
  if (not $uri) {
    die "Use of undeclared prefix $prefix in document name $in";
  }

  my $full_name = "{$uri}$name";
  #print "Resolved to $full_name (known prefix)\n";
  return $full_name;
}

sub do_preamble {
  my ($self, $preamble) = @_;

  if (!$self->filename) {
    die "Unknown filename";
  }

  for my $key (keys %$preamble) {
    if ($key =~ m/^datatype_prefix_(.*)$/) {
      $self->environments->{$self->filename}{datatype_prefixes}{$1} = $preamble->{$key};
    } elsif ($key =~ m/^namespace_prefix_(.*)$/) {
      $self->environments->{$self->filename}{namespace_prefixes}{$1} = $preamble->{$key};
    } elsif ($key =~ '__default_namespace') {
      $self->environments->{$self->filename}{default_namespace} = $preamble->{$key};
    } else {
      Dump $preamble;
      die "$key";
    }
  }
}

sub do_include {
  my ($self, $args) = @_;

  print "***do_include***\n";
  Dump $args;

  if ($args->{inherit}) {
    die "do_include inherit not handled";
  }

  if ($args->{include_body}) {
    die "do_include include_body not handled";
  }

  my $subschema_filename = $args->{uri};
  print "base_filename = ".$args->{base_filename}."\n";
  my $base_filename = Path::Class::File->new($args->{base_filename});
  print "Trying to include $subschema_filename from inside $args->{base_filename}\n";
  $subschema_filename = $base_filename->dir->file($subschema_filename);

  if (!-e $subschema_filename and -e ($subschema_filename.".rnc")) {
    $subschema_filename .= ".rnc";
  }

  if (!-e $subschema_filename) {
    die "Can't find $subschema_filename (or $subschema_filename.rnc)";
  }

  my $subschema = do {local (@ARGV, $/) = $subschema_filename; <>};

  my $old_filename = $self->filename;
  $self->filename($subschema_filename);

  XML::RelaxNG::Compact->parse_compact($subschema, $self, $subschema_filename);
  ## This needs a fresh TopThingy else it overwrites the namespaces, which can be different in the included files.
  #my $top_include = XML::RelaxNG::Compact->parse_compact($subschema, $toplevel, $subschema_filename);
  #push @{ $self->includes }, $top_include;
  $self->filename($old_filename);
}

sub add_type {
  my ($self, $part_type) = @_;

  if (not blessed $part_type) {
    Dump $part_type;
    die "Unblessed part type";
  }

  if (!$self->types->{$part_type->name}) {
    $self->types->{$part_type->name} = $part_type;
    return $part_type;
  } else {
    $self->types->{$part_type->name}->merge($part_type);
    return $part_type;
  }

}

sub get_start {
  $_[0]->types->{'__start'};
}

sub get_type {
  my ($self, $type_name) = @_;
  if (exists $self->types->{$type_name}) {
    return $self->types->{$type_name};
  }

  foreach my $inc (@{ $self->includes }) {
    my $type_in_inc = $inc->get_type($type_name);
    return $type_in_inc if $type_in_inc;
  }

  Dump $self;
  die "While trying to get_type $type_name, fell off the bottom";
}

sub get_datatype_prefix {
  my ($self, $filename, $datatype_name) = @_;

  my $uri = $self->environments->{$filename}{datatype_prefixes}{$datatype_name};

  if (!$uri) {
    die "Cannot find datatype prefix $datatype_name in filename $filename";
  }

  return $uri;
}

sub get_namespace_prefix {
  my ($self, $namespace_name) = @_;
  my $uri = $self->environments->{$self->filename}{namespace_prefixes}{$namespace_name};
  return $uri if $uri;

  die "Don't know namespace $namespace_name in file ".$self->filename;
}

sub from_dom {
  # Nice names.
  my ($top, $dom, $rest) = @_;

  if (not blessed $top->get_start) {
    Dump $top->get_start;
    die "from_dom on a TopThingy where start is not blessed";
  }

  $top->get_start->from_dom($dom, $rest);
}

sub to_dom {
  my ($top, $object) = @_;

  my $document = XML::LibXML::Document->new;

  $top->get_start->to_dom($object, $document);
}

1;
