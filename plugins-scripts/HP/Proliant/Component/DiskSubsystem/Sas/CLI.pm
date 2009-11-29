package HP::Proliant::Component::DiskSubsystem::Sas::CLI;
our @ISA = qw(HP::Proliant::Component::DiskSubsystem::Sas);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    controllers => [],
    accelerators => [],
    physical_drives => [],
    logical_drives => [],
    spare_drives => [],
    blacklisted => 0,
  };
  bless $self, $class;
  return $self;
}

sub init {
  my $self = shift;
}

1;
