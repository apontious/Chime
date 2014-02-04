Chime
=====

Chime is a Mac (and eventually iOS) framework that provides Objective-C wrappers around the clang library's indexing functionality.

Currently, it is very rudimentary, and has been released primarily as a promised complement to the [Edge Cases](http://edgecasesshow.com) episode ["Indexing with Clang"](http://edgecasesshow.com/78).

To achieve its functionality, it copies the embedded (private, undocumented) libclang.dylib from inside Xcode's package into itself, and uses its own copy of a recent top-of-tree version of libclang's Index.h and related headers. These are hacks! And will eventually be replaced with this project's own process to download and build the llvm and clang source code itself.

Since documentation and functionality are both scarce, I would recommend listening to the episode first to get a sense of what's going on.

Then, try out the two sample projects, the command-line utility chimesimpletester, and the GUI app Chime Project Indexer. Both require 10.9.

I hope to provide additional functionality shortly.

Andrew Pontious 2/3/2014