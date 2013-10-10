package XML::RelaxNG::Group;
use Moose;
use Data::Dump::Streamer 'Dump', 'Dumper';
use Scalar::Util 'blessed';
use Try::Tiny;
use XML::LibXML;
use XML::RelaxNG::Utils;
use strictures 1;

has 'members', is => 'rw', default => sub { [] };

has 'member_map', is => 'ro', lazy => 1, 
  default => sub {
    my ($self) = @_;

    my $map = {attribute => {},
               element => {},
               text => []};

    for my $member (@{$self->members}) {
      if(!blessed $member) {
        Dump($member);
        die "Unblessed member in Group members?? $member";
      }
      my $debug_string = $member->as_debug_string;
      my $node_type = $member->node_type;

      die "'*' not yet supported" if $debug_string =~ m/\*/;

      if ($node_type == XML_TEXT_NODE) {
        push @{$map->{text}}, $member;
      } elsif ($node_type == XML_ATTRIBUTE_NODE) {
        # Store both with namespace and without  (FIXME: This is probably better fixed in Utils's full_name.)
        my @names = ($member->xml_name, $member->name);
        $map->{attribute}{$_} = $member for @names;
      } elsif ($node_type == XML_ELEMENT_NODE) {
        my @names = ($member->xml_name, $member->name);
        $map->{element}{$_} = $member for @names;
      } else {
        die;
      };
    }

    return $map;
  };

sub add_attributes_for_class {
  my ($self, $class, $element) = @_;

#  my $map = $self->member_map;

  my @ret;

#  for my $xml_subthingy (values %{$map->{attribute}}, values %{$map->{element}}, @{$map->{text}}) {
  for my $xml_subthingy (@{ $self->members }) {
    push @ret, $xml_subthingy->add_attributes_for_class($class, $element);
  }

  return @ret;
}

sub as_debug_string {
    my ($self) = @_;

    # return join(", ", map { ref $_ eq 'HASH' ? keys %$_ : '<text?>' } values(%{ $self->member_map }));
    my $out;
    if (scalar (keys %{$self->member_map->{attribute}}) > 0) {
        $out .= "attrs: ";
        $out .= join(', ', map {$_->as_debug_string} values %{$self->member_map->{attribute}});
    }

    if (scalar (keys %{$self->member_map->{element}}) > 0) {
        $out .= "elems: ";
        $out .= join(', ', map {$_->as_debug_string} values %{$self->member_map->{element}});
    }

    if (@{$self->member_map->{text}}) {
        $out .= "text: ";
        $out .= join(', ', map {$_->as_debug_string} @{$self->member_map->{text}});
    }

    return $out;
}

