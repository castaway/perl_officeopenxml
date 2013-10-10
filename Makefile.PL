#!/usr/bin/perl
use ExtUtils::MakeMaker;
use warnings;
use strict;

WriteMakefile(
              NAME => 'XML::RelaxNG::Compact',
              VERSION_FROM => 'lib/XML/RelaxNG/Compact.pm',
              PREREQ_PM => {
                            'Moose' => 0,
                            'PadWalker'=> 0, # Data::Dump::Streamer depends on this, but doesn't list it
                            'Data::Dump::Streamer' => 0,
                            'Parse::Eyapp' => 0,
                            'strictures' => 0,
                            'indirect' => 0,
                            'XML::LibXML' => 0,
                            'Path::Class' => 0,
                            'MooseX::StrictConstructor' => 0,
                            'Archive::Zip' => 0,
                           }
             );
