use strict;
use warnings;

for my $file (@ARGV) {
  open my $in_fh, '<', $file or die $!;
  open my $out_fh, '>', "$file.new" or die $!;
  while (my $line = <$in_fh>) {
    $line =~ s{\A(\s*package\s+\S+)\s+(v[0-9.]+);}{$1; our \$VERSION = '$2';};
    $line =~ s{\A(\s*use v5\.24;)}{use strict;};
    $line =~ s{\A(\s*use v5\.(?:38|40|42);)}{use strict;use warnings;};
    $line =~ s{\A(\s*use experimental qw\(lexical_subs signatures\);)}{};
    $line =~ s{\bmy \$target = 'v5\.24';}{my \$target = 'v5.10';};
    $line =~ s{\A(\s*package\s+\S+)\s*\{}{\{$1;};
    $line =~ s{\A(\s*)my\s+sub\b}{${1}sub};
    $line =~ s{(\$\w+(?:(?:->)?(?:\w+(?:\((?:\$\w+|'[^']*')\))?|{\$?\w+}))*)->([@%])((\*)|\{[^\}]+\}|\[[^\]]+\])}{
      $2."\{".$1."\}" . ($4 ? '' : $3);
    }ge;
    $line =~ s{(\bsub((?:\s+\w+)?)\s+\((.*?)\)\s*\{)}{
      my $orig = $1;
      my $name = $2;
      my $params = $3;
      $params =~ s{\$(\w*)}{$1 ? "\$$1" : 'undef'}ge;
      $params =~ s{\s*=\s*undef\s*(,|\z)}{$1}g;
      $params =~ s{,?\s*\@\s*\z}{};
      my $suffix = '';
      my @parts = split /,/, $params;
      my $i = 0;
      for my $part (@parts) {
        if ($part =~ s{([\$\@%]\w+)\s*=\s*(.*)}{$1}) {
          my $var = $1;
          my $value = $2;
          $suffix .= "$var = $value if \$#_ < $i;";
        }
        $i++;
      }
      $params = join ',', @parts;
      if (!$params) {
        "sub$name \{";
      }
      elsif ($params =~ /=/) {
        warn "oh no $file: $params";
        $orig;
      }
      else {
        "sub$name \{ my ($params) = \@_;$suffix";
      }
    }e;
    print { $out_fh } $line;
  }
  close $in_fh;
  close $out_fh;
  rename "$file.new", $file;
}
