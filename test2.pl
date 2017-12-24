use Win32::Process::List;
my $P = Win32::Process::List->new();
my %list = $P->GetProcesses();        #returns the hashes with PID and process name
foreach my $key ( keys %list ) {
      # $list{$key} is now the process name and $key is the PID
      print sprintf("%30s has PID %15s", $list{$key}, $key) . "\n";
}

my $program = 'Code.exe';
my $PID = $P->GetProcessPid($program); #get the PID of process chrome.exe
print "$program $PID\n";

my $np = $P->GetNProcesses();  #returns the number of processes
print "Nro. procesos $np\n";
