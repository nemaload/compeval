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

In order to safely use Docker containers, the computation run
within a container must (i) store no persistent state in the container
and (ii) be re-entrant, i.e. multiple computation instances may run
within the same container. These requirements would be a must if the
computation run on the main system anyway.

Container-Computation Correspondence
------------------------------------

Across task evaluation runs, we would of course like to reuse
the same container. For now, each container is tied to a particular
computation commit; we generate a new container when the computation
runs from a different commit.

In the future, we can improve this in two significant ways:

  * Keep around containers for different commits, in case we switch
between two versions. Let's see how common that will be.

  * Incrementally update containers in case of update from one commit
to another one (forward in the history). The docker description script
is ready to accomodate this, it just not implemented in the first phase
for the sake of simplicity.

We store the mapping **computation(commit) \to container(id)**
in the computation's directory in the file `docker-container`
(this file is not tracked in Git, of course).

Implementation
--------------

The computation directory can contain Docker setup configuration which
is then used to execute the computation.

### Docker Description

Each computation is associated with a **docker description**
(stored in the file `docker.conf`) which is a simple configuration
file listing a few essential keys:

  * `image`: Name of the base Docker image to use for the container setup.

(Well, that's, um.. everything so far. :-)

### Docker Setup

Each computation is also associated with a **docker setup** which
is a simple shell script (stored in the file `docker-setup.sh`) that
takes care of the docker container setup, sourced into an environment
with some helper functions defined that take care of the details.

The script can be extended in time to include more commands to adjust
the setup etc. For each set of commands added at a time, the `next_stage`
function is used, like this:

	next_stage && cp /etc/a /etc/b
	next_stage && apt-get update && apt-get install package
	next_stage && {
		if ! [ -e /var/tmp/example ]; then
			echo `hostname` is broken | mail root
		fi
		rm -f /var/tmp/example
	}

Of course, some commands should be executed everytime and therefore
are not prefixed by `next_stage` but `everytime` (which of course always
returns true, but is provided as a decorator and may do some logging):

	next_stage && git clone git://github.com/nemaload/something
	everytime && (cd something && git fetch && git checkout 12345)
	everytime && (cd something && make)

Typically, aside of installing dependencies etc., the main task
done in the docker setup file will be cloning a Git repository with
the software to be run (and building it). *You should always checkout
an explicit commit id in your docker setup script!* This makes sure
that every time the software Git repo is updated, the computation
repo commit id is changed as well and the computation is re-run.

An alternative approach is to include the software Git repo as
a submodule in the computations/ directory and include the computation
configuration files in the project root directory. If you do this,
you can access the (treat as read-only!) computation directory from
within the container by referring to the environment variable **COMPDIR**
so that you don't have to clone it again:

	everytime && rsync -r --delete $COMPDIR/ computation/
	everytime && (cd computation && make)

### Execution

The `ce-run` command takes care of setting up the Docker instances
properly and executing stuff in the Docker container.

Several directories of the main system are bindmounted to within the
Docker container:

  * The global file storage (path in `$GFSDIR`)
  * The computation directory (path in `$COMPDIR`)

The parameters of the executable run in the container then explicitly
refer to the global file storage mount point within the container.

In case Docker is used, the `ce-run` command must be run as root.
