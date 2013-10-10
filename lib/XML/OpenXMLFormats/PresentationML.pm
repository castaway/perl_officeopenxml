package XML::OpenXMLFormats::PresentationML;
use strictures 1;
use XML::RelaxNG::Compact;
use Archive::Zip;
use XML::OpenFormats::FileSource::Zip;
use Moose;
use Data::Dump::Streamer 'Dump', 'Dumper';

## This should probably inherit from a base class which knows how to extrct XML from the input files via the relaxng schema
## we just set its paths and off it goes.. ideally.

has 'file', is => 'ro';
has 'dir', is => 'ro';
has 'opc_relaxng_path', is => 'ro', default => '/mnt/shared/projects/work/pptx/spec/opc-relaxng/';
has 'transitional_relaxng_path', is => 'ro', default => '/mnt/shared/projects/work/pptx/spec/transitional-relaxng/';

has 'element_rnc_map',
  is => 'ro', 
  # Make sure that ..._relaxng_path is inited first.
  lazy => 1,
  default => sub {
  my ($self) = @_;
  +{
    '{http://schemas.openxmlformats.org/presentationml/2006/main}presentation'    => $self->transitional_relaxng_path . 'PresentationML_Presentation.rnc',
    '{http://schemas.openxmlformats.org/package/2006/relationships}Relationships' => $self->opc_relaxng_path .'opc-relationships.rnc'
   }
};

has 'source', is => 'ro', lazy => 1,
  default => sub {
    my ($self) = @_;
    
    # Rest can be a filename, in which case it's a zipped-up presentation, the normal case.
    if ($self->file) {
      return XML::OpenFormats::FileSource::Zip->new(file => $self->file);
    } elsif ($self->dir) {
      return XML::OpenFormats::FileSource::Dir->new(dir => $self->dir);
    } else {
      die "Must specify one of file, dir, or source";
    }
  };

has '_topthingys', is => 'ro', default => sub { {} };

sub topthingys {
    my ($self, $rnc) = @_;
    
    if(!exists $self->_topthingys->{$rnc}) {
      my $rels_rnc = do {local (@ARGV, $/) = $rnc; <>};
      $self->_topthingys->{$rnc} = XML::RelaxNG::Compact->parse_compact($rels_rnc, undef, $rnc);
    }

    return $self->_topthingys->{$rnc};
  };

## All the aready parsed XML things!
has '_parsed', 'is' => 'ro', default => sub { {} };
sub parsed {
  my ($self, $ooxml_path) = @_;

  ## Can we just pass in the XML (Target) and the Type and map to the rnc from there?
  if(!exists $self->_parsed->{$ooxml_path}) {
    my $dom = XML::LibXML->load_xml(string => $self->source->get_file($ooxml_path));
    $dom->setURI($ooxml_path);

    my $root_name = XML::RelaxNG::Utils::full_name($dom->documentElement);
    my $topthingy;
    if (exists $self->element_rnc_map->{$root_name}) {
      $topthingy = $self->topthingys($self->element_rnc_map->{$root_name});
    } else {
      die "Don't know where to find rnc file for root element $root_name";
    }

    ## FIXME: "presentation" key ought to be something more generic
    ## Used by Reference to parse the related relationships file.
    $self->_parsed->{$ooxml_path} = $topthingy->from_dom($dom, 
                                                         {
                                                          source => $self->source,
                                                          presentation => $self,
                                                          uri => $ooxml_path
                                                         });
  }

  return $self->_parsed->{$ooxml_path};
}

has 'root_rels', is => 'ro', lazy => 1,
  default => sub {
    my ($self) = @_;

    return $self->parsed('_rels/.rels');
  };

has 'main_presentation', is => 'ro', lazy => 1,
  handles => [qw/slides slide_ids/],
  default => sub {
    my ($self) = @_;

    my $ooxml_path = $self->root_rels->Relationship->[0]->Target()->as_string;

    return $self->parsed($ooxml_path);
  };

sub save {
  my ($self, $dir) = @_;

  my $root_rels = $self->root_rels;
  my $dom = $self->topthingys($self->opc_relaxng_path .'opc-relationships.rnc')->to_dom($root_rels);
  
  ## Hardcoding the location of the root rels file inside here is considered a Good Thing; the opc spec hardcodes it (FIXME: confirm, add reference).
  $dir = Path::Class::Dir->new($dir);
  my $out_path = $dir->file("_rels/.rels");
  $self->source->save_file($dom, $out_path);

  # A bunch of 
  my @rels_to_dump = @{$self->root_rels->Relationship};
  my %dumped;

  while (@rels_to_dump) {
    my $related = shift @rels_to_dump;

    $out_path = $dir->file($related->Target()->as_string);
    my $obj = $self->parsed($related->Target()->as_string);
    my $dom = $self->topthingys($self->transitional_relaxng_path . 'PresentationML_Presentation.rnc')->to_dom($obj);
    $self->source->save_file($dom, $out_path);

    # push @rels_to_dump ...
  }
}

sub test_to_dom {
  my ($self) = @_;

  my $rels = $self->topthingys($self->opc_relaxng_path .'opc-relationships.rnc')->to_dom($self->root_rels);

  print "TO_DOM (rels): \n";
  print $rels->toString(2);

  my $pres = $self->main_presentation;
  print "Presentation, from_dommed\n";
  Dump $pres;

  print "TO_DOM (presentation): \n";
  print $self->topthingys($self->transitional_relaxng_path . 'PresentationML_Presentation.rnc')->to_dom($pres)->toString(2);
}

'blah blah blah';
