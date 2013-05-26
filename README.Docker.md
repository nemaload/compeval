CompEval Docker Integration
===========================

Note that this is all TODO yet - just conceptual design documentation.

Motivation
----------

Our goal is to run each computation stage in a dedicated Docker
container so that:

  * Its dependencies do not spill out to the main system
  * It is isolated from the main system and its idiosyncracies
  * Overally, it creates and runs in a well-defined environment.

Each computation class (by name) corresponds to a Docker image,
either the latest version or a specific tag; at any rate,
the used image id is used to identify the computation together
with the commit id. For each run of the computation, a container
is instantiated from the image.

This means that the computation run within a container must not
rely on any persistent state that would be stored in the container.
Also, it technically does not have to be re-entrant, however
breaking that property is probably not a good practice.

Docker Images of Computations
-----------------------------

In principle, CompEval does not care about the genesis of the
Docker images used. However, the recommended best practice is to:

  * Base computation images on the `nemaload/base` image (which has
been crafted manually and contains only stuff listed in `/README`).

  * Create per-computation images using the Docker Builder files
that contain the complete setup instructions in a text format:

	http://docs.docker.io/en/latest/use/builder/

  * Store the Docker Builder files as a part of the computation
software Git repo and also include (as submodule) this Git repo in
the computation directory of the compeval workflow; i.e. we have
the sources, compeval computation descriptor files and Docker Builder
image recipe all at the same place.


In the future, we *may* want to avoid re-downloading new images
on each minor change and instead rebuild them locally; this depends
on how will Docker deal with our changes. If that's required, we can
use the Docker build files in the computation Git repo and rebuild
the images based on them locally.

Implementation
--------------

### Setup

The computation directory can contain a file called `docker-image`;
the contents of this file is then the Docker image name to be pulled
and used as a base for the containers created during computation runs,
e.g.

	nemaload/base

or including a tag like

	nemaload/autorectify:v2.0

The particular image id used during the run is appended to the
computation id.

### Execution

The `ce-run` command will run the computation executable (the contents
of the `exec` file as usual) within a Docker container.  The parameters
of the executable run in the container then explicitly refer to the
global file storage mount point within the container. The current working
directory of the executable is the (bind mount of the) computation
directory; it should be treated as read-only!
