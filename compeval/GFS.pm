package compeval::GFS;

use warnings;
use strict;
use v5.10.1;

use Cwd;

use compeval;

sub new {
	my $class = shift;
	my ($dir, $basedir) = @_;

	-d "$dir" or die "$dir not a global file storage (directory not found)";
	-d "$basedir/computations" or die "$basedir not a task directory ('computations' subdirectory not found)";

	my $self = {
		dir => $dir,
		basedir => $basedir,
	};

	bless $self, $class;
}

sub dir {
	my $self = shift;
	return Cwd::abs_path($self->{dir});
}

sub nameof_input {
	my $self = shift;
	my ($hash) = @_;
	return 'tinputs/'.substr($hash, 0, 2).'/'.substr($hash, 2);
}

sub nameof_output {
	my $self = shift;
	# @inputs are first 12 digits of the SHA1 hashes of files (except for the 'literal' kind)
	my ($workflow, $output_i, @inputs) = @_;

	my $name;
	if ($workflow->kind eq 'input') {
		$name = $self->nameof_input($inputs[0]);
	} elsif ($workflow->kind eq 'literal') {
		$name = $inputs[0];
	} elsif ($workflow->kind eq 'computation') {
		my ($basedir, $compname) = ($self->{basedir}, $workflow->value);
		my $comphead = substr(`(cd "$basedir/computations/$compname" && git rev-parse HEAD)`, 0, 12);
		my $imageid = $workflow->computation->image_id // '';
		$name = sprintf('c_%s/%s%s/%02d/%s', $workflow->value, $comphead, $imageid, $output_i, join('_', @inputs));
	}

	return $name;
}

sub pathof {
	my $self = shift;
	my ($name) = @_;
	return $self->{dir}.'/'.$name;
}

1;
