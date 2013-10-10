package XML::OpenXMLFormats::Reference;
use strictures 1;
use Moose;
use MooseX::StrictConstructor;
use Data::Dump::Streamer;

use overload '""' => sub { return $_[0]->rid }, fallback => 1;

has 'rid', is => 'ro';
has 'rest', is => 'ro';

sub DDS_freeze {
  my ($self) = @_;

  my $proxy = {%$self};
  $proxy->{rest} = 'value hidden by Reference.pm DDS_freeze';

  return ($proxy, undef, undef);
}

sub dereference {
  my ($self) = @_;
  
  my $rest = $self->rest;

  my $from_uri = $rest->{uri};
  my $rid = $self->rid;
  print "Dereference from $from_uri to $rid\n";

  # FIXME: Can URI do this?
  $from_uri = Path::Class::File->new($from_uri);
  my $path = $from_uri->parent;
  my $basename = $from_uri->basename;
  $path = $path->subdir('_rels');
  my $rels_uri = $path->file($basename . '.rels');

  print "Rels file at $rels_uri\n";

  my $rels = $rest->{presentation}->parsed($rels_uri);
  #Dump $rels;
  my $relref = $rels->get_by_id($self->rid);
  my $target = $relref->Target()->as_string;
  $target = $from_uri->parent->file($target);
  my $rel = $rest->{presentation}->parsed($target->stringify);

  #Dump $rel;

  return $rel;
}

'->';
