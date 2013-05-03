latex shared files, meant to be included as a submodule on other projects to be shared amongst projects.

for a new project, consider using the latex template located in: https://github.com/cirosantilli/latex-template/tree/1.1 directly.

# rationale

the advantage of this submodule is obvious: centralizing all shared file developement in one place.

the problem with this submodule is a problem because you have to copy it up once for every latex repo, and this takes up space

however, we have considered that this is currently the best alternative since this repo is quite small
and because the other alternatives are either unstable or put too much burden on the user.

## alternatives to use less space

### search paths

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

- users have learn about the latex search path at first usage

- users have to checkout stuff manually

- at every version change, you have to modify the latex file include line.

- to be really memory efficient you would have to count how many times a
    version is used and then remove the version specific files once the count
    reaches 0, and there is no way to do that currently.

I believe this adds a startup and maintainance barrier that is too large,
and that it is better to simply use up a little more memory.
