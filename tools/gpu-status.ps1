# SYNOPSIS: Show GPU VRAM, load, temperature and processes; verdict whether heavy GPU work is safe
# USAGE: bt gpu-status [-MinFreeMB 2500]
param([int]$MinFreeMB = 2500)
if (-not (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) { Write-Output 'nvidia-smi not found'; exit 2 }
$line = (& nvidia-smi --query-gpu=name,memory.total,memory.used,memory.free,utilization.gpu,temperature.gpu --format=csv,noheader,nounits 2>&1 | Select-Object -First 1)
$p = "$line" -split ',\s*'
if ($p.Count -lt 6) { Write-Output "Unexpected output: $line"; exit 2 }
Write-Output ("GPU: {0} | total {1} MB | used {2} MB | free {3} MB | util {4}% | {5} C" -f $p[0], $p[1], $p[2], $p[3], $p[4], $p[5])
Write-Output '-- compute processes --'
& nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader 2>&1
$free = [int]$p[3]
if ($free -lt $MinFreeMB) {
  Write-Output "VERDICT: LOW VRAM ($free MB free < $MinFreeMB). Do not start GPU-heavy work. Do not unload the model server unless the user asks."
  exit 1
}
Write-Output "VERDICT: OK ($free MB free)"
