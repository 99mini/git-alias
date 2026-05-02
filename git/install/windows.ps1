# Git Alias Installer - Windows (PowerShell)
# Run with: powershell -ExecutionPolicy Bypass -File windows.ps1
#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$ScriptDir     = Split-Path -Parent $MyInvocation.MyCommand.Definition
$GitconfigFile = Join-Path $ScriptDir "..\alias\git-aliases.gitconfig"

# ── ANSI color support ────────────────────────────────────────────────────────

function Enable-ANSI {
  # Windows 10 1511+ supports ANSI via VirtualTerminalProcessing
  try {
    $OutputEncoding = [System.Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
    $null = [System.Console]::OutputEncoding
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class ConsoleHelper {
    [DllImport("kernel32.dll")] public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll")] public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
    [DllImport("kernel32.dll")] public static extern IntPtr GetStdHandle(int nStdHandle);
}
'@
    $handle = [ConsoleHelper]::GetStdHandle(-11)
    $mode   = 0
    [ConsoleHelper]::GetConsoleMode($handle, [ref]$mode) | Out-Null
    [ConsoleHelper]::SetConsoleMode($handle, $mode -bor 4) | Out-Null
  } catch { }
}

Enable-ANSI

$C = @{
  Red    = "`e[31m"
  Green  = "`e[32m"
  Yellow = "`e[33m"
  Blue   = "`e[34m"
  Cyan   = "`e[36m"
  Bold   = "`e[1m"
  Reset  = "`e[0m"
}

function Write-Color([string]$Text, [string]$Color = 'Reset') {
  Write-Host "$($C[$Color])$Text$($C.Reset)"
}

# ── helpers ───────────────────────────────────────────────────────────────────

function Test-Git {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Color "Error: git is not installed or not in PATH." Red
    exit 1
  }
}

function Test-GitconfigFile {
  if (-not (Test-Path $GitconfigFile)) {
    Write-Color "Error: git-aliases.gitconfig not found at $GitconfigFile" Red
    exit 1
  }
}

function Test-InGitRepo {
  $result = git rev-parse --is-inside-work-tree 2>$null
  return $LASTEXITCODE -eq 0
}

function Get-AliasNames {
  git config --file $GitconfigFile --get-regexp '^alias\.' |
    ForEach-Object { ($_ -split '\s+', 2)[0] -replace '^alias\.', '' } |
    Sort-Object
}

function Get-AliasValue([string]$Name) {
  git config --file $GitconfigFile "alias.$Name"
}

function Set-GitAlias([string]$Scope, [string]$Name) {
  $value = Get-AliasValue $Name
  $exitCode = 0
  git config $Scope "alias.$Name" $value 2>$null
  $exitCode = $LASTEXITCODE
  if ($exitCode -eq 0) {
    Write-Host "  $($C.Green)v$($C.Reset) $Name"
  } else {
    Write-Host "  $($C.Red)x$($C.Reset) $Name (failed)"
  }
}

function Remove-GitAlias([string]$Scope, [string]$Name) {
  git config $Scope --unset "alias.$Name" 2>$null
  if ($LASTEXITCODE -eq 0) {
    Write-Host "  $($C.Green)v$($C.Reset) $Name removed"
  } else {
    Write-Host "  $($C.Yellow)~$($C.Reset) $Name (not set)"
  }
}

function Assert-LocalScope {
  if (-not (Test-InGitRepo)) {
    Write-Color "Error: Not inside a git repository." Red
    Write-Host "  Run this from within a git repository to use local scope."
    Write-Host "  Use global scope, or cd into a git project first."
    return $false
  }
  return $true
}

# ── bulk operations ───────────────────────────────────────────────────────────

function Install-AllAliases([string]$Scope, [string]$Label) {
  if ($Scope -eq '--local' -and -not (Assert-LocalScope)) { return }
  Write-Host ""
  Write-Color "Installing all aliases ($Label)..." Blue
  Write-Host ""
  foreach ($name in (Get-AliasNames)) {
    Set-GitAlias $Scope $name
  }
  Write-Host ""
  Write-Color "Done! All aliases installed ($Label)." Green
}

function Remove-AllAliases([string]$Scope, [string]$Label) {
  if ($Scope -eq '--local' -and -not (Assert-LocalScope)) { return }
  Write-Host ""
  Write-Color "Removing all aliases ($Label)..." Yellow
  Write-Host ""
  foreach ($name in (Get-AliasNames)) {
    Remove-GitAlias $Scope $name
  }
  Write-Host ""
  Write-Color "Done! All aliases removed ($Label)." Green
}

# ── selective operations ──────────────────────────────────────────────────────

