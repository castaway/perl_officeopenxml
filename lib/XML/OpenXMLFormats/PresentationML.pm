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
  my ($self, $rnc, $ooxml_path) = @_;

  ## Can we just pass in the XML (Target) and the Type and map to the rnc from there?
  if(!exists $self->_parsed->{$ooxml_path}) {
    my $dom = XML::LibXML->load_xml(string => $self->source->get_file($ooxml_path));
    $dom->setURI($ooxml_path);
    ## FIXME: "presentation" key ought to be something more generic
    ## Used by Reference to parse the related relationships file.
    $self->_parsed->{$ooxml_path} = $self->topthingys($rnc)->from_dom($dom, 
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

    return $self->parsed($self->opc_relaxng_path .'opc-relationships.rnc', '_rels/.rels');
  };

has 'main_presentation', is => 'ro', lazy => 1,
  handles => [qw/slides slide_ids/],
  default => sub {
    my ($self) = @_;

    my $ooxml_path = $self->root_rels->Relationship->[0]->Target()->as_string;

    return $self->parsed($self->transitional_relaxng_path . 'PresentationML_Presentation.rnc', $ooxml_path);
  };

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
