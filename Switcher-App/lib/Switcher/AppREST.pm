
package Switcher::AppREST;
use Dancer2;
use Dancer2::Plugin::REST;
use Config::Tiny;
use Data::Dumper;
use Win32::Process::List;
use lib "C:\\Users\\Julio\\Dropbox\\current\\eContact\\switcher\\";
use Status qw(sget);

# Constantes
my $pwspath='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';   # ubicacion de powershell

set serializer => 'JSON'; 
set port => 5000;  # Util para ambiente de desarrollo 
set show_errors => 1;
set 'logger'    => 'console';
set 'log'       => 'warning';

# lee configuracion
my $fileconf = shift || 'C:\\Users\\Julio\\Dropbox\\current\\eContact\\switcher\\switchover.conf';
my $config = Config::Tiny->new;
$config = Config::Tiny->read( $fileconf );
die "no se pudo leer $fileconf\n" if ( $Config::Tiny::errstr );
my $group_id = $config->{_}->{groupname};
my $service_A = $config->{grupo}->{service_A};
my $service_B = $config->{grupo}->{service_B};
my $PERIODO_SEGS = $config->{grupo}->{lapso_revision};      # cada cuanto se vuelve a revisar
my $max_err = $config->{grupo}->{max_err_consec};
my $nb_secs = $config->{grupo}->{timeout_secs};             # Tiempo de Espera para dar "Timeout"
my $ps_script   = $config->{grupo}->{script_activa_so};     # script con comandos que activa el switchover

get '/help' => sub {
    return {
        help => 'este help',
        config=>'devuelve configuracion',
        status => 'estado del proceso en encuesta',
        kill => 'terinar arbol de un proceso, sintaxis /kill/pid',
        stop => 'detener el servicio de switchover',
        start => 'iniciar el servicio de switchover',
        process => 'lista de procesos sintaxis /process/pname',
    };
};

get '/config' => sub {
    return  { 
        "grupo"=>$group_id,
        "servicio_1"=>$service_A ,
        "servicio_2"=>$service_B ,
        "periodo_revision"=>$PERIODO_SEGS,,
        "max_err_antes_switchover"=>$max_err,
        "timeout"=>$nb_secs, 
        "script_switchover"=>$ps_script,
    }
};


get '/status' => sub {
    my $data = sget( $group_id, $service_A );
#print Dumper $data;
    return {    'grupo'=>$$data[0], 
                'servicio_A'=>$$data[1],
                'timestamp'=>$$data[2],
                'status'=>$$data[3], 
                'errores_consecutivos'=>$$data[4],
                'texto_error'=>$$data[5] ||'sin errores', 
                'last_elapsed'=> $$data[6] 
            };
};

get '/start' => sub {
    my $data = sget( $group_id, $service_A );
};

get '/switchover' => sub {
    system("$pwspath -command $ps_script");
};

get '/process/:pname' => sub {
    my $process_name = params->{pname};   # Ejemplo despues deberia ser el nombre del switcher
    my $P = Win32::Process::List->new();
    my %list = $P->GetProcesses();
    my $procesos;        
    foreach my $key ( keys %list ) {
      if ( $list{$key} =~ /$process_name/ ) {
         $procesos .= $list{$key}." ".$key." | ";
      }
    }
    return { 'procesos' => $procesos };
};

get "/kill/:pid" => sub {
    my $pid = params->{pid};
    system("TASKKILL /F /T /PID $pid");
};

get '/start' => sub {
    return { 'estado' => 'aun no implementada' };

};

true;
