$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
if (Test-Path "$env:ProgramFiles\Git\usr\bin") { #enable ssh-agent from posh-git
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}
if (Test-Path "$root\Modules\psake") { #enable ssh-agent from posh-git
    $env:path="$env:path;$root\Modules\psake"
}
. $root\Modules\posh-git\profile.example.ps1
Import-Module z
Import-Module psake
Import-Module $root\Modules\posh-docker\posh-docker\posh-docker.psm1

#psake expansion
Push-Location $root
. ./PsakeTabExpansion.ps1
Pop-Location
if((Test-Path Function:\TabExpansion) -and (-not (Test-Path Function:\DefaultTabExpansion))) {
    Rename-Item Function:\TabExpansion DefaultTabExpansion
}
# Set up tab expansion and include psake expansion
function TabExpansion($line, $lastWord) {
    $lastBlock = [regex]::Split($line, '[|;]')[-1]
    
    switch -regex ($lastBlock) {
        # Execute psake tab completion for all psake-related commands
        '(Invoke-psake|psake) (.*)' { PsakeTabExpansion $lastBlock }
        # Fall back on existing tab expansion
        default { DefaultTabExpansion $line $lastWord }
    }
}
#end of psake expansion

#aliases:
Set-Alias pester invoke-pester
function add {
    if ($args) {
        Invoke-Expression ( "git add " + ($args -join ' ') )
    } else {
        git add -A :/
    }
}
Add-Alias st 'git status'
Add-Alias push 'git push'
Add-Alias pull 'git pull'
Add-Alias log 'git log'
Add-Alias ci 'git commit'
Add-Alias co 'git checkout'
Add-Alias dif 'git diff'
Add-Alias rs 'git reset'
Add-Alias rb 'git rebase'
Add-Alias fixup 'git fixup'
Add-Alias branch 'git branch'
Add-Alias tag 'git tag'
Add-Alias up 'git up'
Add-Alias sync 'git sync'
Add-Alias l 'ls'
Add-Alias ll 'ls -Force'
Add-Alias gitbash '. "C:\Program Files\Git\usr\bin\bash.exe"'
Add-Alias ccat "pygmentize.exe -g -O style=vs -f console16m"

function time() {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Expression $($args -join ' ')
    $sw.Stop()
    $sw.elapsed
}
# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
Set-PSReadlineOption -EditMode Vi

#log history
$historyFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
if (Test-Path $historyFilePath) {
    $numberOfPreviousCommands = $(Get-Content $historyFilePath | Measure-Object -Line).Lines - 1
} else {
    $numberOfPreviousCommands = 1
}
Register-EngineEvent PowerShell.Exiting -Action {
    $history = Get-History
    $filteredHistory = $history[($numberOfPreviousCommands-1)..($history.Length - 2)]
    $filteredHistory | Export-Csv $historyFilePath -Append
} | Out-Null
if (Test-path $historyFilePath) { Import-Csv $historyFilePath | Add-History }

if (gcm hub -ErrorAction SilentlyContinue) {
    Add-Alias git "$($(gcm hub).Source)"
}

function color ($lexer='javascript') {
    Begin { $t = "" }
    Process { $t = "$t
    $_" }
    End { $t | pygmentize.exe -l $lexer -O style=vs -f console16m; }
} # call like: docker inspect foo | color

function netstatx
{
    netstat -ano | Where-Object{$_ -match 'LISTENING|UDP'} | ForEach-Object{
        $split = $_.Trim() -split "\s+"
        New-Object -Type pscustomobject -Property @{
            "Proto" = $split[0]
            "Local Address" = $split[1]
            "Foreign Address" = $split[2]
            # Some might not have a state. Check to see if the last element is a number. If it is ignore it
            "State" = if($split[3] -notmatch "\d+"){$split[3]}else{""}
            # The last element in every case will be a PID
            "Process Id" = $split[-1]
            "Process Name" = $(Get-Process -ErrorVariable a -ErrorAction SilentlyContinue -Id $split[-1] ).ProcessName
        }
    }  | Format-Table -Property Proto,"Local Address","Foreign Address",State,"Process Id","Process Name" -AutoSize
}
