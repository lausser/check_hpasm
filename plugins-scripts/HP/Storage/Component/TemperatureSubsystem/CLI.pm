package HP::Storage::Component::TemperatureSubsystem::CLI;
our @ISA = qw(HP::Storage::Component::TemperatureSubsystem);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    temperatures => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  my %params = @_;
  my $tempcnt = 1;
  foreach (grep(/^temp/, split(/\n/, $params{rawdata}))) {
    s/^temp\s*//g;
    if (/^#(\d+)\s+([\w_\/\-#]+)\s+(\d+)C\/(\d+)F\s+(\d+)C\/(\d+)F/) {
      push(@{$self->{temperatures}},
          HP::Storage::Component::TemperatureSubsystem::Temperature->new(
              runtime => $params{runtime},
              name => $1,
              location => lc $2,
              degrees => $self->{runtime}->{options}->{celsius} ? $3 : $4,
              threshold => 
                exists $self->{runtime}->{options}->{thresholds}->{$1}
                    ? $self->{runtime}->{options}->{thresholds}->{$1} 
                    : $self->{runtime}->{options}->{celsius} ? $5 : $6,
              counter => $tempcnt++ ));
    } elsif (/^#(\d+)\s+([\w_\/\-#]+)\s+\-\s+(\d+)C\/(\d+)F/) {
      # #3        CPU#2                -       0C/0F
      $self->trace(2, sprintf "skipping temperature %s", $_);
    } elsif (/^#(\d+)\s+([\w_\/\-#]+)\s+(\d+)C\/(\d+)F\s+\-/) {
      # #3        CPU#2                0C/0F       -
      $self->trace(2, sprintf "skipping temperature %s", $_);
    } elsif (/^#(\d+)\s+([\w_\/\-#]+)\s+\-\s+\-/) {
      # #3        CPU#2                -       -
      $self->trace(2, sprintf "skipping temperature %s", $_);
    } elsif (/^#(\d+)/) {
      $self->trace(0, sprintf "send this to lausser: %s", $_);
    }
  }
}

1;
