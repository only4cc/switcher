
package Switcher::App;
use Dancer2;
use HTML::Table;
use Config::Tiny;
use Data::Dumper;
use lib "C:\\Users\\Julio\\Dropbox\\current\\eContact\\switcher\\";
use Status qw(sget);

# lee configuracion
my $fileconf = shift || 'C:\\Users\\Julio\\Dropbox\\current\\eContact\\switcher\\switchover.conf';
my $config = Config::Tiny->new;
$config = Config::Tiny->read( $fileconf );
die "no se pudo leer $fileconf\n" if ( $Config::Tiny::errstr );
my $group_id = $config->{_}->{groupname};
my $service_A = $config->{grupo}->{service_A};
my $service_B = $config->{grupo}->{service_B};
my $PERIODO_SEGS = $config->{grupo}->{lapso_revision}; # cada cuanto se vuelve a revisar
my $max_err = $config->{grupo}->{max_err_consec};
my $nb_secs = $config->{grupo}->{timeout_secs};   # Tiempo de Espera para dar "Timeout"
my $script  = $config->{grupo}->{script_activa_so};   # comando que activa el switchover


get '/' => sub {
    my $data = [
                ["grupo",$group_id],
                ["Servicio 1",$service_A ],
                ["Servicio 2",$service_B ],
                ["Periodo revision",$PERIODO_SEGS, "[sec]" ],
                ["maximo errores antes de switchover",$max_err],
                ["Tiempo timeout",$nb_secs, "[sec]" ],
                ["Script switchover",$script],
                ];
    my $tabla = new HTML::Table(
                                -spacing=>1,
                                -padding=>1,
                                -class=>'table table-hover table-bordered',
                                -data => $data 
                                );
    template 'index.tt',  { 'configuracion' => $tabla };
};


get '/switcher' => sub {
    my $ON = "<span class=\"label label-success\">On</span>";
    my $OFF = "<span class=\"label label-danger\">Off</span>";
    my $OP = "<button type=\"button\" class=\"btn btn-toggle\" data-toggle=\"button\" aria-pressed=\"false\" autocomplete=\"off\"><div class=\"handle\"></div></button>";
       $OP= "<button type=\"button\" class=\"btn btn-default\">switchover</button>";

    my $rdata  = getdata();
    my $header = ["grupo servicios","service_id IP:PORT","timestamp","estado","errores consecutivos","texto errores","elapsed \[s\]"];
    my $data   = [$rdata];
    #[$group_id,$service_A,$timestamp,$status,$err_consecutivos,$text_errors,$elapsed];
    my $tabla = new HTML::Table(
                                -spacing=>1,
                                -padding=>1,
                                -class=>'table table-hover table-bordered',
                                -head => $header,
                                -data => $data
                                );
    my $cellrow = 2;
    if ( $$data["status"] eq 'A' ) { 
        $tabla->setCell($cellrow, 4, $ON);
    } else {
        $tabla->setCell($cellrow, 4, $OFF);
    }

=begin
    my $cellrow = 1;
    foreach my $r ( @$data ) {
        if ( $$r[1] eq 'A' ) { 
            $tabla->setCell($cellrow, 2, $ON);
        } else {
            $tabla->setCell($cellrow, 2, $OFF);
        }
        if ( $$r[3] eq 'A' ) { 
            $tabla->setCell($cellrow, 4, $ON);
        } else {
            $tabla->setCell($cellrow, 4, $OFF);
        }
        $tabla->setCell($cellrow, 5, $OP);
        $cellrow++;
    };
=cut
	template 'switcher.tt', { 'tabla' => $tabla };
};


sub getdata {
    my $data = sget( $group_id, $service_A );
    return $data;
}

#-------------------------------------------
#------------------- REST ------------------
#-------------------------------------------

set serializer => 'JSON';

get '/status' => sub {
    my $data = sget( $group_id, $service_A );
#    return Dumper $data;
    return { 'grupo'=>$group_id, 'servicio_A'=>$service_A ,'timestamp'=>$data->{timestamp},
                    'status'=>$data->{status}, 'errores_consecutivos'=>$data->{err_consecutivos},
                    'texto_error'=>$data->{text_errors}, 'elapsed'=> $data->{elapsed} };
};

get '/stop' => sub {
    my $data = sget( $group_id, $service_A );
};

true;