function Invoke-PickAliases([string]$Action, [string]$Scope, [string]$Label) {
  if ($Scope -eq '--local' -and -not (Assert-LocalScope)) { return }

  $names = @(Get-AliasNames)

  Write-Host ""
  Write-Color "Available aliases:" Blue
  Write-Host ""
  for ($i = 0; $i -lt $names.Count; $i++) {
    Write-Host ("  {0,3}) {1}" -f ($i + 1), $names[$i])
  }

  Write-Host ""
  Write-Host "Enter numbers separated by spaces (e.g. 1 3 5),"
  Write-Host "  'all' to select all, or 'q' to go back:"
  $selection = Read-Host "> "

  if ($selection -match '^[qQ]$') { return }

  if ($selection -eq 'all') {
    if ($Action -eq 'install') { Install-AllAliases $Scope $Label }
    else                        { Remove-AllAliases  $Scope $Label }
    return
  }

  Write-Host ""
  foreach ($token in ($selection -split '\s+')) {
    if ($token -match '^\d+$') {
      $idx = [int]$token - 1
      if ($idx -ge 0 -and $idx -lt $names.Count) {
        $name = $names[$idx]
        if ($Action -eq 'install') { Set-GitAlias    $Scope $name }
        else                        { Remove-GitAlias $Scope $name }
      } else {
        Write-Host "  $($C.Red)Invalid:$($C.Reset) $token"
      }
    } elseif ($token -ne '') {
      Write-Host "  $($C.Red)Invalid:$($C.Reset) $token"
    }
  }
  Write-Host ""
  Write-Color "Done!" Green
}

# ── dependency check ──────────────────────────────────────────────────────────

function Test-Dependencies {
  Write-Host ""
  Write-Color "Checking dependencies..." Blue
  Write-Host ""
  $ok = $true

  if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $ver = (fzf --version 2>$null) | Select-Object -First 1
    Write-Host "  $($C.Green)v$($C.Reset) fzf $ver"
  } else {
    Write-Host "  $($C.Red)x$($C.Reset) fzf  (required for interactive selector aliases)"
    Write-Host "    Install with Chocolatey: $($C.Bold)choco install fzf$($C.Reset)"
    Write-Host "    Install with Scoop:      $($C.Bold)scoop install fzf$($C.Reset)"
    Write-Host "    Install with winget:     $($C.Bold)winget install junegunn.fzf$($C.Reset)"
    $ok = $false
  }

  if (Get-Command pygmentize -ErrorAction SilentlyContinue) {
    $ver = (pygmentize -V 2>$null) | Select-Object -First 1
    Write-Host "  $($C.Green)v$($C.Reset) pygments ($ver)"
  } else {
    Write-Host "  $($C.Yellow)!$($C.Reset) pygments  (optional — used for diff syntax highlighting)"
    Write-Host "    Install: $($C.Bold)pip install pygments$($C.Reset)"
  }

  Write-Host ""
  if ($ok) {
    Write-Color "All required dependencies are installed." Green
  } else {
    Write-Color "Install missing dependencies, then re-run this installer." Yellow
  }
}

# ── menu ──────────────────────────────────────────────────────────────────────

function Show-Menu {
  Write-Host ""
  Write-Color "╔════════════════════════════════════╗" Cyan
  Write-Color "║       Git Alias Installer           ║" Cyan
  Write-Color "║           Windows                   ║" Cyan
  Write-Color "╚════════════════════════════════════╝" Cyan
  Write-Host ""
  Write-Host "  $($C.Bold)Install$($C.Reset)"
  Write-Host "   1) Install ALL aliases  (local workspace)"
  Write-Host "   2) Install ALL aliases  (global)"
  Write-Host "   3) Install specific aliases  (local workspace)"
  Write-Host "   4) Install specific aliases  (global)"
  Write-Host ""
  Write-Host "  $($C.Bold)Remove$($C.Reset)"
  Write-Host "   5) Remove ALL aliases   (local workspace)"
  Write-Host "   6) Remove ALL aliases   (global)"
  Write-Host "   7) Remove specific aliases   (local workspace)"
  Write-Host "   8) Remove specific aliases   (global)"
  Write-Host ""
  Write-Host "  $($C.Bold)Other$($C.Reset)"
  Write-Host "   9) Check dependencies"
  Write-Host "   0) Exit"
  Write-Host ""
}

# ── entry point ───────────────────────────────────────────────────────────────

Test-Git
Test-GitconfigFile

while ($true) {
  Show-Menu
  $choice = Read-Host "Select option"

  switch ($choice) {
    '1' { Install-AllAliases  '--local'  'local workspace' }
    '2' { Install-AllAliases  '--global' 'global'          }
    '3' { Invoke-PickAliases  'install'  '--local'  'local workspace' }
    '4' { Invoke-PickAliases  'install'  '--global' 'global'          }
    '5' { Remove-AllAliases   '--local'  'local workspace' }
    '6' { Remove-AllAliases   '--global' 'global'          }
    '7' { Invoke-PickAliases  'remove'   '--local'  'local workspace' }
    '8' { Invoke-PickAliases  'remove'   '--global' 'global'          }
    '9' { Test-Dependencies }
    { $_ -in '0','q','Q' } {
      Write-Host ""
      Write-Color "Goodbye!" Green
      Write-Host ""
      exit 0
    }
    default { Write-Color "Invalid option: $choice" Red }
  }

  Write-Host ""
  Read-Host "Press Enter to continue"
}
