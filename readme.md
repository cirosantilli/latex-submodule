Latex shared files, meant to be factor out code amongst latex projects

# Features

- automate the make process, including bibtex and synctex
- view output with viewers
- create a distributions such as zip files
- upload the distribution via ftp
- `.gitignore`
- common `.sty` file options
- markdown to pdf
- many customizable parameters

# Live example

A live example that illustrates the usage of this submodule.
can be found at: <https://github.com/cirosantilli/latex-cheat>

# Dependencies

This section describes the utilities on which this project depends,
and which you must install before using this project.

## POSIX

This is designed to rely only on basic [POSIX 7 command line utilities](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)
such as `sh`, `cd`, `ln` or `find`, and include extra utilities only when absolutelly necessary.

This means that it will be easier to use this project in a Linux distro
or MAC-OS, since those are largely POSIX compliant out-of-the-box.

Windows is not POSIX compliant out-of-the-box,
but you can easily install most POSIX utilities in one go with packages such as mingw or cygwin.
Remember that the utilities must be in your PATH.

## non-POSIX

The non POSIX commdependencies are:

- git: this should be used as a git submodule of another git repo.

- pdflatex (optional): used to transform `.tex` into `.pdf`.

- bibtex (optional): required if you want to use `.bib` bibliography files with latex.

- pandoc (optional): required if you want to compile `.md` markdown files.

- lftp (optional): required if you want to upload your output files via ftp.

For systems which have some sort of command line package manager,
such as Ubuntu's `apt-get` or Fedora's `yum`,
there may be a make target of the type: `install-deps-XXX`
which installs in one go all the non-POSIX requirements.

## Prior knowledge

Although it is possible (and a design goal) to use this project without much prior knowledge,
understanding the very basics of the dependency utilities will be of great help
if you want to understand what is going on, and easily guess how to do new things.

# Installation

This should be used as a submodule to latex projects.
The advantage of doing so is that whenever updates are done to the shared files,
you can easily add them to other repository by:

    cd submodule
    git pull

## New project

For a new project, consider using the latex template located at:
<https://github.com/cirosantilli/latex-template> directly,
which already has this submodule installed.

See the instructions on the readme for how to use that template.

## Existing project

Include this as a submodule in your existing git repo as:

    git submodule add git://github.com/USERNAME/latex.git shared
    git add .gitmodules

At the repo root then symlink from the required place in
the repo into this submodule. For example, to use the makefile do:

    git-root/submodule/makefile
    git-root/makefile               ( -> submodule/makefile)

The `install` script helps automate the symlink creation process
but is efficacy for existing projects is limited since it cannot decide
what to do if symlink names already exist. To use it do:

    cd `submodule`
    ./install

# Usage

Once installed, all the usage is based on `make`,

See:

