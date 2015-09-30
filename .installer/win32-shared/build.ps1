param([String]$platform)

$ErrorActionPreference = "Continue"

function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value;
    if($Invocation.PSScriptRoot)
    {
        $Invocation.PSScriptRoot;
    }
    Elseif($Invocation.MyCommand.Path)
    {
        Split-Path $Invocation.MyCommand.Path
    }
    else
    {
        $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf("\"));
    }
}

$script_dir = Get-ScriptDirectory
$shared_dir = "$script_dir\..\win32-shared"
$output_dir = "$script_dir\output"
$cache_dir = "$script_dir\..\cache\$platform"
$tmp_dir = [io.path]::GetTempFileName()
$wix_template_dir = "$shared_dir\wix"
$wix_dir = "C:\Program Files (x86)\WiX Toolset v3.9\bin"

if ($env:APPVEYOR_REPO_BRANCH -eq 'develop') {
  $gateblu_version="develop"
  $gateblu_legal_version="0.0.0"
} elseif ($env:APPVEYOR_REPO_TAG_NAME){
  $gateblu_version=$env:APPVEYOR_REPO_TAG_NAME
  $gateblu_legal_version = "$gateblu_version" -replace 'v', ''
} else {
  $gateblu_version='latest'
  $gateblu_legal_version="0.0.0"
}

echo "Building Gateblu $gateblu_version"

@(
    $output_dir
    $tmp_dir
) |
ForEach-Object {
  If (Test-Path $_) {
    Remove-Item $_ -Recurse -Force -ErrorAction Stop
  }
  mkdir $_ | Out-Null
}

If (!(Test-Path $cache_dir)){
  mkdir $cache_dir | Out-Null
}

echo "Copying to $tmp_dir..."
#Copy excluding .git and installer
robocopy $script_dir\..\.. $tmp_dir /S /NFL /NDL /NS /NC /NJH /NJS /XD .git installer .installer coverage test node_modules
robocopy $shared_dir\assets $tmp_dir /S /NFL /NDL /NS /NC /NJH /NJS

$destination = "$cache_dir\GatebluService.msi"
If(!(Test-Path $destination)) {
  $source = "https://s3-us-west-2.amazonaws.com/gateblu/gateblu-service/latest/GatebluService-$platform.msi"
  echo "Downloading $destination..."
  Invoke-WebRequest $source -OutFile $destination | Out-Null
}

$destination = "$cache_dir\gateblu-$platform-$gateblu_version.zip"
If(!(Test-Path $destination)) {
  if($gateblu_version -eq "develop") {
    echo "Sleeping for 45 minutes because this is the develop branch"
    Start-Sleep -s 2700;
  }
  $source = "https://s3-us-west-2.amazonaws.com/gateblu/gateblu-ui/$gateblu_version/gateblu-$platform.zip"
  echo "Downloading $destination..."
  for($i=1; $i -le 100; $i++) {
    echo "Checking $i for $source..."
    Invoke-WebRequest $source -OutFile $destination | Out-Null

    If(Test-Path $destination) {
      break
    }
    Start-Sleep -s 30;
  }
}

If(!(Test-Path "$destination")) {
  echo "$destination not found, giving up."
  exit 1
}

echo "Adding GatebluApp..."
$source = "$destination"
pushd $tmp_dir
7z -y x $source | Out-Null
popd

#Generate the installer
. $wix_dir\heat.exe dir $tmp_dir -srd -dr INSTALLDIR -cg MainComponentGroup -out $shared_dir\wix\directory.wxs -ke -sfrag -gg -var var.SourceDir -sreg -scom
. $wix_dir\candle.exe -dCacheDir="$cache_dir" -dSourceDir="$tmp_dir" -dProductVersion="$gateblu_legal_version" $wix_template_dir\*.wxs -o $output_dir\\ -ext WiXUtilExtension
. $wix_dir\light.exe -o $output_dir\GatebluApp-$platform.msi $output_dir\*.wixobj -cultures:en-US -ext WixUIExtension.dll -ext WiXUtilExtension

# Optional digital sign the certificate.
# You have to previously import it.
#. "C:\Program Files (x86)\Microsoft SDKs\Windows\v7.1A\Bin\signtool.exe" sign /n "Auth10" .\output\installer.msi

Copy-Item $output_dir\GatebluApp-$platform.msi $tmp_dir\GatebluApp.msi
Copy-Item $cache_dir\GatebluService.msi $tmp_dir\GatebluService.msi

. $wix_dir\candle.exe -dSourceDir="$tmp_dir" -dProductVersion="$gateblu_legal_version" -ext WixNetFxExtension -ext WixBalExtension -ext WixUtilExtension -o $output_dir\\ $shared_dir\wix-burn\burn.wxs
. $wix_dir\light.exe -o $output_dir\gateblu-$platform.exe -ext WixNetFxExtension -ext WixBalExtension -ext WixUtilExtension $output_dir\burn.wixobj

#Remove the temp
Remove-Item $tmp_dir -Recurse -Force
