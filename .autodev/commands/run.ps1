$ErrorActionPreference = "Stop"
. "$PSScriptRoot/driver_helper.ps1"

Invoke-RuntimeContract -ContractName "run"
