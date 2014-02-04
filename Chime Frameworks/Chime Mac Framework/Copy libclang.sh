#!/bin/sh

#  Copy libclang.sh
#  Chime Framework
#
#  Created by Andrew Pontious on 1/29/14.
#  Copyright (c) 2014 Andrew Pontious.
#  Some rights reserved: http://opensource.org/licenses/mit-license.php

#
#  Copies the libclang.dylib from within Xcode's package into our Chime framework.
#  This is a (hopefully) short-term hack to avoid the extra work of building clang in our project.
#

xcodepath="`xcode-select --print-path`"

if [ -z $xcodepath ]; then
    # Shouldn't happen, because you need Xcode to build the project that runs this script!
    echo "Cannot find Xcode"
    exit 255
fi

libclangpath="$xcodepath/Toolchains/XcodeDefault.xctoolchain/usr/lib/libclang.dylib"

if [ ! -f "libclang.dylib" ]; then
    cp "$libclangpath" "libclang.dylib"
else
    echo "libclang.dylib already copied"
fi