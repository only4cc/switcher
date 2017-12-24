package Checks;
use strict;
use warnings;

use Data::Dumper;
use IO::Socket::PortState qw(check_ports);

use Exporter qw(import);
 
our @EXPORT_OK = qw(encuesta_demo encuesta_1433);

sub encuesta_demo {
    print localtime().": encuestando servicio ...\n";
    my $SEGUNDOS = ( 1+int(rand(8)) );
    print "=== demorare $SEGUNDOS segundos ===\n";
    my $res = system("sleep $SEGUNDOS");
    return 1;
}

sub encuesta_1433 {
    my $service = shift;
    my $timeout = shift;
    my ($host,$port) = split(':',$service);
    print "verificando $host $port proto:tcp\n"; 
    my %porthash = (
                        tcp => {
                                    $port    => {},
                                }
                    );
    my $resp = check_ports($host,$timeout,\%porthash);
    my $open = $resp->{tcp}->{$port}->{open};
    return $open;
}

1;