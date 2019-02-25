# Visual Studio Helper

PowerShell Helper scripts to manage Service Fabric services.

## Getting Started

* Copy the files
* Open Command Line or PowerShell (*Window + X, A*)
* If you opened Command Prompt, then type *powershell* in order to use PowerShell commands
* Navigate to the scripts directory <br />`cd your_directory`
* Type <br />`Import-Module .\VisualStudioHelper.psm1`
* Now you can use the methods from your PowerShell session

### Adding Script to Profile [Optional]

* Enable execution policy using PowerShell Admin <br /> `Set-ExecutionPolicy Unrestricted`
* Navigate to the profile path <br />`cd (Split-Path -parent $PROFILE)`
* Open the location in Explorer <br />`ii .`
* Create the user profile if it does not exist <br />`If (!(Test-Path -Path $PROFILE )) { New-Item -Type File -Path $PROFILE -Force }`
* Import the module in the PowerShell profile <br />`Import-Module -Path script_directory -ErrorAction SilentlyContinue`

# Examples

## Remove-BuildDirectories Example
Remove build directories
<details>
   <summary>Remove bin,obj,pkg and resharper directories for local directory</summary>
   <p>Remove-BuildDirectories</p>
</details>
<details>
   <summary>Remove bin,obj,pkg and resharper directories for specific directory</summary>
   <p>Remove-BuildDirectories -Path 'C:\git\Projects\TestProject\'</p>
</details>
<details>
   <summary>Remove specific files for specific directory</summary>
   <p>Remove-BuildDirectories -Includes '*.pyc' -Path 'C:\git\Python\'</p>
</details>
<details>
   <summary>Remove all files excluding specific files</summary>
   <p>Remove-BuildDirectories -Includes '*' -Excludes '*.cs', '*.sln', '*.csproj', '*.sfproj', '*.resx' -Path 'C:\git\C#\'</p>
</details>

## Register-PackageSources Example
Register package sources if the sources don't exist
<details>
   <summary>Register package sources to NuGet</summary>
   <p>Register-PackageSources -names 'Test', 'Test1' -Location 'NuGet Feed Url for Test', 'NuGet Feed Url for Test1'</p>
</details>
<details>
   <summary>Register package sources to another provider</summary>
   <p>Register-PackageSources -names 'Test', 'Test1' -Location 'Feed Url for Test', 'Url for Test1' -Provider 'MyProvider'</p>
</details>

## Enable-RemoteDebugging Example
Enable remote debugging for the current project
<details>
   <summary>Enable remote debugging by host, port and directory</summary>
   <p>Enable-RemoteDebugging -Host '10.101.10.1' -Port 4078 -Path 'C:\MyServices\TestService\'</p>
</details>

## Disable-RemoteDebugging Example
Disable remote debugging for the current project
<details>
   <summary>Disable remote debugging</summary>
   <p>Disable-RemoteDebugging</p>
</details>

## Get-References Example
Get references for all projects
<details>
   <summary>Get all references</summary>
   <p>Get-References</p>
</details>
<details>
   <summary>Get specific references</summary>
   <p>Get-References -Regex *Microsoft*</p>
</details>
<details>
   <summary>Get references by version</summary>
   <p>Get-References -Regex '*2.*'</p>
</details>
<details>
   <summary>Get only specific version references</summary>
   <p>Get-References -SpecificVersion $false</p>
</details>

## Remove-AllReferencePaths Example
Remove all reference paths from all projects
<details>
   <summary>Remove all reference paths</summary>
   <p>Remove-AllReferencePaths</p>
</details>

## Remove-ReferencePath Example
Remove specific reference path from all projects
<details>
   <summary>Remove specific reference path</summary>
   <p>Remove-ReferencePath "PACKAGE_NAME" "DLL_PATH\bin\Debug\"</p>
</details>

## Set-ReferencePath Example
Set specific reference path for all projects
<details>
   <summary>Set specific reference path</summary>
   <p>Set-ReferencePath "PACKAGE_NAME" "DLL_PATH\bin\Debug\"</p>
</details>
