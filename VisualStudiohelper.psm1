$ErrorActionPreference = "Stop";

function Create-UserProjectFile {
Param(
	[Parameter(Mandatory=$true)]
	[string]
	$project
);

	$projectUserFile = "$project.user";
    if(-not (Test-Path $projectUserFile)) {
        New-Item -Type file $projectUserFile;
        Add-Content $projectUserFile '<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="15.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
	<ReferencePath></ReferencePath>
  </PropertyGroup>
</Project>';
    }
}
function Set-ProjectReferencePath {
Param(
	[string]
	$project,
	
	[string]
	$path
);
	Create-UserProjectFile $project
	$projectUserFile = "$project.user";
    [xml]$xml = Get-Content "$projectUserFile";
    $propertyGroupNode = $xml.Project.PropertyGroup | Where { $_.ReferencePath -ne $null } 

    if($propertyGroupNode -eq $null) {
        $newPropertyGroup = $xml.CreateElement("PropertyGroup", "http://schemas.microsoft.com/developer/msbuild/2003");
        $propertyGroupNode = $xml.Project.AppendChild($newPropertyGroup);

        $newReferencePath = $xml.CreateElement("ReferencePath", "http://schemas.microsoft.com/developer/msbuild/2003");
        $newPropertyGroup.AppendChild($newReferencePath);
    }

    if($propertyGroupNode.ReferencePath.Contains($path)) {
        Write-Host "Reference path already in $project"
        return;
    }
    Write-Host "Adding reference path to $project";
	
    if($propertyGroupNode.ReferencePath.trim() -ne '') {
        $propertyGroupNode.ReferencePath += ";$path";
    } else {
        $propertyGroupNode.ReferencePath = $path;
    }

    $xml.Save($projectUserFile)
}
function Remove-ProjectReferencePath {
Param(
	[string]
	$project,
	
	[string]
	$path
);
	$regex = $([Regex]::Escape($path));
	
	$projectUserFile = "$project.user";
	If (Test-Path $projectUserFile) {
		[xml]$xml = Get-Content "$projectUserFile";
		$propertyGroupNode = $xml.Project.PropertyGroup | Where { $_.ReferencePath -match $regex };

		if($propertyGroupNode -eq $null) {
			return;
		}

		Write-Host "Removing reference path from project $project";
		$propertyGroupNode.ReferencePath = $propertyGroupNode.ReferencePath -replace "$regex\\?;?";
		$xml.Save($projectUserFile);
	}
}

function Set-SpecificVersion {
Param(
	[string]
	$project,
	
	[string]
	$name,
	
	[boolean]
	$specificVersion
);
    [xml]$myXML = Get-Content $project;

    # Set specific version to false
    $myXML.Project.ItemGroup.Reference | 
        where { $_.Include -match "^$($name)[,""]" } | 
        foreach { 
            write-host "Set SpecificVersion to $specificVersion for $name on $project"
            $SpecificVersionNode = $_.Item('SpecificVersion')
            if($SpecificVersionNode) {
                if($specificVersion) {
                    $trash = $_.RemoveChild($SpecificVersionNode);
                } else {
                    $_.SpecificVersion = "false"; 
                }
            } else {
                $newChild = $myXML.CreateElement("SpecificVersion", "http://schemas.microsoft.com/developer/msbuild/2003");
                $newChild.set_InnerXML("false");
                $removedNode = $_.AppendChild($newChild);
            }
            $myXML.Save($project);
        }
}
function Set-ReferencePath {
Param(
	[Parameter(mandatory=$true)]
	[string]
	$name,
	
	[Parameter(mandatory=$true)]
	$path
);
	
	$projects = Get-Project -all;

	Foreach ($project in $projects) {
		Write-Host "Saving $($project.FileName)";
		Set-SpecificVersion "$($project.FullName)" "$name" $false;
		Set-ProjectReferencePath "$($project.FullName)" "$path";
		$project.Save();
	}
}
function Remove-ReferencePath {
Param(
	[Parameter(mandatory=$true)]
	[string]
	$name,
	
	[Parameter(mandatory=$true)]
	[string]
	$path
);    
	
	$projects = Get-Project -all;

	Foreach ($project in $projects) {
		Write-Host "Saving $($project.FileName)";
		Set-SpecificVersion "$($project.FullName)" $name $true;
		Remove-ProjectReferencePath "$($project.FullName)" $path;
		$project.Save();
	}
}
function Remove-AllReferencePaths {
	$projects = Get-Project -all;

	Foreach ($project in $projects) {
		$references = $project.Object.References;
		
		Foreach ($reference in $references) {
			Set-SpecificVersion "$($project.FullName)" "$($referene.Name)" $true;
			Remove-ProjectReferencePath -project "$($project.FullName)" -regex "$($reference.Path)";
			$project.Save();
		}
	}
}
function Get-References {
Param(
	[Parameter(Mandatory=$false)]
	[string]
	$regex = '*',
	
	[Parameter(Mandatory=$false)]
	[Nullable[boolean]]
	$specificVersion = $null
);
	$projects = Get-Project -all;

	Foreach ($project in $projects) {
		$references = $project.Object.References;
		
		$references = $references | Where { $_.Name -like $regex -or $_.Version -like $regex };
		
		if ($specificVersion) {
			$references = $references | Where { $_.SpecificVersion -eq $specificVersion };
		}
		
		Foreach ($reference in $references) {
			Write-Host "$($project.Name)   $($reference.Name)   $($reference.Version)   $($reference.SpecificVersion)   $($reference.Path)";
		}
	}
}


