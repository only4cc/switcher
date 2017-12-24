my $SO  = $^O;  # MSWin32
my $PID = $$;
print "Sistema Operativo: $SO\nProceso PID: $PID\n"; exit;

my $path='C:\Users\Julio\Dropbox\current\eContact\switcher\failover.ps1';
my $pwspath='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe';

system("$pwspath -command $path");
