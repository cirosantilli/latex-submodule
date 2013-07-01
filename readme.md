latex shared files, meant to be factor out code amongst latex projects

things it factors out include:

- the `makefile`
- `.gitignore`
- common `.sty` file options

it also supports markdown to pdf conversion in an analogous way to the tex to pdf conversion

the advantage of this method is that whenever updates are done to the shared files,
you can easily add them to other repository by:

    cd submodule
    git pull

# example

a working example that illustrates the usage of this submodule

things it factors out include:

- the `makefile`
- `.gitignore`
- common `.sty` file options
is be kept at <https://github.com/cirosantilli/latex-cheat>

# installation

## new project

For a new project, consider using the latex template located at:
<https://github.com/cirosantilli/latex-template> directly,
which already has this submodule installed.

See the instructions on the readme for how to do this.

## existing project

include this as a submodule in your existing git repo as:

    git submodule add git://github.com/USERNAME/latex.git shared
    git add .gitmodules

at the repo root then symlink from the required place in
the repo into this submodule. For example, to use the makefile do:

    git-root/submodule/makefile
    git-root/makefile               ( -> submodule/makefile)

the `install` script helps automate the symlink creation process
but is efficacy for existing projects is limited since it cannot decide
what to do if symlink names already exist. To use do:

    cd `submodule`
    ./install

# usage

once installed, all the usage is based on `make`,
and you can get usage information by running:

    make help

# warning: data loss

all output and auxiliary files are put in the output dirs specified in the makefile.

**DO NOT PUT ANYTHING VALUABLE INSIDE THOSE DIRS**, since `make clean` will wipe them out!!!

# rationale

the advantage of this submodule is obvious: centralizing all shared file developement in one place.

the problem with this submodule is a problem because you have to copy it up once for every latex repo, and this takes up space

however, we have considered that this is currently the best alternative since this repo is quite small
and because the other alternatives are either unstable or put too much burden on the user.

## alternatives to use less space

### clone into search paths

files which have search paths for example `.sty`, could be put once on search path for every version.
as explained in https://github.com/cirosantilli/latex-cheat/blob/86cdba6be7a3b4900e9459d7dcd516db6d0121f4/readme.md#sty-search-path

this does not apply to `makefile` or `.gitignore` since there is no search path for thoes AFAIK.

however AFAIK there is no automatic way to manage multiple versions of files in a search path.

The best we could come up with was to:

- in the tex files, usepackage to an specific version of packages (`pack-1.0.sty`, `pack-1.1.sty`, etc.)
    and have developement under `pack.sty`

- in the search path, manually checkout every used version once under the name

        V="1.1"
        git show "$V":shared.sty > shared-"$V".sty

    and add the version files to the gitignore as:

        *-[0-9].[0-9].sty

    so that only the developement file woudl be kept

however this has the following shortcomings:

- possibility of name conflicts with other packages

- users have learn about the latex search path at first usage

- users have to checkout stuff manually

- at every version change, you have to modify the latex file include line.

- to be really memory efficient you would have to count how many times a
    version is used and then remove the version specific files once the count
    reaches 0, and there is no way to do that currently.

I believe this adds a startup and maintainance barrier that is too large,
and that it is better to simply use up a little more memory.

## why output dirs are not on the repo

it would be nice to keep the `_out/` in the main repo to make that even clear for users
that this dir will contain stuff

however git cannot currently track empty dirs

of course, one could put a dummy file like `.gitkeep` or `readme.md` inside the dir to keep it

however any file put into those dirs could conflict with output files
(what if the program output is called `.gitkeep` or `readme.md` ?)

since `_out/` is such a rare name and obviously not a place where users should put their important files,
a design decision was made to keep it out of the repo.

furthermore dataloss is an inevitable possible consequense of `make clean`,
and even keeping the `_out` in the repo would not prevent people from losing their data
( it might even increase the chances that someone puts something in there... )
