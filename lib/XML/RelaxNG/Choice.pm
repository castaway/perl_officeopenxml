package XML::RelaxNG::Choice;
use Moose;
extends 'XML::RelaxNG::Group';

"('this' or 'that') and not ('this' and 'that')";
