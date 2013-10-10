package XML::RelaxNG::Element;
use Moose;
use Data::Dump::Streamer 'Dump','Dumper';
use feature 'say', 'state';
use strictures 1;
use XML::LibXML;
use XML::RelaxNG::Utils;
use Moose::Util::TypeConstraints;
use Class::Load 'load_optional_class';
use Module::Runtime 'module_notional_filename';

subtype 'namespaced_name', as 'Str', where { $_ eq '*' or $_ =~ /^\{.*?\}.*$/};
has 'rnc_file', is => 'ro', required => 1;
has 'top', is => 'ro', required => 1;
# ???
has 'name', is => 'ro', isa => 'Str';
# full_name: {http://foo.bar.com/asdf/namespace}tag
# (or "*")
has 'full_name', is => 'ro', isa => 'namespaced_name';
has 'pattern', is => 'ro';
# The name of the perl class that this element will get parsed into
has 'class_name', is => 'ro', lazy => 1,
  default => sub {
    my ($self) = @_;
    my $class_name = XML::RelaxNG::Utils::class_name($self->full_name);
  };
has 'class', is => 'ro', lazy => 1,
    default => sub {
      my ($self) = @_;
      my $class_name = $self->class_name;
      print "Optionally loading class $class_name\n";
      load_optional_class($class_name);

      my $class = Moose::Meta::Class->create($class_name);

      $self->ordered_attributes([$self->pattern->add_attributes_for_class($class, $self)]);

      my $local_names;

      for my $attr ($class->get_all_attributes) {
        # $attr is a Moose::Meta::Attribute / Class::MOP::Attribute
        my $name = $attr->name;
        next unless ($name =~ m/^\{(.*)\}(.*)$/);
        my ($ns, $local) = ($1, $2);
        $local_names->{$local}{count}++;
        $local_names->{$local}{moose_attr} = $attr;
      }

      for my $name (keys %$local_names) {
        next unless $local_names->{$name}{count} == 1;
        my $long_name = $local_names->{$name}{moose_attr}->name;
        print "Making alias $name for $long_name\n";
        $class->add_method($name => sub {
                             my $self = shift; 
                             $self->$long_name(@_);
                           });
        # Possible room for future expansion: when a thing is ambigious, give a useful error.
      }

      print ">>> constructed class named $class_name, our ordered attributes\n";
      print " - $_\n" for map {$_->name} @{$self->ordered_attributes};
      print ">>> attribute mapping\n";
      for my $value (@{$self->attribute_mapping}) {
        my $mma = $value->{mma};
        my $rng = $value->{rng}->full_name;
        my $name = $mma->name;
        print " - $name => mma=$mma, rng=$rng\n";
      }
      print "\n";
      
      return $class;
    };
has 'ordered_attributes', is => 'rw', default => sub {[]};
has 'attribute_mapping',  is => 'rw', default => sub {[]};

sub namespace_uri {
  my ($self) = @_;
  my $full = $self->full_name;

  if ($full eq '*') {
    return '*';
  }
  
  $full =~ m/^\{(.*?)\}(.*)$/ or die "Can't parse $full";

  my ($ns, $local) = ($1, $2);
  return $ns;
}

sub add_attributes_for_class {
  my ($self, $class, $element) = @_;

  # Note that this is adding attributes to a class that can have this
  # element as a child, not to the class that represents this element
  # itself (unless, of course, this element can contain itself).

  print "Element add_attributes_for_class: ", $self->as_debug_string, "\n";

  my $long_name = $self->full_name;

  print "Element $long_name\n";
  my $mma = $class->add_attribute($long_name, {
                                               is => 'rw',
                                               accessor => $long_name,
                                               init_arg => $long_name,
                                               predicate => "has_${long_name}",
                                               # isa, default, lazy
                                              });
  $element->add_attribute($long_name, $mma, $self);
  return $mma;
}

