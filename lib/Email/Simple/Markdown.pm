package Email::Simple::Markdown;
# ABSTRACT: simple email creation with auto text and html multipart body

use strict;
use warnings;

use Carp;

use Email::Abstract;
use Email::MIME;
use Email::Simple;

use List::Util qw/ first pairmap /;
use Module::Runtime qw/ use_module /;

use Moo;
extends 'Email::Simple';

sub BUILDARGS {
    my $class = shift;
    return {};
}

around create => sub {
    my ( $orig, $self, %arg ) = @_;

    my @local_args = qw/ css markdown_engine pre_markdown_filter charset /;
    my %md_arg;
    @md_arg{@local_args} = delete @arg{@local_args};

    my $email = $orig->( $self, %arg );

    $email->markdown_engine_set(
        $md_arg{markdown_engine}||'auto'
    );

    $email->charset_set( $md_arg{charset} ) if $md_arg{charset};
    $email->css_set($md_arg{css}) if $md_arg{css};
    $email->pre_markdown_filter_set($md_arg{pre_markdown_filter}) 
        if $md_arg{pre_markdown_filter};

    return $email;
};

our @SUPPORTED_ENGINES = qw/ Text::MultiMarkdown Text::Markdown /;

has markdown_engine => (
    is              => 'rw',
    lazy            => 1,
    default         => sub { $_[0]->find_markdown_engine },
    clearer         => 1,
    coerce          => sub {
        my( $value ) = @_;
        
        return $value eq 'auto'
            ? __PACKAGE__->find_markdown_engine 
            : $value;
    },
    trigger => sub{
        my( $self, $engine ) = @_;
        
        die "engine '$engine' not implementing a 'markdown' method\n"
            unless use_module($engine)->can('markdown');

        $self->clear_markdown_object;
    },
    writer => 'markdown_engine_set',
);

has markdown_object => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    default => sub { $_[0]->{markdown_engine}->new },
    handles => {
        _markdown => 'markdown',
    }
);

sub find_markdown_engine {
    first { eval { use_module($_) } } @SUPPORTED_ENGINES
        or die "No supported markdown engine found" 
}

has markdown_css => (
    is => 'rw',
    reader => 'css',
    writer => 'css_set',
    coerce => sub {
        my $css = shift;

        if ( ref $css eq 'ARRAY' ) {
            my @css = @$css;

            croak "number of argument is not even" if @css % 2;

            $css = join "\n", pairmap { "$a { $b }" } @css;
        }

        $css;
    },
);

has markdown_filter => (
    is => 'rw',
    writer => 'pre_markdown_filter_set',
);

has markdown_charset => (
    is => 'rw',
    writer => 'charset_set',
);

sub with_markdown {
    my $self = shift;

    my $body = $self->body;
    
    my $mail = Email::Abstract->new($self->SUPER::as_string)
                ->cast('Email::MIME');

    $mail->content_type_set('multipart/alternative');

    my $markdown = $body;

    if( my $filter =  $self->markdown_filter ) {
        local $_ = $markdown;
        $filter->();
        $markdown = $_;
    }
    
    $markdown = $self->_markdown($markdown);
    $markdown = '<style type="text/css">'
              . $self->css
              . '</style>'
              . $markdown 
        if $self->css;

    $mail->parts_set([
        Email::MIME->create(
            attributes => { 
                content_type => 'text/plain',
                charset      => $self->markdown_charset
            },
            body => $body,
        ),
        Email::MIME->create(
            attributes => {
                content_type => 'text/html',
                charset      => $self->markdown_charset,
                encoding     => 'quoted-printable',
            },
            body => $markdown,
        )
    ]);

    return Email::Abstract->new($mail);
}

sub as_string { $_[0]->with_markdown->as_string }

1;
