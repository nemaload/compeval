package compeval::Computation;

use warnings;
use strict;
use v5.10.1;

use File::Basename;

use compeval;
use compeval::Docker;

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
	-e $execfile or $execfile = "$dir/exec";
	-e $execfile or die "$dir not a computation directory (file 'exec' or 'compeval-exec' not found)";

	my $docker_image = "$dir/compeval-docker-image";
	-s $docker_image or $docker_image = "$dir/docker-image";
	-s $docker_image or $docker_image = undef;
	my ($docker_image_name, $docker_image_tag);
	if (defined $docker_image) {
		my $docker_image_line = (slurp($docker_image))[0];
		($docker_image_name, $docker_image_tag) = split(':', $docker_image_line);
		$docker_image_tag //= 'latest';
	}

	my $self = {
		dir => $dir,
		inputs => [slurp($inputfile)],
		outputs => [slurp($outputfile)],
		execfile => $execfile,
		docker_image_name => $docker_image_name,
		docker_image_tag => $docker_image_tag,
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

sub image_update {
	my $self = shift;
	$self->{docker_image_name} or return;
	compeval::Docker::pull($self->{docker_image_name}, $self->{docker_image_tag});
}

sub image_id {
	my $self = shift;
	$self->{docker_image_name} or return undef;
	return compeval::Docker::image_id($self->{docker_image_name}, $self->{docker_image_tag});
}

sub exec {
	my $self = shift;
	my ($gfs, @args) = @_;
	if (not defined $self->{docker_image_name}) {
		# This is very straightforward - no Docker, just run exec
		system($self->{execfile}, map { $gfs->pathof($_) } @args);

	} else {
		# We already made sure we have the Docker image during
		# task initialization

		my $execfile_name = (slurp($self->{execfile}))[0];
		my @execfile_args = map { "/srv/gfs/$_" } @args;

		compeval::Docker::run($self->{docker_image_name}, $self->{docker_image_tag},
			[ $execfile_name, @execfile_args ],
			{ binds => [ [$gfs->dir => '/srv/gfs'] ] });
	}
}

1;
