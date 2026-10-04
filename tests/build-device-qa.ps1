param([string]$ToolRoot = (Join-Path $PSScriptRoot '..\..\..\work\tools'))
$ErrorActionPreference='Stop'
$ToolRoot=(Resolve-Path -LiteralPath $ToolRoot).Path
$jdk=Get-ChildItem -LiteralPath $ToolRoot -Directory | Where-Object {Test-Path -LiteralPath (Join-Path $_.FullName 'bin\javac.exe')} | Select-Object -First 1
$java=Join-Path $jdk.FullName 'bin\java.exe';$javac=Join-Path $jdk.FullName 'bin\javac.exe';$jar=Join-Path $jdk.FullName 'bin\jar.exe'
$bt=Join-Path $ToolRoot 'android-15';$android=Join-Path $ToolRoot 'android-35\android.jar'
$build=Join-Path $PSScriptRoot '..\..\..\work\device-qa'
$appClasses=Join-Path $PSScriptRoot '..\..\..\work\build\classes'
New-Item -ItemType Directory -Force -Path $build,(Join-Path $build 'classes'),(Join-Path $build 'dex') | Out-Null
@'
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="id.kabar.qa">
 <uses-sdk android:minSdkVersion="26" android:targetSdkVersion="35" />
 <application android:label="Kabar QA" android:debuggable="true" />
 <instrumentation android:name="id.kabar.app.DeviceQA" android:targetPackage="id.kabar.app" android:functionalTest="true" />
</manifest>
'@ | Set-Content -LiteralPath (Join-Path $build 'AndroidManifest.xml') -Encoding utf8NoBOM
function Run([string]$exe,[string[]]$arguments){& $exe @arguments;if($LASTEXITCODE -ne 0){throw "QA build failed: $exe"}}
Run (Join-Path $bt 'aapt2.exe') @('link','-o',(Join-Path $build 'base.apk'),'--manifest',(Join-Path $build 'AndroidManifest.xml'),'-I',$android)
Run $javac @('-encoding','UTF-8','--release','8','-cp',"$android;$appClasses",'-d',(Join-Path $build 'classes'),(Join-Path $PSScriptRoot 'DeviceQA.java'),(Join-Path $PSScriptRoot 'WidgetAssertions.java'))
Run $jar @('cf',(Join-Path $build 'classes.jar'),'-C',(Join-Path $build 'classes'),'.')
Run $java @('-cp',(Join-Path $bt 'lib\d8.jar'),'com.android.tools.r8.D8','--lib',$android,'--classpath',$appClasses,'--min-api','26','--output',(Join-Path $build 'dex'),(Join-Path $build 'classes.jar'))
Run $jar @('uf',(Join-Path $build 'base.apk'),'-C',(Join-Path $build 'dex'),'classes.dex')
Run (Join-Path $bt 'zipalign.exe') @('-f','-p','4',(Join-Path $build 'base.apk'),(Join-Path $build 'aligned.apk'))
Run $java @('-jar',(Join-Path $bt 'lib\apksigner.jar'),'sign','--ks',(Join-Path $ToolRoot 'kabar-test.p12'),'--ks-pass','pass:kabar-development-only','--out',(Join-Path $build 'Kabar-QA.apk'),(Join-Path $build 'aligned.apk'))
Write-Output 'Device QA APK built (work/device-qa/Kabar-QA.apk)'
