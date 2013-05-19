package compeval;

use warnings;
use strict;
use v5.10;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(slurp sha1f);
our @EXPORT_OK = qw(slurp sha1f);

sub slurp {
	my ($filename) = @_;
	open my $fh, '<', $filename or die "$filename: $!";

	# Load and return list of lines, without trailing newlines
	my @lines = <$fh>;
	chomp @lines;
	@lines;
}

sub sha1f {
	my ($filename) = @_;
	if (-e $filename) {
		my $sha1line = `sha1sum "$filename"`;
		return substr($sha1line, 0, 12);
	} else {
		return '???';
	}
}

1;
