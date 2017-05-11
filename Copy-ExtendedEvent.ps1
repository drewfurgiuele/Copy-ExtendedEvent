param(
    [Parameter(Mandatory=$true)]  [string]$SourceHostName,
    [Parameter(Mandatory=$false)] [string]$SourceInstanceName = 'DEFAULT',
    [Parameter(Mandatory=$true)]  [string]$SessionName,
    [Parameter(Mandatory=$true)]  [string]$TargetHostName,
    [Parameter(Mandatory=$false)] [string]$TargetInstanceName = 'DEFAULT',
    [Parameter(Mandatory=$false)] [string]$Rename
)

$existingSession = Get-ChildItem -Path "SQLSERVER:\XEvent\$SourceHostName\$SourceInstanceName\Sessions" | Where-Object {$_.Name -eq $SessionName}
$targetstore = Get-ChildItem -Path "SQLSERVER:\XEvent\$TargetHostName" | Where-Object {$_.DisplayName -eq $TargetInstanceName}
$newSessionName = $sessionName
if ($rename) {$newSessionName = $rename}
#[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Management.XEvent")
$newSession = New-object Microsoft.SqlServer.Management.XEvent.Session -argumentlist $targetStore, $newSessionName

$newSession.MaxDispatchLatency = $existingSession.MaxDispatchLatency
$newSession.MaxEventSize = $existingSession.MaxEventSize
$newSession.MaxMemory = $existingSession.MaxMemory

ForEach ($e in $existingSession.Events) 
{
    $newSession.AddEvent($e.Name) | out-null
    $newEvent = $newSession.Events | Where-Object {$_.Name -eq $e.Name}
    $newEvent.Predicate = $e.Predicate
    ForEach ($a in $e.Actions)
    {
        $newEvent.AddAction($a.Name)
    }
}
ForEach ($t in $existingSession.Targets) 
{
    $newTarget = $newSession.AddTarget($t.Name)
    $targetFields = $t.TargetFields   
    ForEach ($tf in $targetFields)
    {
        $tfName = $tf.Name
        Write-Verbose "Setting target field $tfname..."
        if ($tf.Name -eq "filename" -and $rename -ne $null) {
            (($newSession.Targets | Where-Object {$_.Name -eq $t.Name}).TargetFields | Where-Object {$_.Name -eq $tf.Name}).Value = ($Rename + ".xev")
        } else {
            (($newSession.Targets | Where-Object {$_.Name -eq $t.Name}).TargetFields | Where-Object {$_.Name -eq $tf.Name}).Value = $tf.Value
        }
    }
}
$newSession.Create()
$newSession



