param([string]$ToolRoot = (Join-Path $PSScriptRoot '..\..\..\work\tools'),[switch]$Live)
$ErrorActionPreference='Stop'
$ToolRoot=(Resolve-Path -LiteralPath $ToolRoot).Path
$jdk=Get-ChildItem -LiteralPath $ToolRoot -Directory | Where-Object {Test-Path -LiteralPath (Join-Path $_.FullName 'bin\javac.exe')} | Select-Object -First 1
$java=Join-Path $jdk.FullName 'bin\java.exe'
$javac=Join-Path $jdk.FullName 'bin\javac.exe'
$classes=Join-Path $PSScriptRoot '..\..\..\work\test-classes'
New-Item -ItemType Directory -Force -Path $classes | Out-Null
$json=Join-Path $ToolRoot 'json.jar'
$source=Join-Path $PSScriptRoot '..\src\id\kabar\app'
& $javac -encoding UTF-8 --release 8 -cp $json -d $classes (Join-Path $source 'StatusLogic.java') (Join-Path $source 'Pairing.java') (Join-Path $source 'KabarState.java') (Join-Path $source 'Relay.java') (Join-Path $PSScriptRoot 'DomainTests.java')
if($LASTEXITCODE -ne 0){throw 'Kompilasi QA gagal'}
$arguments=@('-cp',"$classes;$json",'id.kabar.app.DomainTests')
if($Live){$arguments+='live'}
& $java @arguments
if($LASTEXITCODE -ne 0){throw 'Pengujian gagal'}