function Enable-RemoteDebugging {
Param(
	[Parameter(Mandatory=$true)]
	[string]
	$host,
	
	[Parameter(Mandatory=$true)]
	[int]
	$port,
	
	[Parameter(Mandatory=$true)]
	[string]
	$path
);
	If ($DTE -eq $null) {
		throw "Please launch this script from NugetPackageManager console from Visual Studio"
	}

	$startupProjectName = $DTE.Solution.Properties['StartupProject'].Value;

	# Configure the startup project to debug remotly
	$project = get-project -Name $startupProjectName;
	$debugConfiguration = $project.Object.Project.ConfigurationManager | Where { $_.ConfigurationName -eq 'Debug' };
	$debugConfiguration.Properties['RemoteDebugEnabled'].Value = $true;
	$debugConfiguration.Properties['RemoteDebugMachine'].Value = "$($host):$($port)";

	# Add a postbuild event to copy output directory to the remote host
	$project.Properties['PostBuildEvent'].Value =  "Robocopy . $path /MIR 
set rce=%errorlevel% 
if not %rce%==1 exit %rce% else exit 0";
}
function Disable-RemoteDebugging {
	If ($DTE -eq $null) {
		throw "Please launch this script from NugetPackageManager console from Visual Studio"
	}
	$startupProjectName = $DTE.Solution.Properties['StartupProject'].Value;

	# Configure the startup project to debug remotly
	$project = get-project -Name $startupProjectName;
	$debugConfiguration = $project.Object.Project.ConfigurationManager | Where { $_.ConfigurationName -eq 'Debug' };
	$debugConfiguration.Properties['RemoteDebugEnabled'].Value = $false;
	$debugConfiguration.Properties['RemoteDebugMachine'].Value = "";

	$project.Properties['PostBuildEvent'].Value =  "";
}
function Register-PackageSources {
Param(
	[Parameter(Mandatory=$true)]
	[string[]]
	$names,
	
	[Parameter(Mandatory=$true)]
	[string[]]
	$locations,
	
	[Parameter(Mandatory=$false)]
	$provider = 'NuGet'
);
	
	$packageSourceLocations = (Get-PackageSource | Where-Object -Property ProviderName -eq -Value $provider).Location;
	
    #add nuget sources
    for ($counter = 0; $counter -lt $locations.Length; $counter++) {
		$exists = $packageSourceLocations -Contains $locations[$counter];
		If ($exists) {
			Write-Host "PackageSource $($names[$counter]) $($locations[$counter]) already exists";
		}
		Else {
			Register-PackageSource -Name $names[$counter] -Location $locations[$counter] -ProviderName $provider;
		}
	}
    Write-Host "NuGet Sources updated"
}
function Remove-BuildDirectories {
Param(
	$path = '.',
	
	[string[]]
	$includes = @('bin', 'pkg', 'obj', '_ReSharper.Caches'),
	
	[string[]]
	$excludes = @('packages')
);
    $directories = Get-ChildItem -Path $path -Directory -Include $includes -Exclude $excludes -Recurse;

	Foreach ($directory in $directories) {
		Remove-Item -Path $directory -Force -Recurse;
	}
}

Export-ModuleMember -function Remove-BuildDirectories;
Export-ModuleMember -Function Register-PackageSources

Export-ModuleMember -Function Get-References;
Export-ModuleMember -Function Set-ReferencePath;
Export-ModuleMember -Function Remove-ReferencePath;
Export-ModuleMember -Function Remove-AllReferencePaths;

Export-ModuleMember -Function Disable-RemoteDebugging;
Export-ModuleMember -Function Enable-RemoteDebugging;
