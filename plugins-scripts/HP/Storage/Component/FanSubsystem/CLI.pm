package HP::Storage::Component::FanSubsystem::CLI;
our @ISA = qw(HP::Storage::Component::FanSubsystem);

use strict;
use Nagios::Plugin;

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    runtime => $params{runtime},
    rawdata => $params{rawdata},
    fans => [],
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
  my %tmpfan = ();
  foreach (grep(/^fans/, split(/\n/, $self->{rawdata}))) {
    s/^fans //g;
    if (/^#(\d+)\s+([\w#_\/\-]+)\s+(\w+)\s+(\w+)\s+(FAILED|[N\/A\d]+)%*\s+([\w\/]+)\s+(FAILED|[N\/A\d]+)/) {
      %tmpfan = (
          name => $1, 
          location => lc $2,
          present => lc $3,
          speed => lc $4,
          pctmax => lc $5,                 # (FAILED|[N\/A\d]+)
          redundant => lc $6,
          partner => lc $7,                # (FAILED|[N\/A\d]+)
          runtime => $params{runtime},
      ); 
    } elsif (/^#(\d+)\s+([\w#_\/\-]+?)(Yes|No|N\/A)\s+(\w+)\s+(FAILED|[N\/A\d]+)%*\s+([\w\/]+)\s+(FAILED|[N\/A\d]+)/) { 
      # #5   SCSI_BACKPLANE_ZONEYes     NORMAL N/A  .... 
      %tmpfan = (
          name => $1,
          location => lc $2,
          present => lc $3,
          speed => lc $4, 
          pctmax => lc $5,
          redundant => lc $6,
          partner => lc $7,
          runtime => $params{runtime},
      );
    } elsif (/^#(\d+)\s+([\w#_\/\-]+)\s+[NOno]+\s/) {
      # Fan is not installed. #2   CPU#2   No   -   -    No      N/A      -
    } elsif (/^#(\d+)/) {
      main::contact_author("FAN", $_); 
    }
    if (%tmpfan) {
      if ($tmpfan{pctmax} !~ /^\d+$/) {
        if ($tmpfan{speed} eq 'normal') {
          $tmpfan{pctmax} = 50;
        } elsif ($tmpfan{speed} eq 'high') {
          $tmpfan{pctmax} = 100;
        } else {
          $tmpfan{pctmax} = 0;
        }
      }
      if($tmpfan{speed} eq 'failed') {
        $tmpfan{condition} = 'failed';
      } elsif($tmpfan{speed} eq 'n/a') {
        $tmpfan{condition} = 'other';
      } else {
        $tmpfan{condition} = 'ok';
      }
      $tmpfan{redundant} = $tmpfan{redundant} eq 'yes' ? 'redundant' :
          $tmpfan{redundant} eq 'no' ? 'notredundant' : 'other';
      $tmpfan{present} = $tmpfan{present} eq 'yes' ? 'present' :
          $tmpfan{present} eq 'failed' ? 'present' :
          $tmpfan{present} eq 'no' ? 'notpresent' : 'other';
      push(@{$self->{fans}},
          HP::Storage::Component::FanSubsystem::Fan->new(%tmpfan));
      %tmpfan = ();
    }
  }
}

sub overall_check {
  my $self = shift;
  # nix. nur wegen der gleichheit mit snmp
}
1;
