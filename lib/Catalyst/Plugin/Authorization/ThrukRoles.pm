package Catalyst::Plugin::Authorization::ThrukRoles;

=head1 NAME

Catalyst::Plugin::Authorization::ThrukRoles - Authorization for monitoring objects like host/services...

=head1 SYNOPSIS

    use Catalyst qw/
        Authorization::ThrukRoles
    /;


=head1 DESCRIPTION

This authorization module provides authorization for monitoring objects like host/services.

=cut

use strict;
use warnings;

use base qw/Catalyst::Plugin::Authorization::Roles/;

=head1 METHODS

=head2 check_permissions

 check_permissions('host', $hostname)
 check_permissions('service', $servicename, $hostname)
 check_permissions('hostgroup', $hostgroupname)
 check_permissions('servicegroup', $servicegroupname)

 for example:
 $c->check_permissions('service', $service, $host)

=cut

sub check_permissions {
    my($c, $type, $value, $value2) = @_;

    $type   = '' unless defined $type;
    $value  = '' unless defined $value;
    $value2 = '' unless defined $value2;

    my $count = 0;
    if($type eq 'host') {
        $count = $c->{'live'}->selectscalar_value("GET hosts\n".Thruk::Utils::get_auth_filter($c, 'hosts')."\nStats: name = $value", { Sum => 1 });
    }
    elsif($type eq 'service') {
        $count = $c->{'live'}->selectscalar_value("GET services\n".Thruk::Utils::get_auth_filter($c, 'services')."\nStats: description = $value\nFilter: host_name = $value2", { Sum => 1 });
    }
    elsif($type eq 'hostgroup') {
        my $count1 = $c->{'live'}->selectscalar_value("GET hosts\n".Thruk::Utils::get_auth_filter($c, 'hosts')."\nStats: groups >= $value", { Sum => 1 });
        my $count2 = $c->{'live'}->selectscalar_value("GET hosts\nStats: groups >= $value", { Sum => 1 });
        $count = 0;
        if(defined $count1 and defined $count2 and $count1 == $count2 and $count2 != 0) {
            $count = 1;
        }
    }
    elsif($type eq 'servicegroup') {
        my $count1 = $c->{'live'}->selectscalar_value("GET services\n".Thruk::Utils::get_auth_filter($c, 'services')."\nStats: groups >= $value", { Sum => 1 });
        my $count2 = $c->{'live'}->selectscalar_value("GET services\nStats: groups >= $value", { Sum => 1 });
        $count = 0;
        if(defined $count1 and defined $count2 and $count1 == $count2 and $count2 != 0) {
            $count = 1;
        }
    }
    else {
        $c->error("unknown auth role check: ".$type);
        return 0;
    }
    $count = 0 unless defined $count;
    $c->log->debug("count: ".$count);
    if($count > 0) {
        $c->log->debug("check_permissions('".$type."', '".$value."', '".$value2."') -> access granted");
        return 1;
    }
    $c->log->debug("check_permissions('".$type."', '".$value."', '".$value2."') -> access denied");
    return 0;
}

1;

