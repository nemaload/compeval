package compeval::Task;

use warnings;
use strict;
use v5.10;

use compeval;
use compeval::Workflow;

sub new {
	my $class = shift;
	my ($dir) = @_;

	-d "$dir/workflow" or die "$dir not a task directory (directory 'workflow' not found)";
	-d "$dir/computations" or die "$dir not a task directory (directory 'computations' not found)";
	-s "$dir/inputs" or die "$dir not a task directory (file 'inputs' not found)";

	system('git', '--work-tree', $dir, 'submodule', 'update', '--init');

	bless \$dir, $class;
}

sub workflow {
	my $self = shift;
	return compeval::Workflow->new("$$self/workflow");
}

sub inputnames {
	my $self = shift;
	return slurp("$$self/inputs");
}

1;
