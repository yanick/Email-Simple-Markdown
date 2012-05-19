package Email::Simple::Markdown;
# ABSTRACT: simple email creation with auto text and html multipart body

=head1 SYNOPSIS

    use Email::Simple::Markdown;

    my $email = Email::Simple::Markdown->create(
        header => [
            From    => 'me@here.com',
            To      => 'you@there.com',
            Subject => q{Here's a multipart email},
        ],
        body => '[this](http://metacpan.org/search?q=Email::Simple::Markdown) is *amazing*',
    );

    print $email->as_string;

=head1 DESCRIPTION

I<Email::Simple::Markdown> behaves almost exactly like L<Email::Simple>,
excepts for one detail: when its method C<as_string()> is invoked, the
returned string representation of the email has multipart body with a 
I<text/plain> element (the original body), and a I<text/html> element,
the markdown rendering of the text body.

The markdown convertion is done using L<Text::MultiMarkdown>.

=head1 METHODS

I<Email::Simple::Markdown> inherits all the methods if L<Email::Simple>. 
In addition, it provides one more method: I<with_markdown>.

=cut

use strict;
use warnings;

use Email::Abstract;
use Email::MIME;
use Email::Simple;

use Text::MultiMarkdown qw/ markdown /;

use parent 'Email::Simple';

=head2 with_markdown()

Returns an L<Email::Abstract> representation of the email, with 
its multipart body.

=cut

sub with_markdown {
    my $self = shift;

    my $body = $self->body;
    
    my $mail = Email::Abstract->new($self->SUPER::as_string)
                ->cast('Email::MIME');

    $mail->content_type_set('multipart/alternative');

    $mail->parts_set([
        Email::MIME->create(
            attributes => { content_type => 'text/plain' },
            body => $body,
        ),
        Email::MIME->create(
            attributes => {
                content_type => 'text/html',
                encoding => 'quoted-printable',
            },
            body => markdown($body),
        )
    ]);

    return Email::Abstract->new($mail);
}

sub as_string {
    return $_[0]->with_markdown->as_string;
}

1;