sub is_arrayref {
  my ($self, $child) = @_;
  
  my $map = $self->member_map;
  my $type = $child->nodeType;
  
  if ($type == XML_NAMESPACE_DECL) {
    # We don't give values for these at all, so it doesn't matter what we return, so long as we don't die.
    return undef;
  }

  my $child_full_name = XML::RelaxNG::Utils::full_name($child);
  my $child_name = $child->localname;
  
  if ($type == XML_ATTRIBUTE_NODE) {
    my $attr = $map->{attribute}{$child_full_name} || $map->{attribute}{$child_name};
    if ($child_full_name =~ m!^\{http://schemas.openxmlformats.org/markup-compatibility/2006\}!) {
      # Do nothing
      return;
    }
    if(!$attr) {
      print "Attribute: ", $child->toString, "\n";
      print "Pattern: ", $self->as_debug_string, "\n";
      die "Can't find child for attribute";
    }
    return $attr && $attr->is_arrayref($child);

  } elsif ($type == XML_ELEMENT_NODE) {
    my $ele = $map->{element}{$child_full_name} || $map->{element}{$child_name};
    if (!$ele) {
      print "Element: ", $child->toString, "\n";
      print "Pattern: ", $self->as_debug_string, "\n";
      die "Can't find child for element";
    }
    return $ele->is_arrayref($child);

  } else {
    return 1;
  }
}

sub result_name {
    my ($self, $dom) = @_;
    
    my $child_full = XML::RelaxNG::Utils::full_name($dom);

    return $child_full;
}

sub from_dom {
  my ($self, $dom, $rest) = @_;

  my @ret;

  print "group from_dom ", $self->as_debug_string, "\n";
  my $map = $self->member_map;
  #print "MAP: ", Dumper($map);

  my $values;

  if (!ref $dom) {
    # This is plain ole literal text.
    return $dom;
  }

  my $child = $dom;
  
  my $child_type = $child->nodeType;
  
  return if $child_type == XML_NAMESPACE_DECL;
  
  my $child_full_name = XML::RelaxNG::Utils::full_name($child);
  print "Looking at: $child_full_name\n";

  my $child_name = $child->localname;
  
  if ($child_type == XML_ATTRIBUTE_NODE) {
    my $attr = $map->{attribute}{$child_full_name} || $map->{attribute}{$child_name};
    
    if (not $attr) {
      #### FIXME: Temporary hack to ignore the "markup compatability" gubbins.
      if ($child_full_name =~ m!^\{http://schemas.openxmlformats.org/markup-compatibility/2006\}!) {
        # Do nothing
        return;
      } else {
        Dump $map;
        print STDERR "Attributes in group:\n";
        print STDERR " $_\n" for sort keys %{$map->{attribute}};
        print "dom asString: ", $dom->toString, "\n";
        print "child asString: ", $child->toString, "\n";
        die "Hmm, trying to from_dom an attribute named $child_name, which doesn't seem to be in this group?";
      }
    }
    
    return $attr->from_dom($child, $rest);
    
  } elsif ($child_type == XML_ELEMENT_NODE) {
    my $ele = $map->{element}{$child_full_name} || $map->{element}{$child_name};
    if (not $ele) {
      Dump $map;
      print STDERR "Elements in group:\n";
      print STDERR " $_\n" for sort keys %{$map->{element}};
      print "dom asString: ", $dom->toString, "\n";
      print "child asString: ", $child->toString, "\n";
      die "Hmm, trying to from_dom an element named $child_name, which doesn't seem to be in this group?";
    }
    
    print "ISA $ele\n";
    return $ele->from_dom($child, $rest)
  } elsif ($child_type == XML_NAMESPACE_DECL) {
    return;
  } elsif ($child_type == XML_TEXT_NODE) {
    my $val = $child->data;
    print "Text child, '$val'\n";
    if (!$map->{text} and $val =~ m/^\s*$/) {
      # If there's no text child declared against this group, but the text is just whitespace anyway, ignore it.
      return;
    } elsif (!$map->{text}) {
      die "No text handler defined";
    } else {
      return $map->{text}->from_dom($child, $rest);
    }
  } else {
    print $child->toString;
    die "Child of unhandled type $child_type";
  }
  #  }
  
  die "how did we get here??";
}

sub to_dom {
  my ($self, $value) = @_;
  
  print "to_dom($self, $value)\n";
  my @ret;

  for my $member (@{$self->members}) {
    print "Group.pm to_dom member ", $member->as_debug_string, "\n";

    my $method_name = $member->long_name;
    my $pred_name = "has_$method_name";
    next if $method_name eq '__text__';
    next if !$value->$pred_name;

    my $this_value = $value->$method_name;
    push @ret, $member->to_dom($this_value);
  }

  return @ret;
}

sub node_type {
    print "node_type of: ".$_[0]->members->[0]."\n";
    Dump($_[0]->members->[0]) if(!blessed $_[0]->members->[0]);
    $_[0]->members->[0]->node_type;
}

## If we have a choice included as a member of a group, we return all the choices members
## This isn't quite straight as it ignores any limits on the appearances of that choice
sub xml_name {
  map {$_->xml_name} @{$_[0]->members};
}

sub name {
  map {$_->name} @{$_[0]->members};
}

'apple,orange,elephant';
