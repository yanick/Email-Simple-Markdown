package Email::Simple::Markdown;
# ABSTRACT: simple email creation with auto text and html multipart body


use strict;
use warnings;

use Carp;

use Email::Abstract;
use Email::MIME;
use Email::Simple;

use List::Util qw/ first /;
use Module::Runtime qw/ use_module /;

use parent 'Email::Simple';


sub create {
    my ( $self, %arg ) = @_;

    my @local_args = qw/ css markdown_engine pre_markdown_filter charset /;
    my %md_arg;
    @md_arg{@local_args} = delete @arg{@local_args};

    my $email = $self->SUPER::create(%arg);

    $email->markdown_engine_set(
        $md_arg{markdown_engine}||'auto'
    );

    $email->charset_set( $md_arg{charset} ) if $md_arg{charset};
    $email->css_set($md_arg{css}) if $md_arg{css};
    $email->pre_markdown_filter_set($md_arg{pre_markdown_filter}) 
        if $md_arg{pre_markdown_filter};

    return $email;
}


# TODO Moo'fy this base

sub markdown_engine { return $_[0]->{markdown_engine} };


our @SUPPORTED_ENGINES = qw/ Text::MultiMarkdown Text::Markdown /;

sub markdown_engine_set {
    my ( $self, $engine ) = @_;

    $engine = $self->find_markdown_engine if $engine eq 'auto';

    croak "'$engine' is not supported" 
        unless grep { $_ eq $engine } @SUPPORTED_ENGINES;

    use_module( $engine );

    $self->{markdown_engine} = $engine;
    $self->{markdown_object} = $engine->new;

    return;
}

sub find_markdown_engine {
    first { eval { use_module($_) } } @SUPPORTED_ENGINES
        or die "No supported markdown engine found" 
}

sub _markdown {
    my( $self, $text ) = @_;

    return $self->{markdown_object}->markdown($text);
}


sub css { return $_[0]->{markdown_css} };


sub css_set {
    my( $self, $css ) = @_;

    if ( ref $css eq 'ARRAY' ) {
        my @css = @$css;

        croak "number of argument is not even" if @css % 2;

        $css = '';
        while( my( $sel, $style ) = splice @css, 0, 2 ) {
            $css .= "$sel { $style }\n";
        }
    }

    $self->{markdown_css} = $css;

    return $self;
}


sub pre_markdown_filter_set {
    my ( $self, $sub ) = @_;
    $self->{markdown_filter} = $sub;
    return $self;
}


sub charset_set {
    my( $self, $charset ) = @_;
    $self->{markdown_charset} = $charset;

    return $self;
}



sub with_markdown {
    my $self = shift;

    my $body = $self->body;
    
    my $mail = Email::Abstract->new($self->SUPER::as_string)
                ->cast('Email::MIME');

    $mail->content_type_set('multipart/alternative');

    my $markdown = $body;

    if( $self->{markdown_filter} ) {
        local $_ = $markdown;
        $self->{markdown_filter}->();
        $markdown = $_;
    }
    
    $markdown = $self->_markdown($markdown);
    $markdown = '<style type="text/css">'
              . $self->{markdown_css}
              . '</style>'
              . $markdown 
        if $self->{markdown_css};

    $mail->parts_set([
        Email::MIME->create(
            attributes => { 
                content_type => 'text/plain', 
                charset => $self->{markdown_charset} 
            },
            body => $body,
        ),
        Email::MIME->create(
            attributes => {
                content_type => 'text/html',
                charset => $self->{markdown_charset},
                encoding => 'quoted-printable',
            },
            body => $markdown,
        )
    ]);

    return Email::Abstract->new($mail);
}

sub as_string {
    return $_[0]->with_markdown->as_string;
}

1;
