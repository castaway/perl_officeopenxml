#!/usr/bin/perl
use XML::RelaxNG::Compact;
use XML::LibXML;
use Path::Class 'dir';
#use Data::Dump::Streamer;
use Data::Dumper;
use strictures 1;

my ($schema_file, $file) = @ARGV;

my $schema = do {local (@ARGV, $/) = $schema_file; <>};
my $topthingy = XML::RelaxNG::Compact->parse_compact($schema, undef, $schema_file);


#my $pdir = dir($schema_dir);

# my %schemata = ();
# $pdir->traverse(sub {
#                   my ($child, $cont) = @_;
#                   if($child->is_dir) {
#                     return $cont->();
#                   }

#                   return if ($child->basename !~ /\.rnc$/);
#                   print "Parsing $child\n";
#                   my $schema = do {local (@ARGV, $/) = $child->stringify; <>};
#                   my $topthingy = XML::RelaxNG::Compact->parse_compact($schema);
#                   $schemata{$child->stringify} = $topthingy;
#                 });
# Dump(\%schemata);

my $dom = XML::LibXML->load_xml(location => $file);

#Dump($topthingy->from_dom($dom))->Purity(0)->OptSpace(' ')->Out;
print Dumper($topthingy->from_dom($dom));
