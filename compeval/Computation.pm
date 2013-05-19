package compeval::Computation;

use warnings;
use strict;
use v5.10;

use compeval;

sub new {
	my $class = shift;
	my ($dir) = @_;

	-s "$dir/inputs" or die "$dir not a computation directory (file 'inputs' not found)";
	-s "$dir/outputs" or die "$dir not a computation directory (file 'outputs' not found)";
	-x "$dir/exec" or die "$dir not a computation directory (file 'exec' not found)";

	my $self = {
		dir => $dir,
		inputs => [slurp("$dir/inputs")],
		outputs => [slurp("$dir/outputs")],
	};

	bless $self, $class;
}

sub inputs {
	my $self = shift;
	return @{$self->{inputs}};
}

sub outputs {
	my $self = shift;
	return @{$self->{outputs}};
}

sub exec {
	my $self = shift;
	my (@args) = @_;
	system($self->{dir}.'/exec', @args);
}

1;