sub add_attribute {
  my ($self, $long_name, $mma, $rng_thingy) = @_;

  # Called by a subelement of this element, or an attribute, to let us know about an element or attribute that can be a subnode of us.
  # $mma should be a Moose::Meta::Attribute
  # $rng_thingy should be a XML::RelaxNG::{Attribute,Element} (or a text?)

  push @{ $self->attribute_mapping }, { mma => $mma, rng => $rng_thingy };

#  $self->attribute_mapping->{$long_name}{mma} = $mma;
#  $self->attribute_mapping->{$long_name}{rng} = $rng_thingy;

  'You forgot to return the right thing, you dufus';
}



sub is_arrayref {
  my ($self, $dom) = @_;

  return undef;
}

sub result_name {
    return $_[0]->full_name;
}

sub as_debug_string {
  my ($self) = @_;

  return "Element ".$self->name;
}

sub node_type {
  XML_ELEMENT_NODE;
}

sub xml_name {
  $_[0]->full_name;
}

sub from_dom {
  my ($self, $dom, $rest) = @_;

  print "Element from_dom ", $self->name, "\n";
  my $dom_doc;
  if ($dom->isa('XML::LibXML::Document')) {
    $dom_doc = $dom;
    $dom = $dom->documentElement;
  }

  if (!$dom->isa('XML::LibXML::Element')) {
    die "Tryping to parse an element, but got a ".$dom;
  }

  # FIXME: Pay proper attention to namespaces.
  #say "Node namespace: ", $dom->namespaceURI;
  my $dom_full_name = "{".$dom->namespaceURI."}".$dom->localname;
  if ($dom_full_name ne $self->full_name) {
    die "Expected ".$self->name.", got ".$dom_full_name;
  }

  my $ret_class = $self->class;
  my $ret;
  if($dom_doc) {
    ## Set the original filename on the toplevel element:
    $self->class->add_attribute('_filename', 
                                {
                                 is => 'ro',
                                 reader => '_filename',
                                 predicate => 'has__filename',
                                });
    $ret = $ret_class->new_object( '_filename' => $dom_doc->URI());
  } else {
    $ret = $ret_class->new_object();
  }
#  my $ret = {};
  # Hmm, shouldn't this specify "the inside of" somehow?
  #my @children;
  #for my $child ($dom->childNodes) {
  #  push @children, $self->pattern->from_dom($child);
  #}
  print "Element pattern " . $self->pattern . "\n";
  #$ret->{content} = $self->pattern->from_dom($dom, $dom->attributes, $dom->childNodes);
  foreach my $child ($dom->attributes, $dom->childNodes) {
    next if $child->isa('XML::LibXML::Namespace');
    
    my $result = $self->pattern->from_dom($child, $rest);
    ## Group.pm returns undef when it encounters an Attribute in the http://schemas.openxmlformats.org/markup-compatibility/2006 namespace
    ## however so do the values for booleans, which we'll need to (un)fix
    next if !defined $result;

#    print "Top's filename: ", $self->top->filename, "\n";
#    Dump($self->top->environments);
    my $full_name = XML::RelaxNG::Utils::full_name(
        namespaces => $self->top->environments->{$self->rnc_file}{namespace_prefixes},
        dom => $child,
        class => $self->class,
        );

    print "Have an element child, full_name=$full_name\n";
    
    if ($child->nodeType == XML_TEXT_NODE) {
      $full_name = '__text__';
    }
    
    if ($self->pattern->is_arrayref($child)) {
      if (!$ret->$full_name) {
        $ret->$full_name([]);
      }
      push @{$ret->$full_name}, $result;
    } else {
      $ret->$full_name($result);
    }
  }
  
#  $ret = bless $ret, $self->class_name;

  # So, we need to return something that encodes the element, and pass on the contents of the element to our "pattern"?
  # Stub it in for now.
  return $ret;
}

