package compeval;

use warnings;
use strict;
use v5.10;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(slurp);
our @EXPORT_OK = qw(slurp);

sub slurp {
	my ($filename) = @_;
	open my $fh, '<', $filename or die "$filename: $!";

	# Load and return list of lines, without trailing newlines
	my @lines = <$fh>;
	chomp @lines;
	@lines;
}

1;
