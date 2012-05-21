use strict;
use warnings;

use Test::More tests => 2;

use Email::Simple::Markdown;

my $email = Email::Simple::Markdown->create(
    header => [
        From    => 'me@here.com',
        To      => 'you@there.com',
        Subject => q{Here's a multipart email},
    ],
    body => '[this](http://metacpan.org/search?q=Email::Simple::Markdown) is *amazing*',
);

my $text = $email->as_string;

isa_ok $email->with_markdown, 'Email::Abstract';

like $text, qr#<em>amazing</em>#, 'html is present';
