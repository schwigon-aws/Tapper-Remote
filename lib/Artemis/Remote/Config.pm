package Artemis::Remote::Config;

use strict;
use warnings;

use Getopt::Long;
use Moose;
use Net::TFTP;
use Socket;   # for inet_aton and gethostbyname
use Sys::Hostname;
use YAML::Syck;


=head1 NAME

Artemis::Remote::Config - Get configuration from Artemis host

=head1 SYNOPSIS

 use Artemis::Remote::Config;

=head1 FUNCTIONS

=cut


=head2 get_artemis_host

Get hostname of artemis MCP host from kernel boot parameters.

@returnlist ($host,port) - string, int - hostname and port of MCP server

=cut

sub get_artemis_host
{
        my ($host, $port);
        # try kernel command line
        open FH,'<','/proc/cmdline';
        my $cmd_line = <FH>;
        close FH;
        ($host,undef,$port) = $cmd_line =~ m/artemis_host\s*=\s*(\w+)(:(\d+))?/;
        return($host,$port) if $host;

        # try %ENV
        if ($ENV{ARTEMIS_MCP_SERVER}) {
                $host = $ENV{ARTEMIS_MCP_SERVER};
                $port = $ENV{ARTEMIS_MCP_PORT};
                return ($host, $port);
        }

        # try multicast
}


=head2 gethostname

This function returns the host name of the machine. When NFS root is
used together with DHCP the hostname set in the kernel usually equals
the IP address received from DHCP as a string. In this case the kernel
hostname is set to the DNS hostname associated to this IP address.

@return hostname of the machine as set in the kernel

=cut

sub gethostname
{
	my ($self) = @_;
        my $hostname = Sys::Hostname::hostname();
	if ($hostname   =~ m/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
                ($hostname) = gethostbyaddr(inet_aton($hostname), AF_INET) or ( print("Can't get hostname: $!") and exit 1);
                $hostname   =~ s/^(\w+?)\..+$/$1/;
                system("hostname", "$hostname");
        } elsif ($hostname  =~ m/^([^.]+)./) {
                $hostname   = $1;
        }
	return $hostname;
}





=head2 get_local_data

Get local data needed for all tools running locally on NFS. The function tries
to get the MCP host and fetches the config from there. This reduces any need
for configuration outside MCP host and thus allows to use unchanged NFS root
file systems for both testing and production, with different MCP servers and
so on. 

@return success - hash reference containing the config
@return error   - error string 

=cut

sub get_local_data
{
        my ($self, $state) = @_;
        # logger will usually be initialised by caller
        my $tmpcfg={};

        my $config_file_name = '/etc/artemis';
        $config_file_name = $ENV{ARTEMIS_CONFIG} if $ENV{ARTEMIS_CONFIG};

        my ($server, $port, $help);
        Getopt::Long::GetOptions("host=s"   => \$server,
                                 "port=s"   => \$port,
                                 "config=s" => \$config_file_name,
                                 "help|h"   => \$help,);
        die "Usage: $0 [--host=host --port=port --config=file]\n" if $help;

        if (not -e $config_file_name) {
                my $hostname;
                $hostname           = $self->gethostname();
                ($server, $port)    = $self->get_artemis_host() if not $server;
                my $tftp            = Net::TFTP->new($server);
                $tftp->get("$hostname-$state", $config_file_name) or return("Can't get local data.",$tftp->error);
                $tmpcfg->{server}   = $server;
                $tmpcfg->{port}     = $port;
                $tmpcfg->{hostname} = $hostname;
        }

        my $config = YAML::Syck::LoadFile($config_file_name) or return ("Can't parse config received from server");
        $config->{filename} = $config_file_name;
        %$config=(%$config, %$tmpcfg);

        return $config;
}


1;

=head1 AUTHOR

OSRC SysInt Team, C<< <osrc-sysint at elbe.amd.com> >>

=head1 BUGS

None.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc Artemis


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 OSRC SysInt Team, all rights reserved.

This program is released under the following license: restrictive