sub get_ns_prefix {
  my ($self, $document, $uri) = @_;
  my $dockey = $document->unique_key;
  state $ns_maps = {};
  state $next_ns = 0;

  my $prefix = $ns_maps->{$dockey}{$uri};

  if (!$prefix) {
    $prefix = "ns".$next_ns++;
    $ns_maps->{$dockey}{$uri} = $prefix;
    # Avoid bootstrapping issues when we are trying to find the prefix we should use for the root element.
    #if ($document->documentElement) {
    #  $document->documentElement->setNamespace($uri, $prefix, 0);
    #}
  }

  return $prefix;
}

sub to_dom {
  my ($self, $value, $document) = @_;

  print "to_dom($self, $value)\n";
  print " self=", $self->as_debug_string, "\n";

  if ($self->name eq '*') {
    return $document->createElement('fixmestarelement');
  }
   
  my $node = $document->createElementNS($self->namespace_uri, $self->get_ns_prefix($document, $self->namespace_uri) . ':' . $self->name);

  #if (!$document->documentElement) {
  #  # If the document has no document element, then we must be the root ourselves.
  #  $document->setDocumentElement($node);
  #}

  my $values;
  if (ref $value ne 'ARRAY') {
    $values = [ $value ];
  } else {
    $values = $value;
  }

  for my $value (@$values) {
    my $got_it;

    ## Must do all these things in order! Make sure all the things return lists.. 
#    for my $attr_name (keys %{$self->attribute_mapping}) {
    for my $attr (@{$self->attribute_mapping}) {
      my $attrib = $attr->{mma};
      my $relaxngthing = $attr->{rng};
      my $method_name = $attrib->name;
      my $pred_name = $attrib->predicate;

      print "In Element.pm to_dom, value $value vs self's attribute $method_name\n";
      # FIXME: I thought we got rid of __text__.  To boot, why doesn't __text__ have a predicate?
      next if $method_name eq '__text__';
      next if !$value->$pred_name;
      
      my $this_value = $value->$method_name;
      print "And the value of this thing is $this_value\n";
#      my $relaxngthing = $self->get_relaxng_thing_for($method_name);
      print "Found it? $relaxngthing for $method_name\n";
      my $subnode = $relaxngthing->to_dom($this_value, $document);
      print "Trying to take node=", $node->toString, "\n";
      print "...and append child subnode: ", $subnode, "\n";
      #} elsif ($subnode->isa('XML::LibXML::Attr')) {
      if (ref($subnode) eq 'HASH') {
        print ".. which is really a $subnode->{name}, $subnode->{value}\n";
        # XML::LibXML is surprisingly full of TODOs.
        #my $ns = $subnode->namespaceURI();
        #my $name = $subnode->nodeName;
        #my $value = $subnode->nodeValue;
        $DB::single=1;
        $node->setAttributeNS($subnode->{ns}, $self->get_ns_prefix($document, $subnode->{ns}) . ':' . $subnode->{name}, $subnode->{value});
      } elsif ($subnode->isa('XML::LibXML::Element')) {
        $node->appendChild($subnode);
      } else {
        die "Don't know how to append $subnode";
      }
    }
  }
  
  return $node;
}

has 'relaxng_things_for', is => 'ro', default => sub {{}};
sub get_relaxng_thing_for {
  my ($self, $long_name) = @_;

  if (exists $self->relaxng_things_for->{$long_name}) {
    return $self->relaxng_things_for->{$long_name};
  }

  if ($self->full_name eq '*') {
    print "Matching $long_name against an Element *\n";
    $self->relaxng_things_for->{$long_name} = $self;
    return $self;
  }

  if ($self->full_name eq $long_name) {
    $self->relaxng_things_for->{$long_name} = $self;
    return $self;
  }

  $self->relaxng_things_for->{$long_name} = $self->pattern->get_relaxng_thing_for($long_name);
  return $self->relaxng_things_for->{$long_name};
}

1;
