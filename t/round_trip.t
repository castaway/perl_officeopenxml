#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $input_file = 't/data/fyp.pptx';

use_ok('XML::OpenFormats::PresentationML');

my $pres = XML::OpenFormats::PresentationML->new(
    file => $input_file,
    );

$pres->test_to_dom();

done_testing;
