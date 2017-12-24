package Status;

use warnings;
use strict;
use DBI;

use Exporter qw(import);
 
our @EXPORT_OK = qw(sput sget);

my $filename = "./data/data.s3db";    # no acepta otra ubicacion !!! :(
$filename = "C:\\Users\\Julio\\Dropbox\\current\\eContact\\switcher\\data\\data.s3db";

print "abriendo bd en $filename ... ";
my $dbh = DBI->connect(          
	"dbi:SQLite:dbname=$filename", 
	"",                          
	"",                          
	{ RaiseError => 1 },         
	) or die $DBI::errstr;
print "conectado\n";


END {
	$dbh->disconnect()  or die $DBI::errstr;
	print "\nbd. cerrada\n";
}

sub sput {
    my ($group_id, $service_A, $timestamp, $status, $err_consecutivos, $text_errors, $elapsed) = @_;
    #print "group $group_id, serviceA $service_A, ts $timestamp, status $status, errnum $err_consecutivos, errtext $text_errors";
	my $sth = $dbh->prepare('delete from status where group_id = ? and service_id = ?');
    $sth->execute( $group_id, $service_A );
	$sth = $dbh->prepare('insert into status ( group_id, service_id, timestamp, status, num_errors, text_errors, elapsed ) values ( ?, ?, ?, ?, ?, ?, ? )');
    $sth->execute( $group_id, $service_A, $timestamp, $status, $err_consecutivos, $text_errors, $elapsed );    
    if ( $DBI::errstr ) {
        return $DBI::errstr;
	}
    else {
	    return 'Registrado';
    }
}

sub sget {
	my $group_id   = shift;
    my $service_id = shift;
	my $sql = 'select group_id, service_id, timestamp, status, num_errors, text_errors, elapsed from status where group_id = (?) and service_id = (?)';
	my $sth = $dbh->prepare($sql);
	$sth->execute($group_id, $service_id);
	my @row; 
    my $count = 0;
    my ($service_A, $timestamp, $status, $err_consecutivos, $text_errors, $elapsed);
    while (@row = $sth->fetchrow_array) {
        #print "id: $row[0]  servicio: $row[1]  timestamp: $row[2] status: $row[3] err_consecutivos: $row[4] text_errors: $row[5] elapsed: $row[6]\n";
        $group_id         = $row[0];
        $service_A        = $row[1];
        $timestamp        = $row[2];
        $status           = $row[3];
        $err_consecutivos = $row[4];
        $text_errors      = $row[5];
        $elapsed          = $row[6];
        ++$count;
	}
    if ( $count ) {
        my $ret = [$group_id,$service_A,$timestamp,$status,$err_consecutivos,$text_errors,$elapsed];
        return $ret;
    }
    else {
        return "Error, no hay filas con el grupo $group_id";
    }
}


1;