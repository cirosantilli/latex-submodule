Latex shared files, meant to be factor out code amongst latex projects

Compiled versions of this file can be found [here](http://cirosantilli.t15.org/latex-submodule/).

You can also compile this yourself by using `make` in this directory.

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

This is designed to rely only on basic
[POSIX 7 command line utilities](http://pubs.opengroup.org/onlinepubs/9699919799/utilities/contents.html)
such as `sh`, `cd`, `ln` or `find`, and include extra utilities only when absolutely necessary.

This means that it will be easier to use this project in a Linux distro
or MAC-OS, since those are largely POSIX compliant out-of-the-box.

Windows is not POSIX compliant out-of-the-box,
but you can easily install most POSIX utilities in one go with packages such as mingw or cygwin.
Remember that the utilities must be in your PATH.

## non-POSIX

The non POSIX dependencies are:

- git: this should be used as a git submodule of another git repo.

- pdflatex (optional): used to transform `.tex` into `.pdf`.

- bibtex (optional): required if you want to use `.bib` bibliography files with latex.

- pandoc (optional): required if you want to compile `.md` markdown files.

- lftp (optional): required if you want to upload your output files via ftp.

For systems which have some sort of command line package manager,
such as Ubuntu's `apt-get` or Fedora's `yum`,
there may be a make target of the type: `install-deps-XXX`
which installs in one go all the non-POSIX requirements.

If you manage to configure this project for use in any other system not mentioned here,
please submit a pull request and we will be glad to merge it.

## Prior knowledge

Although it is possible (and a design goal) to use this project without much prior knowledge,
understanding the very basics of the dependency utilities will be of great help
if you want to understand what is going on, and easily guess how to do new things.

# Installation

## New project

For a new project, consider using the latex template located at:
<https://github.com/cirosantilli/latex-template> directly,
which already has this submodule installed.

See the instructions on the readme for how to use that template.

## Existing project

Include this as a submodule in your existing git repo as:

    git submodule add https://github.com/cirosantilli/latex-submodule shared

At the repo root then symlink files from the required place in the repo into this submodule.
For example, to use the makefile do you probably want a struture such as:

    git-root/shared/makefile
    git-root/makefile               ( -> shared/makefile)

which you can achieve via:

    ln -s shared/makefile makefile

The `install` script helps automate the symlink creation process
but is efficacy for existing projects is limited since it cannot decide
what to do if symlink names already exist. To use it do:

    cd `shared`
    ./install

Finally, `git add` all the files you want to keep in the repo.

# Usage

Once installed, the usage is based on `make`.

You may choose to leave some functions up to your editor,
or configure your editor to rely entirely on the make given.
See [Editor configuration](#editor-configuration) for more information.

See:

- [Make targets](#make-targets) to know what you can do

- [Make configuration](#make-configuration) for a description of how to use the configuration
    files and what each option does.

## Recursive

You can use this in two ways: recursive or non recursive.

No configuration option is needed to indicate which mode you are on,
it all depends if you intend to use subdirs or not.

Recursive operation means that [IN_DIR](#in_dir) will be searched recursivelly for input files such as tex. Ex:

    ~/.repo-root/makefile
    ~/.repo-root/shared.sty
    ~/.repo-root/src/index.tex
    ~/.repo-root/src/index1.tex
    ~/.repo-root/src/subdir/index.tex

will generate output like:

    ~/.repo-root/_out/index.tex
    ~/.repo-root/_out/subdir/index.tex

This is recursive because you want to compile `index.tex` under `subdir`.

The `index.sty` is visible to both `index.tex` and `subdir/index.tex`
when made with the makefile because it is at the repository root.

`index1.sty` is visible only to `index.tex`, no matter how it was made.

Non recursive means that only files directly under [IN_DIR](#in_dir) will be considered, but not its subdirs.

Ex:

    ~/.repo-root/makefile
    ~/.repo-root/shared.sty
    ~/.repo-root/src/index.sty
    ~/.repo-root/src/index.tex
    ~/.repo-root/src/subdir-index.tex

Which is not recursive since all input files are under `src`.

The `index.sty` is visible to both `index.tex` and `subdir-index.tex`
even when made with most tex IDEs, since it is no the same directory as those files.
`shared.sty` is however only visible to them when the `makefile` is used.

The tradeoff is simple: if you intend recursive operation,
you must then use the makefile provided with this project,
and users must configure their editors to use that makefile.

This may cause many users not to get involved into your project
because of the entry barrier of configuring their editors. Therefore, only use recursive operation
if having subdirs will substantially increase the clarity of your project.

Also, if you intend to use recursive operation,
consider looking at the [Editor configuration](#editor-configuration) session.

The reason why users must configure their editors for recursive operation is that
dependencies such as `.sty` or `.bib` will be put on the toplevel (`~/.repo-root`)
and the makefile is configured to make those visible to all subdirectories,
while what all editors do by default is to take dependencies on the same dir as

In non recursive operation, you just put all the dependencies in [IN_DIR](#in_dir) together with the tex files.

# Make targets

For those unfamiliar with make: you can use targets simply as:

    make target-name

Targets are sorted by increasing usefulness, simplicity or grouped by similarity of function.

The make commands assume that you current dir is the same as the makefile.

## install-deps-ubuntu

Installs all the required dependencies supposing user is on a ubuntu machine

## all

This is the default target, that is, the will that will be run when you use just `make` without arguments.

Makes all .tex and .md (markdown) files under [IN_DIR](#in_dir) (recursivelly) into pdfs.

Puts outputs under a directory named [OUT_DIR](#out_dir)

Empty directories are removed from the output.

## view

View output using a file viewer.

Implies the all target.

The following parameters are used by this target:

- [VIEWER](#viewer)
- [VIEW](#view-parameter)
- [LINE](#line)

Example:

    make view VIEWER="okular -p $$PAGE" VIEW=subdir/index LINE=10

would run something like:

    okular -p 2 _out/subdir/index.pdf

supposing that line 10 is subdir/index correponds to page `2` of the pdf.

## dist

Creates a distribution, that is, files that can be used to end users such as pdfs.

Current distribution types generated are:

- a directory tree with all the files
- a zip file containing the directory tree

The distribution files are put under a dir named [DIST_DIR](#dist_dir) under the following structure:

    $(TAG)pdf/
    $(TAG)pdf.zip

where TAG is a configuration parameter.

If [TAG](#tag) is `EMPTY`, the operation is aborted.

The `pdf/` subdir contains the pdf files of the original tree.

The `pdf.zip` zip file contains the `pdf/` subdir.

## distup

Uploads the latest compiled distribution created by `make dist` via ftp.

Implies `dist`.

Before using this, you must of course have the ftp account.
Many websites offer such accounts today. An example is <http://www.000webhost.com>
but there may be others out there which offer more space or bandwidth.

A common usage of this is to upload to web servers with an http server frontend
so that end users can browse and download the uploaded distribution files with their browser
without needing to compile them.

It is recommended that you only upload certain stable versions when you feel that the project has changed enough,
and not every single development version, or you will have too many useless files in your server,
taking up space and making users confused.

You will need to set the following parameters in one of the [Makefile configuration](#make-configuration)
parameters:

- FTP_HOST: the ftp host. Example: `cirosantilli.t15.org`
- FTP_USER: the ftp username. Example: `u147220728`

Those parameters together with the password are necessary for establishing the connection.
They can be found in the control panel of your account.

You will be prompted for the ftp password after running the command.

Next, you must tell the server where to store your files.
The location is given by the [REMOTE_SUBDIR](#remote_subdir) configuration parameter.

All remote files in the `REMOTE_SUBDIR` directory will be first removed before attempting the upload,
so make sure that you don't set it to a useful directory.

## clean

Removes the following directories:

- `OUT_DIR`
- `AUX_DIR`
- `DIST_DIR`

and any files which are any type of output generated by either latex, pdflatex, bibtex or synctex
for example `.pdf`, `.ps`, `synctex.gz`, `.out`, etc.

The removal of files under `IN_DIR` is done so that users who use their editors to compile
the pdfs on the same directory as the tex sources will also get a clean repo.

It is however recommended that users configure their editors to use the makefile via command bindings.

# Make configuration

## Methods

You can configure the make parameters in the following ways:

- command line arguments
- makefile-params file
- makefile-params-private file

### Command line arguments

Those follow the normal make syntax:

    make PARAM=value

It has precedence over all other methods of specifying parameters,
but has the disadvantage that you have to type them every time.

### makefile-params

The `makefile-params` and `makefile-params-private` shall be put on the same directory as the makefile.

Those files use regular makefile syntax, but it may *not* contain any rules,
only variable definitions and possibly intermediate computation steps to reach the values.

For those unfamiliar with makefile syntax, this means that you should define parameters as:

    PARAM := val

where `PARAM` is the name of the parameter, and `val` is its value.
There should be no trailing whitespace (`"val "` instead of `"val"`), as those are included in the vales.

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

If you use a variable with a supported name as an intermediate buffer,
don't forget to unset that variable before the end, or it shall be taken as a parameter value

Example ( highly *not* recommended usage, but valid ):

    FTP_USER = a
    b = FTP_USER
    unset FTP_USER

Those parameters can be equally given on the command line to make using the usual syntax

    make PARAM_NAME=PARAM_VAL

## Parameters

The following configuration parameters are supported:

### IN_DIR

Directory which shall contain all of the `.tex` source files

Must be slash `/` terminated.

Must be a realtive path from the project root, without starting with `./`.

`IN_DIR` must not be `./`. Rationale: only way to clean editor generated
files such as .pdf s which are put on the same directory as the .tex
is removing files by extension, but it is possible that users want to
include pdfs as media in their project, and that media would get wiped out
by clean also. It would be possible to get around that by not removing
files under certain directories, but that would be annoying to implement
since whenever a new directory is created it would be necessary to add it
to the don't clear directory list.

Default value: `src/`

### OUT_DIR

Directory where output files such as `.pdf` will be put after running [all](#all)

Must be slash `/` terminated.

Not necessarily the same as where auxiliary files such as `.aux` will be put, which is in [AUX_DIR](#aux_dir)

**Do not put anything valuable inside this dirs**,
since it is ignored by `.gitignore` and `make clean` will wipe it out!

Default value: `_out/`.

### AUX_DIR

Directory where auxiliary files such as `.aux` will be put after running [all](#all)

Must be slash `/` terminated.

Must be a realtive path from the project root, without starting with `./`.

**Do not put anything valuable inside this dirs**,
since it is ignored by `.gitignore` and `make clean` will wipe it out!

For the time being, this cannot be different from `OUT_DIR`,
although this is because of current technical limitations which we are trying to overcome.

Default value: [OUT_DIR](#out_dir).

### DIST_DIR

Directory where distribution files will be put after running [dist](#dist).

Must be slash `/` terminated.

Must be a realtive path from the project root, without starting with `./`.

**Do not put anything valuable inside this dirs**,
since it is ignored by `.gitignore` and `make clean` will wipe it out!

Default value: `_dist/`.

### VIEWER

The viewer command, including the page in which the pdf should be open as a sh variable named `PAGE`.

Default value:

    okular -p $$PAGE

where:

- `-p` is the okular flag to select the initial page.

- `$$PAGE` is a sh variable containing that page.

The page is be determined at each invocation by using synctex with [LINE](#line)

It has double dollar mark because it is a shell variable,
so it is necessary to escape the makefile dollar.

### VIEW parameter

Full path of file being edited.

Default value: `project_path/$(IN_DIR)/index.tex`

This is tipically set by your editor as a command line argument to make as:

    make VIEW=/path/to/project/src/file.tex

### LINE

Current line in current file of the editor.

Is used by synctex to determine what pdf page that line corresponds to.

This is tipically set by your editor as a command line argument to make as:

    make LINE=1

Default value: `1`.

### FTP_HOST

Host to upload output files to

Default: `EMPTY`

### FTP_USER

Username to connect to the ftp host.

Default value: `EMPTY`.

### REMOTE_SUBDIR

Remote directory where distribution files shall be uploaded to.

Default value: `$(REMOTE_SUBDIR_PREF)$(PROJECT_NAME)/$(TAG)`.

### REMOTE_SUBDIR_PREF

Prefix to the REMOTE_SUBDIR.

Default value: `EMPTY`.

### PROJECT_NAME

Name of current project.

Default value: the basename of the directory name of the makefile.
Ex: if the makefile is at: `~/project/makefile`, the default value is `project`

### TAG

Identifier for current project version.

Is frequently a string of the type `1.2` or `2.1.3`, but could be anything such as `bugfixed`,
although this is not recommended since you lose the version order information.

Default value:

- if the the HEAD commit (current commit) has no tags, it equals [TAG_DEFAULT](#tag_default)
- else, the first of the tags in alphabetical (ASCII) order

In this way, you can upload a latest version of your project whenever you are not on a git tag.

It is recommended that you don't name a git tag as [TAG_DEFAULT](#tag_default),
since this would conflict with this default methodology.

### TAG_DEFAULT

The default value for TAG in case the HEAD has no tags.

Default value: `latest`

# Editor configuration

To make the most of this template,
you can configure your editor of choice to use it.

All you need is an editor which can:

- trigger `sh` commands, via keybindigs. Ex: F5 runs `make`

- insert some parameters about the current file in the shell command. Ex of an imaginary editor:

        make VIEW=%FULLPATH% LINE=%CURRENT_LINE%

    and then the editor shoud replace FULLPATH by the full path of the current file being edited
    and CURRENT_LINE by the current line number, before giving the command to sh.

The first thing you should keep in mind that you must issue the make commands from the same directory
as the makefile, that is, the repo root. You can achieve this in the following ways:

- prefix all your bindings with:

        cd `git rev-parse --show-toplevel` &&

    so for example in our imaginary editor we would do:

        <F5> --> make VIEW=%FULLPATH% LINE=%CURRENT_LINE%

    `git rev-parse --show-toplevel` is simply a git command that prints the full path of the repository root.

- create some sort of project which users must select before workign with the files.

    This strategy is common amongst IDEs: before using files in a project, you must first open
    a configuration file which containt parameters for that project.

    That file should specify the keybindings for the makefile.

If you manage to configure this project for use with any other editor not mentioned here,
please submit a pull request and we will be glad to merge it.

## Vim

You could add the following lines to your `.vimrc`:

    #make
    au BufEnter,BufRead *.tex cal MapAllBuff( '<F5>'  , ':w<cr>:! cd `git rev-parse --show-toplevel` && make<cr>' )

    #make clean
    au BufEnter,BufRead *.tex cal MapAllBuff( '<S-F5>', ':w<cr>:! cd `git rev-parse --show-toplevel` && make clean<cr>' )

    #make view
    au BufEnter,BufRead *.tex cal MapAllBuff( '<F6>'  , ':w<cr>:exe '':sil ! cd `git rev-parse --show-toplevel` && make view VIEW=''''"%:p"'''' LINE=''''"'' . line(".") . ''"''''''<cr>' )

This will however set this behaviour to all tex files.

If you want this behaviour only for this project, you should put those commands on a
`.vim` file and source it every time you want to work on your tex project.

To do inverse searches (pdf to tex) using git,
you must configure your viewer to issue the following command: TODO

# When should you modify a file in this directory

Only make changes to the files in this directory
( or to their symlink names, which is the same thing )
if those change would be generally useful for the majority of projects,
and then merge them back in.

For changes which are only interesting for a given project
you must use other files to achieve the same effects.

# Rationale

This section discusses design choices made for this repo.

## Why a submodule

This should be used as a submodule to latex projects.
The advantage of doing so is that whenever updates are done to the shared files,
you can easily add them to other repository by:

    cd submodule
    git pull

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
    and have development under `pack.sty`

- in the search path, manually checkout every used version once under the name

        V="1.1"
        git show "$V":shared.sty > shared-"$V".sty

    and add the version files to the gitignore as:

        *-[0-9].[0-9].sty

    so that only the development file would be kept

However this has the following shortcomings:

- possibility of name conflicts with other packages

- users have learn about the latex search path at first usage

- users have to checkout stuff manually

- at every version change, you have to modify the latex file include line.

- to be really memory efficient you would have to count how many times a
    version is used and then remove the version specific files once the count
    reaches 0, and there is no way to do that currently.

I believe this adds a startup and maintenance barrier that is too large,
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

Furthermore data loss is an inevitable possible consequence of `make clean`,
and even keeping the `_out` in the repo would not prevent people from losing their data
( it might even increase the chances that someone puts something in there... )
