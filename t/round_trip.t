#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $input_file = 't/data/fyp.pptx';

use_ok('XML::OpenXMLFormats::PresentationML');

my $pres = XML::OpenXMLFormats::PresentationML->new(
    file => $input_file,
    );

$pres->save('t/var/round_trip_test');
#$pres->test_to_dom();

done_testing;
