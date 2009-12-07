
  # cpqRackServerEnclosureTable
  my $cpqRackServerEnclosureEntry = '1.3.6.1.4.1.232.22.2.3.2.1.1';
  my $cpqRackServerEnclosureRack = '1.3.6.1.4.1.232.22.2.3.2.1.1.1';
  my $cpqRackServerEnclosureIndex = '1.3.6.1.4.1.232.22.2.3.2.1.1.2';
  my $cpqRackServerEnclosureName = '1.3.6.1.4.1.232.22.2.3.2.1.1.3';
  my $cpqRackServerEnclosureMaxNumBlades = '1.3.6.1.4.1.232.22.2.3.2.1.1.4';
  # INDEX { cpqRackServerEnclosureRack, cpqRackServerEnclosureIndex }
  # der gleiche dreck...
  @indexes =
      SNMP::Utils::get_indices($snmpwalk, $cpqRackServerEnclosureEntry);
  foreach (@indexes) {
    my($idx1) = ($_->[0]);
    my $rack = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureRack, $idx1);
    my $index = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureIndex, $idx1);
    my $name = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureName, $idx1);
    my $maxnumblades = lc SNMP::Utils::get_object(
        $snmpwalk, $cpqRackServerEnclosureMaxNumBlades, $idx1);
    push(@{$self->{server_enclosures}},
        HP::BladeSystem::Component::EnclosureSubsystem::ServerEnclosure->new(
            runtime => $self->{runtime},
            rack => $rack,
            enclosure => $index,
            name => $name,
            maxnumblades => $maxnumblades,
        ));
  }


1;
