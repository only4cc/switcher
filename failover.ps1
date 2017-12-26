# failover.ps1
# Pre-Req.: Powershell Add-PSSnapin VeeamPSSnapin

$dir = "C:\Users\Julio\Dropbox\current\eContact\switcher"
cd $dir

Add-PSSnapin VeeamPSSnapin
Connect-VBRServer -Server veam-1-bkp-rpl.e-contact.cl
#Get-VBRServer
Get-VBRFailoverPlan -Name "FailOver_SQL" | Start-VBRFailoverPlan