package XML::RelaxNG::Compact;
use strictures 1;
use Data::Dump::Streamer 'Dump';
use feature 'state';
use XML::RelaxNG::Compact::Parser;
use XML::RelaxNG::TopThingy;

# http://relaxng.org/compact-tutorial-20030326.html

sub parse_compact {
  my ($self, $string, $topthingy, $filename) = @_;

  $topthingy ||= XML::RelaxNG::TopThingy->new(filename => $filename);
  die "filename is required" if !$filename;
  
  my $tokens = $self->tokenize_compact($string);
  #Dump $tokens;
  my $parser = XML::RelaxNG::Compact::Parser->new;
  $|=1;
  $parser->{USER}{topthingy} = $topthingy;
  $parser->{USER}{filename} = $filename;

  $parser->YYParse(yylex => sub {
                     if (!@$tokens) {
                       return ('', undef);
                     }
                     @{shift @$tokens},
                   },
                   yyerror => sub {
                     my ($self) = @_;
                     my $curtok = $self->YYCurtok;
                     my $expect = join ' | ', map {$_ eq '' ? '<empty>' : $_} $self->YYExpect;
                     my $line = $self->YYCurval->[0];
                     my $col  = $self->YYCurval->[1];
                     die "Parse error near $filename line $line column $col, got $curtok, expected $expect";
                   },
                   #yydebug => 0x1F
                  );

  #Dump $topthingy;
  return $topthingy;
}

sub tokenize_compact {
  my ($self, $string) = @_;
  
  my @tokens;

  # http://www.w3.org/TR/REC-xml-names/#NT-NCName
  # Which is to say, http://www.w3.org/TR/REC-xml/#NT-Name without the colon.
  state $namestartchar = qr/[A-Z_a-z\x{C0}-\x{D6}\x{D8}-\x{F6}\x{F8}\x{2FF}\x{370}\x{37D}\x{37F}-\x{1FFF}\x{200C}-\x{200D}\x{2070}-\x{218F}\x{2C00}-\x{2FEF}\x{3001}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFFD}\x{10000}-\x{EFFFF}]/;
  state $namechar = qr/(?:$namestartchar|[-.0-9\xB7\x{0300}-\x{036F}\x{203F}-\x{2040}])/;

  # matches emacs conventions.
  my ($line, $col) = (1, 0);
  while (length $string) {
    my $start = $string;

    {
      my $extract = substr($string, 0, 10);
      #print "($line, $col): $extract\n";
    }

    # FIXME: \namespace should be returned as an "identifier", not a symbol followed by a keyword!
    for my $keyword (qw<namespace default datatypes element attribute list mixed parent empty text notAllowed external grammar div include start string token inherit>) {
      if ($string =~ s/^$keyword\b//) {
        $col += length($keyword);
        push @tokens, [$keyword, [$line, $col, $keyword]];
      }
    }

    for my $symbol (sort {length $b <=> length $a} qw<- + = { } * ? | ( ) & >, ',') {
      if ($string =~ s/^\Q$symbol\E//) {
        $col += length($symbol);
        push @tokens, [$symbol, [$line, $col, $symbol]];
      }
    }

    if ($string =~ s/^## ([^\n]*)//) {
      push @tokens, ['documentation', [$line, $col, $1]];
      $col += length($1);
    }

    if ($string =~ s/^( +)//) {
      $col += length($1);
    }

    if ($string =~ s/^(\cM\cJ|\cJ|\cM)//) {
      $line++;
      $col = 0;
    }

    # OK, now for the somewhat hard bit: strings.
    if ($string =~ s/^(["'])//) {
      my $delimiter = $1;
      $string =~ s/^([^\n]*?)$delimiter//;
      push @tokens, ['literalSegment', [$line, $col, $1]];
      $col += length($1);
    }

    if ($string =~ s/^('''|""")//) {
      my $delimiter = $1;
      $string =~ s/^([.]*?)$delimiter//;
      push @tokens, ['literalSegment', [$line, $col, $1]];
      # FIXME: incorrect if $1 contains a newline.
      $col += length($1);
    }

    if ($string =~ s/^($namestartchar$namechar*:$namestartchar$namechar*)//) {
      push @tokens, ['CName', [$line, $col, $1]];
      $col += length($1);
    }

    if ($string =~ s/^($namestartchar$namechar*:\*)//) {
      push @tokens, ['nsName', [$line, $col, $1]];
      $col += length($1);
    }

    # Keep this after simple keywords
    if ($start eq $string and
        $string =~ s/^($namestartchar$namechar*)\b//) {
      push @tokens, ['identifier', [$line, $col, $1]];
      $col += length($1);
    }

    if ($start eq $string) {
      my $extract = substr($string, 0, 10);
      Dump \@tokens;
      die "Cannot toke relaxng compact near '$extract' at line $line, column $col";
    }
  }
  return \@tokens;
}

1;
