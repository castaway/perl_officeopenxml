package XML::RelaxNG::Utils;
use strictures 1;
use Data::Dump::Streamer 'Dump', 'Dumper';
use feature 'state';
use XML::LibXML;

sub full_name {
  my ($node, $namespaces, $class);
  if(@_ > 1) {
      my %args = @_;
      $node = $args{dom};
      $namespaces = $args{namespaces};
      $class = $args{class};
      #Dump $namespaces;
  } else {
      $node = $_[0];
  }

  if ($node->nodeType == XML_TEXT_NODE) {
    return '__text__';
  }

  if (!$node->localname) {
    die "WTF, node with no localname";
  }

  if (!$node->namespaceURI) {
    print "Hmm, got a node with no namespace, looking it up\n";
    for my $ns (values %$namespaces) {
        my $test = "{$ns}" . $node->localname;
        print "Trying.. $test\n";
        return $test if($class->has_attribute($test));
    }
    
    warn "Nope, still can't find the namespace for " . $node->localname;
    return "{".$node->parentNode->namespaceURI."}".$node->localname;
  }
  
  return "{" . $node->namespaceURI . "}" . $node->localname;
}

=item class_name

     my $name = XML::RelaxNG::Utils::class_name("{http://foo.bar/baz/}merp");

Returns a class name corresponding to the passed in {uri}name.

=cut

state $namespaces = {
                     'http://schemas.openxmlformats.org/presentationml/2006/main' => "XML::OpenXMLFormats::PresentationML::_2006::Main",
                     'http://schemas.openxmlformats.org/drawingml/2006/main'      => "XML::OpenXMLFormats::DrawingML::_2006::Main",
                     'http://schemas.openxmlformats.org/package/2006/relationships' => 'XML::OpenXMLFormats::Package::_2006::Relationships',
                    };

sub class_name {
  my ($name) = @_;

  my ($namespace, $localname) = ($name =~ m!^{(.*?)}(.*)$!);
  
  if (exists $namespaces->{$namespace}) {
    return $namespaces->{$namespace} . "::" . $localname;
  }

  die "Don't know name for $name";
}

'this:that';
