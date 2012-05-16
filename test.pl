#!/usr/bin/perl 

use 5.10.0;

use strict;
use warnings;

use Email::Simple::Markdown;

say Email::Simple::Markdown->create(
    header => [
        From => 'me@boo.com',
        To   => 'you@boo.com',
        Subject => 'stuff',
    ],
    body => <<'EOT'
# Hi there!

| stuff | foo |
| yay   | xxx |

This works

    oh yeah
    This should be preformated
EOT
)->as_string;





