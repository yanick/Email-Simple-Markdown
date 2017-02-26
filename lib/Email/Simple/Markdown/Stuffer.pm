package Email::Simple::Markdown::Stuffer;
# ABSTRACT: use Email::Simple::Markdown with Email::Stuffer

# TODO take care of the charsets

=head1 SYNOPSIS

    use Email::Simple::Markdown::Stuffer;

    my $stuffer = with_markdown(
        Email::Stuffer->new,
        Email::Simple::Markdown->create(
            markdown_engine     => 'Text::Markdown',
            pre_markdown_filter => sub {
                s#:-\)#<img src="smiley" alt="yeee!" /># 
            }
        ),
    );

    $stuffer->from         ('me@babyl.ca'     )
            ->to           ('yanick@babyl.ca' )
            ->markdown_body(<<'MD'            )->send;

    # Hi there!

    Cool, uh? :-)

    MD

=head1 DESCRIPTION

Quick and dirty integration of L<Email::Simple::Markdown>
and L<Email::Stuffer>.

Loading this module will automatically load both
L<Email::Stuffer> and L<Email::Simple::Markdown>. The function
C<with_markdown> is also exported.

=head1 FUNCTIONS

=head2 with_markdown

    with_markdown( $stuffer, $email_simple_markdown_object );

Applies a role to C<$stuffer>, which has to be
a L<Email::Stuffer> object> augmenting the object
with the method C<markdown_body>.  This method takes
a markdown text and assign the C<text_body> and C<html_body>
with the right values. C<$email_simple_markdown_object>
is optional. If not given, an L<Email::Simple::Markdown>
object with all the defaults will be used.


=cut

use strict;
use warnings;

use Role::Tiny;
use Email::Simple::Markdown;
use Email::Stuffer;

use parent 'Exporter';

our @EXPORT = qw/ with_markdown  /;

sub with_markdown {
    my( $stuffer, $esm ) = @_;

    Role::Tiny->apply_roles_to_object(
        $stuffer, 'Email::Simple::Markdown::ForStuffer'
    );
    
    $stuffer->markdown_engine($esm) if $esm;

    return $stuffer;
}

{
    package
        Email::Simple::Markdown::ForStuffer;

    use Moo::Role;

    sub markdown_engine {
        my $self = shift;

        $self->{__markdown_engine} = shift if @_;

        $self->{__markdown_engine} ||= 
            Email::Simple::Markdown->create;
    }

    sub markdown_body {
        my( $self, $body ) = @_;

        $self->markdown_engine->body_set($body);

        $self->text_body($body)->html_body( 
            $self->markdown_engine->markdown_part
        )
    }

}

1;
