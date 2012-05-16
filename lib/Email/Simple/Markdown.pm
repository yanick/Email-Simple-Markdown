package Email::Simple::Markdown;

use strict;
use warnings;

use Email::Abstract;
use Text::MultiMarkdown qw/ markdown /;

use parent 'Email::Simple';

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

    $DB::single = 1;

    return Email::Abstract->new($mail);
}

sub as_string {
    $DB::single = 1;
    return $_[0]->with_markdown->as_string;
}

1;
