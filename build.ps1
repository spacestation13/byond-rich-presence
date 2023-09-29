# Builds the entire project and outputs the installer/update files in /artifacts
# Expects rust and dotnet to be installed

Push-Location src
try
{
    [XML]$versionXML = Get-Content Version.props
    $version = $versionXML.Project.PropertyGroup.Version
    $squirrelVersion = $versionXML.Project.PropertyGroup.SquirrelVersion
    Write-Output "Building version $version..."

    Set-Location rust-project
    rustup target add i686-pc-windows-msvc

    (Get-Content Cargo.toml).Replace("version = `"0.0.0`"", "version = `"$version`"").Replace("ProductVersion = `"0.0.0`"", "ProductVersion = `"$version`"").Replace("FileVersion = `"0.0.0`"", "FileVersion = `"$version`"") | Set-Content Cargo.toml
    try
    {
        cargo build --release --target i686-pc-windows-msvc
    }
    finally
    {
        git restore Cargo.*
    }

    Set-Location ../squirrel-project
    dotnet build -c Release

    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile nuget.exe
    (Get-Content package.nuspec).Replace("<version>0.0.0</version>", "<version>$version</version>") | Set-Content package.nuspec
    try
    {
        ./nuget.exe pack package.nuspec
    }
    finally
    {
        git restore package.nuspec
    }

    # We know nuget stores packages here on Windows
    # If this doesn't work on your machine, I blame you
    &"$Env:USERPROFILE/.nuget/packages/squirrel.windows/$squirrelVersion/tools/Squirrel.exe" --releasify "ByondRichPresence.$version.nupkg" --setupIcon=../../byond.ico -s -i=../../byond.ico -r ../../artifacts --no-msi
}
finally
{
    Pop-Location
}
