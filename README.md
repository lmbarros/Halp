# Halp: An Ad Hoc Literate Programming Tool

## Rust rewrite branch

This branch contains a work-in-progress rewrite of Halp to Rust. This is a
learning exercise, as Halp seemed like an interesting first real-world Rust
program to write. If I like the results, this may become the official
implementation.

## Old README contents

A quick and dirty Literate Programming tool hacked over a few nights for my other project [DUMP](https://github.com/lmbarros/DUMP).

Main features:

* Not much tested
* Gets into infinite loops if there are cycles in source code
* Source code is ugly and inefficient
* Reads a Markdown file as input
* Produces whatever you want as output
* Requires the use of annoying characters, like ⟨ and ⟩, in the input source
* When a block is expanded, each expanded line retains the prefix an postfix of the referenced block (a feature stolen from [Mason Staugler's Knot](https://github.com/mqsoh/knot))

Someday I should rewrite Halp decently in Halp :-)
