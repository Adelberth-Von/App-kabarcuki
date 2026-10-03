param(
    [string]$ToolRoot = (Join-Path $PSScriptRoot '..\..\work\tools'),
    [string]$OutDir = $PSScriptRoot,
    [switch]$Test
)
$ErrorActionPreference = 'Stop'
$ToolRoot = (Resolve-Path -LiteralPath $ToolRoot).Path
$jdk = Get-ChildItem -LiteralPath $ToolRoot -Directory | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'bin\javac.exe') } | Select-Object -First 1
if (-not $jdk) { throw 'Java JDK 17 tidak ditemukan. Siapkan JDK di ToolRoot.' }
$java = Join-Path $jdk.FullName 'bin\java.exe'
$javac = Join-Path $jdk.FullName 'bin\javac.exe'
$jar = Join-Path $jdk.FullName 'bin\jar.exe'
$keytool = Join-Path $jdk.FullName 'bin\keytool.exe'
$bt = Join-Path $ToolRoot 'android-15'
$android = Join-Path $ToolRoot 'android-35\android.jar'
$build = Join-Path $PSScriptRoot '..\..\work\build'
New-Item -ItemType Directory -Force -Path $build,(Join-Path $build 'classes'),(Join-Path $build 'generated'),(Join-Path $build 'dex') | Out-Null
function Run([string]$exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "Build gagal: $exe ($LASTEXITCODE)" }
}
Run (Join-Path $bt 'aapt2.exe') @('compile','--dir',(Join-Path $PSScriptRoot 'res'),'-o',(Join-Path $build 'resources.zip'))
Run (Join-Path $bt 'aapt2.exe') @('link','-o',(Join-Path $build 'base.apk'),'--manifest',(Join-Path $PSScriptRoot 'AndroidManifest.xml'),'-I',$android,'--java',(Join-Path $build 'generated'),'--min-sdk-version','29','--target-sdk-version','35','--auto-add-overlay',(Join-Path $build 'resources.zip'))
$sources = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'src') -Filter '*.java' -Recurse | ForEach-Object FullName) + @(Get-ChildItem -LiteralPath (Join-Path $build 'generated') -Filter '*.java' -Recurse | ForEach-Object FullName)
$sourceList = Join-Path $build 'sources.txt'
$sources | ForEach-Object { '"' + $_.Replace('\','/') + '"' } | Set-Content -LiteralPath $sourceList -Encoding utf8NoBOM
Run $javac @('-encoding','UTF-8','--release','8','-classpath',$android,'-d',(Join-Path $build 'classes'),('@' + $sourceList))
Run $jar @('cf',(Join-Path $build 'classes.jar'),'-C',(Join-Path $build 'classes'),'.')
Run $java @('-cp',(Join-Path $bt 'lib\d8.jar'),'com.android.tools.r8.D8','--lib',$android,'--min-api','29','--output',(Join-Path $build 'dex'),(Join-Path $build 'classes.jar'))
Copy-Item -LiteralPath (Join-Path $build 'base.apk') -Destination (Join-Path $build 'unsigned.apk') -Force
Run $jar @('uf',(Join-Path $build 'unsigned.apk'),'-C',(Join-Path $build 'dex'),'classes.dex')
Run (Join-Path $bt 'zipalign.exe') @('-f','-p','4',(Join-Path $build 'unsigned.apk'),(Join-Path $build 'aligned.apk'))
$keystore = Join-Path $ToolRoot 'kabar-test.p12'
if (-not (Test-Path -LiteralPath $keystore)) { Run $keytool @('-genkeypair','-keystore',$keystore,'-storetype','PKCS12','-storepass','kabar-development-only','-keypass','kabar-development-only','-alias','kabar','-keyalg','RSA','-keysize','2048','-validity','3650','-dname','CN=Kabar Local Test, O=Kabar') }
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$apk=Join-Path $OutDir 'Kabar-0.4.0.apk'
Run $java @('-jar',(Join-Path $bt 'lib\apksigner.jar'),'sign','--ks',$keystore,'--ks-pass','pass:kabar-development-only','--out',$apk,(Join-Path $build 'aligned.apk'))
Run $java @('-jar',(Join-Path $bt 'lib\apksigner.jar'),'verify','--verbose',$apk)
Run (Join-Path $bt 'aapt.exe') @('dump','badging',$apk)
Write-Output "APK: $apk"
if ($Test) { & (Join-Path $PSScriptRoot 'tests\run-tests.ps1') -ToolRoot $ToolRoot; if ($LASTEXITCODE -ne 0) { throw 'QA gagal' } }
