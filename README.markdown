# Flex Version Manager

## About

This script is for those who want to compile flex apps outside of Adobe's IDEs
and want to switch between different SDK versions easily. You may already have
the SVN repo checked out from http://opensource.adobe.com/svn/opensource/flex/sdk/
and simply switch tags, in which case you probably don't need to bother with this.

I use zsh, so you'll see some places where I've had to do things a bit weirdly
so that this script plays nice with bash aswell.

This script is heavily based on nvm: (http://github.com/creationix/nvm), so many
 thanks to Tim Caswell and Matthew Ranney!

## Installation

You need Java to run the Flex command line apps, and html2text to view available
flex versions (fvm list-remote).

To install, create a folder somewhere in your filesystem with the "`fvm.sh`" file
inside it.  I put mine in a folder called "`.fvm`".

Or if you have `git` installed, then just clone it:

    git clone git://github.com/fel/fvm.git ~/.fvm

Then add two lines to your bash/zsh profile:

    FVM_DIR=$HOME/.fvm
    . $FVM_DIR/fvm.sh
    fvm use

The first line loads the `fvm` function into your bash shell so that it's available
as a command.The second line sets your default Flex SDK to the first version it
finds (not good).

## Usage

    fvm help

To download, install, and use the 3.6.0.16581 release of flex do this:

    fvm install 3.6

And then in any new shell just use the installed version:

    fvm use 3.6

Note that version numbers are expanded for you to match stable releases (with a
fallback to milestone, then nightly, if there's no corresponding stable version
found).
Examples of expansions (i.e. be more specific if you need to be!):

    fvm install 3 -> 3.0 -> 3.0.2.2113
                3.4 -> 3.4.1.10084
                3.4.0 -> 3.4.0.6955
                3.6.0.13426 (no expansion)

If you want to see what versions you have installed issue:

    fvm list

If you want to see what versions are available:

    fvm list-remote [MAJOR_VERSION]

where MAJOR_VERSION is an optional 3 or 4 to limit the versions of Flex you see.
When omitted, both Flex 3 and 4 SDKs are listed.

fvm keeps a cache ($FVM_DIR/.cache/) of the SDK zips it downloads and the list
of available flex SDKS. To clear this cache (to save space), issue:

    fvm clear-cache

To stop using fvm in your current shell and use your system install (if you have
 one), issue:

    fvm deactivate
  or
    fvm use system

If you want to install fvm to somewhere other than `$HOME/.fvm`, then set the
`$FVM_DIR` environment variable before sourcing the fvm.sh file.
