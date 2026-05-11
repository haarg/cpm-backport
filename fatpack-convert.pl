use strict;
use warnings;

for my $file (@ARGV) {
  open my $in_fh, '<', $file or die $!;
  open my $out_fh, '>', "$file.new" or die $!;
  while (my $line = <$in_fh>) {
    $line =~ s{\bmy \$target = 'v5\.24';}{my \$target = 'v5.10.1';};
    $line =~ s{(`git describe --tags --dirty`)}{\$ENV\{GIT_DESCRIBE\} // $1};
    $line =~ s{(`git rev-parse --short HEAD`)}{\$ENV\{GIT_COMMIT_ID\} // $1};
    $line =~ s{\bhttps://github.com/skaji/cpm\b}{https://github.com/haarg/cpm-backport};
    print { $out_fh } $line;
  }
  close $in_fh;
  close $out_fh;
  rename "$file.new", $file;
}
