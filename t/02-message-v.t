#!/usr/bin/perl -w
#
# Copyright (C) 2010 by Mark Hindess

use strict;
$ENV{XPL_MESSAGE_VALIDATE} = 1;
do 't/02-message.t';
