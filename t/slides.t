#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump::Streamer 'Dump', 'Dumper';

use Test::More;

my $input_file = 't/data/fyp.pptx';

use_ok('XML::OpenXMLFormats::PresentationML');

my $pres = XML::OpenXMLFormats::PresentationML->new(
    file => $input_file,
    );

#use Data::Dumper;
print Dump($pres->root_rels)->Purity(0)->Out();

# is($pres->version, '2006', 'Version of doc is 2006');
is(scalar $pres->slide_ids, 16, 'Got 16 slide referencess from doc');

print "MAIN PRESENTATION " , Dumper($pres->main_presentation);
# $pres->main_presentation->dump;

foreach my $slide ($pres->slides) {
    isa_ok($slide, 'XML::OpenXMLFormats::PresentationML::_2006::Main::sld');
}

done_testing;
