# SYNOPSIS: Export reverse engineering findings to color-coded IDAPython script for IDA Pro
# USAGE: bt re-ida-export -InputJson <file.json> [-Output <patch.py>]
<#
.SYNOPSIS
    re-ida-export - Exports annotations, triage results, and colored routines to an IDAPython script.
.DESCRIPTION
    Converts structured REA analysis findings into a production-ready IDAPython (.py) script
    compatible with IDA Pro 7.x/8.x/9.x.
.PARAMETER InputJson
    Path to the JSON file containing function annotations.
.PARAMETER Output
    Path to save the generated .py script (default: C:\REA-Context\ida_patch.py).
#>
param(
    [Parameter(Mandatory=$false)]
    [string]$InputJson,

    [Parameter(Mandatory=$false)]
    [string]$Output = "C:\REA-Context\ida_patch.py"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$pyScript = Join-Path $scriptDir "re_ida_export.py"

if (-not (Test-Path $pyScript)) {
    $pyScript = "C:\tools\re_ida_export.py"
}

if (-not (Test-Path $pyScript)) {
    Write-Error "re_ida_export.py not found!"
    exit 1
}

$pyCode = @"
import sys
import json
from pathlib import Path
from re_ida_export import generate_idapython_script

input_path = r'$InputJson'
output_path = r'$Output'

if input_path and Path(input_path).exists():
    data = json.loads(Path(input_path).read_text(encoding='utf-8'))
else:
    # Read from stdin
    data = json.loads(sys.stdin.read())

script_content = generate_idapython_script(data)
out = Path(output_path)
out.parent.mkdir(parents=True, exist_ok=True)
out.write_text(script_content, encoding='utf-8')
print(f'[+] IDAPython script generated successfully: {out}')
"@

$python = "python"
if (-not $InputJson) {
    $input | & $python -c $pyCode
} else {
    & $python -c $pyCode
}
