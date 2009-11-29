package HP::Storage::Component::PowersupplySubsystem::CLI;
our @ISA = qw(HP::Storage::Component::PowersupplySubsystem);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    powersupplies => [],
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
  my %tmpps = (
    runtime => $self->{runtime},
  );
  my $inblock = 0;
  foreach (grep(/^powersupply/, split(/\n/, $self->{rawdata}))) {
    s/^powersupply\s*//g;
    if (/^Power supply #(\d+)/) {
      $tmpps{name} = $1;
      $inblock = 1;
    } elsif (/\s*Present\s+:\s+(\w+)/) {
      $tmpps{present} = lc $1 eq 'yes' ? 'present' :
          lc $1 eq 'no' ? 'absent': 'other';
    } elsif (/\s*Redundant\s*:\s+(\w+)/) {
      $tmpps{redundant} = lc $1 eq 'yes' ? 'redundant' :
          lc $1 eq 'no' ? 'notredundant' : 'other';
    } elsif (/\s*Condition\s*:\s+(\w+)/) {
      $tmpps{condition} = lc $1;
    } elsif (/\s*Power Supply not present/) {
      $tmpps{present} = "absent";
      $tmpps{condition} = "n/a";
      $tmpps{redundant} = "no";
    } elsif (/^\s*$/) {
      if ($inblock) {
        $inblock = 0;
        push(@{$self->{powersupplies}},
            HP::Storage::Component::PowersupplySubsystem::Powersupply->new(%tmpps));
        %tmpps = (
          runtime => $self->{runtime},
        );
      }
    }
  }
  if ($inblock) {
    push(@{$self->{powersupplies}},
        HP::Storage::Component::PowersupplySubsystem::Powersupply->new(%tmpps));
    %tmpps = (
      runtime => $params{runtime},
    );
  }
}

1;
