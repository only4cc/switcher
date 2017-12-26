#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Switcher::AppREST;
Switcher::AppREST->to_app;
