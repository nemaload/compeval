package compeval::Computation;

use warnings;
use strict;
use v5.10;

use compeval;

sub new {
	my $class = shift;
	my ($dir) = @_;

	my $inputfile = "$dir/compeval-inputs";
	-s $inputfile or $inputfile = "$dir/inputs";
	-s $inputfile or die "$dir not a computation directory (file 'inputs' or 'compeval-inputs' not found)";

	my $outputfile = "$dir/compeval-outputs";
	-s $outputfile or $outputfile = "$dir/outputs";
	-s $outputfile or die "$dir not a computation directory (file 'outputs' or 'compeval-outputs' not found)";

	my $execfile = "$dir/compeval-exec";
	-x $execfile or $execfile = "$dir/exec";
	-x $execfile or die "$dir not a computation directory (file 'exec' or 'compeval-exec' not found or not executable)";

	my $self = {
		dir => $dir,
		inputs => [slurp($inputfile)],
		outputs => [slurp($outputfile)],
		execfile => $execfile,
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
	system($self->{execfile}, @args);
}

1;
