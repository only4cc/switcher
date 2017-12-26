#!C:\Perl64\bin\perl.exe
#
# Objetivo: identificar si se requiere realizar un switchover, en ese caso ejecutar un script 
#           externo que lo hace. Los parametros se cargan desde un archivo de configuracion
# Parametros: 
#           Nombre del archivo de configuracion
#           Ejemplo:
#                   groupname=mssql_gui
#                   
#                   [grupo]
#                   service_A=10.33.16.87:1433
#                   service_B=192.10.33.16.99:1433
#                   max_err_consec=3
#                   lapso_revision=10
#                   timeout_secs=2
#                   script_activa_so=C:\switchover\activa_so.ps1
#
use strict;
use warnings;

use feature 'state';
use Time::Out qw(timeout) ;
use Time::HiRes qw(gettimeofday tv_interval);
use Config::Tiny;
use Capture::Tiny ':all';
use Log::Dispatch;
use Checks qw(encuesta_demo encuesta_1433);
use Status qw(sput);

# Constantes
my $QA = 0;
my $pwspath='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';   # ubicacion de powershell
my $pwd = Cwd::getdcwd();
my $logfile=$pwd.'\\switchover.log';

# Info. de este proceso
my $SO  = $^O;  # en Plat.Windows es : MSWin32
my $PID = $$;   # Process Id.

my $log = Log::Dispatch->new(
    outputs => [
        [ 'File',   min_level => 'debug', filename => $logfile ],
        [ 'Screen', min_level => 'debug' ],
    ],
);
$log->log( level => 'info', message => localtime().": iniciando encuestador\n" );
$log->log( level => 'info', message => localtime().": log en [$logfile]\n" );

# lee configuracion
my $fileconf = shift || 'switchover.conf';
$log->log( level => 'info', message => localtime().": configuracion desde en [$fileconf]\n" );

my $config = Config::Tiny->new;
$config = Config::Tiny->read( $fileconf );
if ( $Config::Tiny::errstr ) {
    $log->log_and_die( level => 'debug', message => localtime().": no se pudo leer el archivo de configuracion [$fileconf]\n" );
}
my $group_id    = $config->{_}->{groupname};              # nombre del grupo de servicios
my $service_A   = $config->{grupo}->{service_A};          # servicio a encuestar, el activo
my $service_B   = $config->{grupo}->{service_B};          # servicio pasivo a activar
my $PERIODO_SEGS= $config->{grupo}->{lapso_revision};     # cada cuanto se vuelve a revisar
my $max_err     = $config->{grupo}->{max_err_consec};     # maximo de errores antes de hacer switchover
my $nb_secs     = $config->{grupo}->{timeout_secs};       # Tiempo de Espera para dar "Timeout"
my $ps_script   = $config->{grupo}->{script_activa_so};   # script con comandos que activa el switchover


my $err_consecutivos=0;
my $res;
my $res_ant = 0;
my $text_errors='';
my $timestamp;
my ($elapsed, $t0);
# ciclo de revision
while ( 1 ) {
    #print "iteracion ".++$iter."\n";
    $t0 = [gettimeofday];
    timeout $nb_secs => sub {
        # Siguiente codigo va ser interrumpido si corre por mas de $nb_secs segundos.
        $res = encuesta_demo() if $QA;                       # Solo para probar 
        $res = encuesta_1433( $service_A,  $nb_secs ) if ( ! $QA );     # Habilitar 
    };
    if ($@) {
        print localtime().": termino por Timeout!\n";
        $res = -1;
    } else {
        if ( $res == 1 ) {
            print localtime().": termino ok\n";
        } else {
            print localtime().": termino con error\trespuesta:[$res]\n";
            $res = -1;
        }
    }    
    $timestamp = localtime();
    $elapsed = tv_interval ( $t0 );

    if ( $res < 0 and $res_ant < 0 ) {
        ++$err_consecutivos;
        sput( $group_id, $service_A, $timestamp, 'E', $err_consecutivos, $text_errors, $elapsed );
        acumula();
    } else {
        $err_consecutivos = 0;
        sput( $group_id, $service_A, $timestamp, 'A', $err_consecutivos, $text_errors, $elapsed );
    }
    $res_ant = $res;    
    print localtime().": durmiendo $PERIODO_SEGS ...\n";
    sleep $PERIODO_SEGS;
}

sub acumula {
    print localtime().": registro $err_consecutivos errores consecutivos ...\n";
    if ( $err_consecutivos > $max_err ) {
        accion();
    }
}

sub accion {
    $log->log( level => 'info', message => localtime().": *********** Activando Switchover ************\n" );
    $log->log( level => 'info', message => localtime().": ejecutando \t $ps_script\n");

    my ($stdout, $stderr, $exit) = capture {
        #system( $cmd, @args );
        system("$pwspath -command $ps_script");
        #system("powershell -executionpolicy bypass  -file $ps_script");
    };
    
    if ( $stderr =~ /Failed to connect to Veeam Backup/ ) {
        $log->log_and_die( level => 'info', message => localtime().": $stderr\n");
#       die "$0 no se pudo conectar usando [$ps_script]\n";
    }

    if ( $stdout ) {
            $log->log( level => 'info', message => localtime().": $stdout\n");
    } 
    $log->log( level => 'info', message => localtime().": finalizando $0\n");

    exit;   ### <<<<---- por el momento termina despues de gatillar la sol. de switchover a Veeam
}