- [Make targets](#make-targets) to know what you can do

- [Make configuration](#make-configuration) for a description of how to use the configuration
    files and what each option does.

# Make targets

For those unfamiliar with make: you can use targets simply as:

    make target-name

Targets are sorted by increasing usefulness, simplicity or grouped by similarity of function.

## install-deps-ubuntu

Installs all the required dependencies supposing user is on a ubuntu machine

## all

This is the default target, that is, the will that will be run when you use just `make` without arguments.

Makes all .tex and .md (markdown) files under IN_DIR (recursive) into pdfs.

Puts outputs under a directory named `OUT_DIR` configuraion parameter.

Empty directories are removed from the output.

## view

Implies the all target

View the file whose relative path without extension from `IN_DIR`
equals `VIEW` using the viewer program `VIEWER` as:

    VIEWER VIEW

Example:

    make view VIEWER=okular VIEW=subdir/index

would run something like:

    okular _out/subdir/index.pdf

## clean

Remove `OUT_DIR` and `AUX_DIR` and any files which are any type output by either latex, pdflatex, bibtex or synctex
for example `.pdf`, `.ps`, `synctex.gz`, `.out`, etc.

The removal of files under IN_DIR is done so that users who use their editors to compile
the pdfs on the same directory as the tex sources will also get a clean repo.

It is however recommended that users configure their editors to use the makefile via command bindings.

# Make configuration

You can configure the make parameters in the following ways:

- command line arguments
- makefile-params file
- makefile-params-private file

## Command line arguments

Those follow the normal make syntax:

    make PARAM=value

It has precedence over all other methods of specifying parameters,
but has the disadvantage that you have to type them every time.

## makefile-params

The `makefile-params` and `makefile-params-private` shall be put on the same directory as the makefile.

Those files use regular makefile syntax, but it may *not* contain any rules,
only variable definitions and possibly intermediate computation steps to reach the values.

For those unfamiliar with makefile syntax, this means that you should define parameters as:

    PARAM := val

where `PARAM` is the name of the parameter, and `val` is its value.
There should be no trailling whitespace (`"val "` instead of `"val"`), as those are included in the vales.

Any of those files may not exist, in which case it is as if it was an empty file.

The difference between `makefile-params` and `makefile-params-private` is that the private version
shall not be tracked by git, and therefore can contain settings that
vary between different users of the same project

The local version shall be run by make *after* the non local one,
therefore any definition done there with `:=` shall override values in the non local params file
while definitions done with `?=` shall provide default values in case those are not yet defined

For example, `makefile-params` could contain:

    FTP_HOST := a.com
    A := $(shell echo -n username )
    FTP_USER := $(A)

Now if `makefile-params-private` contains:

    FTP_HOST := b.com
    FTP_USER ?= username2

Then in the end, the configuration will be `FTP_HOST := b.com` (because is was defined with `:=`)

    FTP_HOST := b.com

Because is was defined with `:=` in the local file which is read afterwards and

    FTP_USER := b.com

Because is was defined with `?=` in the local file

Each parameter has a default value which shall be taken in case it does not appear in the
parameter files.

The default value may equal the empty string,
in which case it shall be noted as EMPTY on this documentation.

It is recommended that you use the default values whenever you can unless you have a good reason not to do so,
since it will be easier for people to understand your project then.

If you use a variable with a supported name as an intemediate buffer,
dont forget to unsed that variable before the end, or it shall be taken as a parameter value

Example ( highly *not* recommended usage, but valid ):

    FTP_USER = a
    b = FTP_USER
    unset FTP_USER

Those parameters can be equally given on the command line to make using the usual syntax

    make PARAM_NAME=PARAM_VAL

The following configuration parameters are supported:

## IN_DIR

Directory which shall contain all of the .tex source files

`IN_DIR` must not be `.` Rationale: only way to clean editor generated
files such as .pdf s which are put on the same directory as the .tex
is removing files by extension, but it is possible that users want to
include pdfs as media in their project, and that media would get wiped out
by clean also. It would be possible to get around that by not removing
files under certain directories, but that would be annoying to implement
since whenever a new directory is created it would be necessary to add it
to the dont clear directory list.

Default value: `src/`

## OUT_DIR

Directory which shall contain the output files such as `.pdf`, but not necessarily
auxiliary files wuch as `.aux`, which shall be put in `AUX_DIR`

**Do not put anything valuable inside this dirs**,
since it is ignored by `.gitignore` and `make clean` will wipe it out!

Default value: `_out/`.

## FTP_HOST

Host to upload output files to

Default: `EMPTY`

## FTP_USER

Username to connect to the ftp host.

Default value: `EMPTY`.

# When should you modify a file in this directory

Only make changes to the files in this directory
( or to ther symlink names, which is the same thing )
if those change would be generally useful for the majority of projects,
and then merge them back in.

For changes which are only interesting for a given project
you must use other files to achieve the same effects.

# Editor configuration

To make the most of this template,
you can configure your editor of choice to use it.

All you need is an editor which supports sh commands,
specially if you can make keybindigs (say F6) to trigger sh commands.

## Vim examples

Example of vim configuration for forward make:

    au BufEnter,BufRead *.tex nnoremap <F6> :w<CR>:exe :sil ! make view VIEW=%:r LINE=' . line(.) . '<CR>

# Rationale

This section discusses design choices made for this repo.

The advantage of this submodule is obvious: centralizing all shared file developement in one place.

The problem with this submodule is a problem
because you have to copy it up once for every latex repo, and this takes up space.

However, we have considered that this is currently the best alternative since this repo is quite small
and because the other alternatives are either unstable or put too much burden on the user.

## Alternatives to use less space

### Clone into search paths

Files which have search paths for example `.sty`, could be put once on search path for every version.
as explained in <https://github.com/cirosantilli/latex-cheat/blob/86cdba6be7a3b4900e9459d7dcd516db6d0121f4/readme.md#sty-search-path>

This does not apply to `makefile` or `.gitignore` since there is no search path for thoes AFAIK.

However AFAIK there is no automatic way to manage multiple versions of files in a search path.

The best we could come up with was to:

- in the tex files, usepackage to an specific version of packages (`pack-1.0.sty`, `pack-1.1.sty`, etc.)
    and have developement under `pack.sty`

- in the search path, manually checkout every used version once under the name

        V="1.1"
        git show "$V":shared.sty > shared-"$V".sty

    and add the version files to the gitignore as:

        *-[0-9].[0-9].sty

    so that only the developement file woudl be kept

However this has the following shortcomings:

- possibility of name conflicts with other packages

- users have learn about the latex search path at first usage

- users have to checkout stuff manually

- at every version change, you have to modify the latex file include line.

- to be really memory efficient you would have to count how many times a
    version is used and then remove the version specific files once the count
    reaches 0, and there is no way to do that currently.

I believe this adds a startup and maintainance barrier that is too large,
and that it is better to simply use up a little more memory.

## Why output dirs are not on the repo

It would be nice to keep the `_out/` in the main repo to make that even clear for users
that this dir will contain stuff.

However git cannot currently track empty dirs.

Of course, one could put a dummy file like `.gitkeep` or `readme.md` inside the dir to keep it.

However any file put into those dirs could conflict with output files
(what if the program output is called `.gitkeep` or `readme.md` ?).

Since `_out/` is such a rare name and obviously not a place where users should put their important files,
a design decision was made to keep it out of the repo.

Furthermore dataloss is an inevitable possible consequense of `make clean`,
and even keeping the `_out` in the repo would not prevent people from losing their data
( it might even increase the chances that someone puts something in there... )
