package HP::Storage::Component::DiskSubsystem::Da::CLI;
our @ISA = qw(HP::Storage::Component::DiskSubsystem::Da);

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

