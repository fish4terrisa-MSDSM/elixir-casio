#!/usr/bin/env perl
# t/400-web.pl: Test web.py
#
# Copyright (c) 2020 Christopher White, <cxwembedded@gmail.com>.
#
# Elixir is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Elixir is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# # You should have received a copy of the GNU Affero General Public License
# along with Elixir.  If not, see <http://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# This file uses core Perl modules only.

use FindBin '$Bin';
use lib $Bin;

use Test::More;

use TestEnvironment;
use TestHelpers;

# ===========================================================================
# Main

# Set up for the tests
my $tenv = TestEnvironment->new;
$tenv->build_repo(sibling_abs_path('tree'));	# dies on error
$tenv->build_db;
$tenv->update_env;

diag $tenv->report;

http_request_ok 'index query', $tenv, '/testproj/latest/source',
    [ qr{^Content-Type:\s*text/html}, qr{href="latest/source/issue102.c"},
        qr{href="latest/source/arch"} ], 1;

http_request_ok 'identifier query', $tenv, '/testproj/v5.4/ident/gsb_buffer',
    [ qr{^Content-Type:\s*text/html}, qr{\bgsb_buffer\b},
        qr{"v5.4/source/drivers/i2c/i2c-core-acpi.c\#L23".+?
            drivers/i2c/i2c-core-acpi.c.+?
            line[ ]23.+?
            \bstruct\b}x ], 1;

# Doc comments: testcases pulled from t/300
http_request_ok 'doc-comment query (nonexistent)', $tenv,
    '/testproj/v5.4/ident/SOME_NONEXISTENT_IDENTIFIER_XYZZY_PLUGH',
    [ qr{^Content-Type:\s*text/html}, qr{<h\d>Identifier not used</h\d>}i], 1;

http_request_ok 'doc-comment query (existent but not documented)', $tenv,
    '/testproj/v5.4/ident/gsb_buffer',   # in drivers/i2c/i2c-core-acpi.c
    [
        qr{^Content-Type:\s*text/html},
        { not => qr{\bDocumented in\b} },
    ], 1;

http_request_ok 'ident query (existent, function, documented in C file)', $tenv,
    '/testproj/v5.4/ident/i2c_acpi_get_i2c_resource',
    [
        qr{^Content-Type:\s*text/html},
        qr{\bDocumented in \d},
        {doc => qr{drivers/i2c/i2c-core-acpi\.c.+\b45\b}},
    ], 1;

http_request_ok 'ident query (existent, function, documented in C file, #102)',
    $tenv, '/testproj/v5.4/ident/documented_function_XYZZY',
    [
        qr{^Content-Type:\s*text/html},
        qr{\bDocumented in \d},
        {doc => qr{issue102\.c.+\b6\b}},
    ], 1;

done_testing;
