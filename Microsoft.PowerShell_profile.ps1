$root = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
if (Test-Path "$env:ProgramFiles\Git\usr\bin") { #enable ssh-agent from posh-git
    $env:path="$env:path;$env:ProgramFiles\Git\usr\bin"
}
. $root\Modules\posh-git\profile.example.ps1
Import-Module z

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
Add-Alias efadd 'dotnet ef migrations add -s ..\Icatu.IdentityServer\Icatu.IdentityServer.csproj -c ApplicationDbContext $args'
Add-Alias efrem 'dotnet ef migrations remove -s ..\Icatu.IdentityServer\Icatu.IdentityServer.csproj -c ApplicationDbContext'
Add-Alias sln 'Invoke-Item *.sln'

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

# PowerShell parameter completion shim for the dotnet CLI 
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
    param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
           [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
}

Set-PSReadlineKeyHandler -Chord UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Chord DownArrow -Function HistorySearchForward

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

$env:COMPOSE_CONVERT_WINDOWS_PATHS=1
# # Helper function to change directory to my development workspace
# # Change c:\ws to your usual workspace and everytime you type
# # in cws from PowerShell it will take you directly there.
# function cws { Set-Location c:\ws }
# # Helper function to set location to the User Profile directory
# function cuserprofile { Set-Location ~ }
# Set-Alias ~ cuserprofile -Option AllScope
# # Helper function to show Unicode character
# function U
# {
#     param
#     (
#         [int] $Code
#     )
 
#     if ((0 -le $Code) -and ($Code -le 0xFFFF))
#     {
#         return [char] $Code
#     }
 
#     if ((0x10000 -le $Code) -and ($Code -le 0x10FFFF))
#     {
#         return [char]::ConvertFromUtf32($Code)
#     }
 
#     throw "Invalid character code $Code"
# }
# # Ensure posh-git is loaded
# Import-Module -Name posh-git
# # Start SshAgent if not already
# # Need this if you are using github as your remote git repository
# if (! (ps | ? { $_.Name -eq 'ssh-agent'})) {
#     Start-SshAgent
# }
# # Ensure oh-my-posh is loaded
# Import-Module -Name oh-my-posh
# # Default the prompt to agnoster oh-my-posh theme
# Set-Theme Honukai
