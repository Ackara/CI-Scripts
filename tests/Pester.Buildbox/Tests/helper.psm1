﻿function New-TestEnviroment()
{
	$rootDir = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent);
	$testResultDir = "$rootDir\TestResults\pester-$((Get-Date).Ticks)";
	$downloadDir = "$rootDir\TestResults\downloads";
	$module = Get-Item "$rootDir\src\Buildbox\Buildbox.psd1";

	foreach ($dir in @($testResultDir, $downloadDir))
	{
		if (-not (Test-Path $dir -PathType Container))
		{
			New-Item $dir -ItemType Directory | Out-Null;
		}
	}

	return New-Object PSObject -Property @{
		"testResultsDir"=$testResultDir;
		"downloadDir"=$downloadDir;
		"projectDir"=$rootDir;
		"module"=$module;
	};
}

function Approve-File([string]$ReceivedFile, [string]$TestName)
{
	$approvalsDir = "$PSScriptRoot\ApprovalTests";
	if (-not (Test-Path $approvalsDir -PathType Container)) { New-Item $approvalsDir -ItemType Directory | Out-Null; }

	$extension = [IO.Path]::GetExtension($ReceivedFile);
	$approvalFile = "$approvalsDir\$TestName.approved$extension";
	if (-not (Test-Path $approvalFile -PathType Leaf)) { New-Item $approvalFile -ItemType File | Out-Null; }

	try
	{
		$diff = Compare-Object $(Get-Content $ReceivedFile) $(Get-Content $approvalFile);
		if ($diff) { throw "files don't match"; } else { return $true; }
	}
	catch
	{
		Write-Host "COPY /Y `"$ReceivedFile`" `"$approvalFile`"";
		Invoke-Item $ReceivedFile;
		return $false;
	}
}