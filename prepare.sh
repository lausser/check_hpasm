#!/bin/bash
aclocal
autoheader
automake --add-missing --copy
autoconf
./configure
