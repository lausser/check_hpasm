package HP::Storage::Component::Powersupply;
our @ISA = qw(HP::Storage::Component);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

{
  our @powersupplies = ();

  sub get_components {
    return @powersupplies;
  }

  sub init {
    my %params = @_;
    if ($params{method} eq 'snmp') {
      HP::Storage::Component::Powersupply::SNMP::init(%params);
    } else {
      HP::Storage::Component::Powersupply::CLI::init(%params);
    }
  }

}

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime}, 
    name => $params{name}, 
    present => $params{present},
    redundant => $params{redundant},
    condition => $params{condition},
    blacklisted => 0,
    info => undef,
    extendexinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  if ($self->{present} eq "present") {
    if ($self->{condition} ne "ok") {
      if ($self->{condition} eq "n/a") {
        $self->add_info(sprintf "powersupply #%d is missing", $self->{name});
      } else {
        $self->add_info(sprintf "powersupply #%d needs attention (%s)",
            $self->{name}, $self->{condition});
      }
      $self->add_message(CRITICAL, $self->{info});
    } else {
      $self->add_info(sprintf "powersupply #%d is %s",
          $self->{name}, $self->{condition});
    }
    $self->add_extendedinfo(sprintf "ps_%s=%s",
        $self->{name}, $self->{condition});
  } else {
    $self->add_info(sprintf "powersupply #%d is %s", 
        $self->{name}, $self->{present});
    $self->add_extendedinfo(sprintf "ps_%s=%s",
        $self->{name}, $self->{present});
  } 
}


sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{name};
  printf "name: %s\n", $self->{name};
  printf "present: %s\n", $self->{present};
  printf "redundant: %s\n", $self->{redundant};
  printf "condition: %s\n", $self->{condition};
  printf "blacklisted: %s\n", $self->{blacklisted};
  printf "info: %s\n\n", $self->{info};
}


package HP::Storage::Component::Powersupply::CLI;
our @ISA = qw(HP::Storage::Component::Powersupply);

use strict;

{
  sub init {
    my %params = @_;
    my %tmpps = (
      runtime => $params{runtime},
    );
    my $inblock = 0;
    foreach (grep(/^powersupply/, split(/\n/, $params{rawdata}))) {
      s/^powersupply //g;
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
          push(@HP::Storage::Component::Powersupply::powersupplies,
              HP::Storage::Component::Powersupply->new(%tmpps));
          %tmpps = (
            runtime => $params{runtime},
          );
        }
      }
    }
    if ($inblock) {
      push(@HP::Storage::Component::Powersupply::powersupplies,
          HP::Storage::Component::Powersupply->new(%tmpps));
      %tmpps = (
        runtime => $params{runtime},
      );
    }
  }
}

package HP::Storage::Component::Powersupply::SNMP;
our @ISA = qw(HP::Storage::Component::Powersupply);

use strict;

{
  sub init {
    my %params = @_;
    my $snmpwalk = $params{rawdata};
    my $cpqHeFltTolPowerSupplyEntry = "1.3.6.1.4.1.232.6.2.9.3.1";
    my $cpqHeFltTolPowerSupplyChassis = "1.3.6.1.4.1.232.6.2.9.3.1.1";
    my $cpqHeFltTolPowerSupplyBay = "1.3.6.1.4.1.232.6.2.9.3.1.2";
    my $cpqHeFltTolPowerSupplyPresent = "1.3.6.1.4.1.232.6.2.9.3.1.3";
    my $cpqHeFltTolPowerSupplyCondition = "1.3.6.1.4.1.232.6.2.9.3.1.4";
    my $cpqHeFltTolPowerSupplyRedundant = "1.3.6.1.4.1.232.6.2.9.3.1.9";
    my $cpqSeCpuStatus = "1.3.6.1.4.1.232.1.2.2.1.1.6";
    my $cpqHeFltTolPowerSupplyPresentValues = {
        1 => "other",
        2 => "absent",
        3 => "present",
    };
    my $cpqHeFltTolPowerSupplyConditionValues = {
        1 => "other",
        2 => "ok",
        3 => "degraded",
        4 => "failed",
    };
    my $cpqHeFltTolPowerSupplyRedundantValues = {
        1 => "other",
        2 => "notRedundant",
        3 => "redundant",
    }; 
    
    # INDEX { cpqHeFltTolPowerSupplyChassis, cpqHeFltTolPowerSupplyBay }
    my @indexes =
        SNMP::Utils::get_indices($snmpwalk, $cpqHeFltTolPowerSupplyEntry);
    foreach (@indexes) {
      my($idx1, $idx2) = ($_->[0], $_->[1]);
      push(@HP::Storage::Component::Powersupply::powersupplies,
          HP::Storage::Component::Powersupply->new(
        runtime => $params{runtime},
        name =>  
          SNMP::Utils::get_number(\@indexes, $idx1, $idx2),
        present => 
          lc SNMP::Utils::get_object_value(
              $snmpwalk, $cpqHeFltTolPowerSupplyPresent,
              $cpqHeFltTolPowerSupplyPresentValues,
              $idx1, $idx2),
        condition => 
          lc SNMP::Utils::get_object_value(
              $snmpwalk, $cpqHeFltTolPowerSupplyCondition,
              $cpqHeFltTolPowerSupplyConditionValues,
              $idx1, $idx2),
        redundant =>
          lc SNMP::Utils::get_object_value(
              $snmpwalk, $cpqHeFltTolPowerSupplyRedundant,
              $cpqHeFltTolPowerSupplyRedundantValues,
              $idx1, $idx2),
      ));
    }

  }
}
