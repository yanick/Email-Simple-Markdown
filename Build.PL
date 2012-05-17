
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Carp" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "Module::Build" => "0.3601",
    "Scalar::Util" => 0,
    "Test::More" => "0.94",
    "perl" => "5.004"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "simple email creation with auto text and html multipart body",
  "dist_author" => [
    "Yanick Champoux <yanick\@babyl.dyndns.org>"
  ],
  "dist_name" => "Email-Simple-Markdown",
  "dist_version" => "0.1.0",
  "license" => "perl",
  "module_name" => "Email::Simple::Markdown",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Email::Abstract" => 0,
    "Email::Simple" => 0,
    "Text::MultiMarkdown" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
