# input .command.txt file
$filePath = (Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.command.txt" | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
#$filePath = Join-Path $PSScriptRoot "<fileName>.txt"

$minecraftCommandAllText = Get-Content -LiteralPath $filePath

# get minX, minZ, maxX, maxZ
$minX =  999999
$minZ =  999999
$maxX = -999999
$maxZ = -999999

for($i = 0; $i -lt $minecraftCommandAllText.Count; $i++)
{
    $workCommand = $minecraftCommandAllText[$i] -split " "
    
    $workX = $null
    $workZ = $null
    
    switch ($workCommand[0])
    {
        "/setblock"
        {
            $workX = [int]$workCommand[1]
            $workZ = [int]$workCommand[3]
        }
        "/summon"
        {
            $workX = [int]$workCommand[2]
            $workZ = [int]$workCommand[4]
        }
    }

    if($workX -ne $null -and $workZ -ne $null)
    {        
        if($workX -lt $minX){$minX = $workX}
        if($workZ -lt $minZ){$minZ = $workZ}
        if($workX -gt $maxX){$maxX = $workX}
        if($workZ -gt $maxZ){$maxZ = $workZ}
    }
}

# rotate 90 degrees to the right
for($i = 0; $i -lt $minecraftCommandAllText.Count; $i++)
{
    $workCommand = $minecraftCommandAllText[$i] -split " "
    $minecraftCommandAllText[$i] = ""

    switch ($workCommand[0])
    {
        "/setblock"
        {
            $workX = [int]$workCommand[1]
            $workZ = [int]$workCommand[3]
            
            $workCommand[1] = [string]($minX + ($maxZ - $minZ) + ($minZ - $workZ))
            $workCommand[3] = [string]($minZ + ($maxX - $minX) - ($maxX - $workX))
        }
        "/summon"
        {
            $workX = [int]$workCommand[2]
            $workZ = [int]$workCommand[4]
            
            $workCommand[2] = [string]($minX + ($maxZ - $minZ) + ($minZ - $workZ))
            $workCommand[4] = [string]($minZ + ($maxX - $minX) - ($maxX - $workX))
        }
    }

    for($j = 0; $j -lt $workCommand.Count; $j++)
    {
        $minecraftCommandAllText[$i] += $workCommand[$j] + " "
    }
    $minecraftCommandAllText[$i] = $minecraftCommandAllText[$i].Trim()

    if($minecraftCommandAllText[$i] -match "(?<facing>facing=.*?(\]|,))")
    {
        $replaceTarget = $false
        $workTarget = $Matches.facing
        switch(($workTarget -split ",|=|]")[1])
        {
            "north" {$workTargetRep = $workTarget -replace "north","east" ; $replaceTarget = $true}
            "east"  {$workTargetRep = $workTarget -replace "east" ,"south"; $replaceTarget = $true}
            "south" {$workTargetRep = $workTarget -replace "south","west" ; $replaceTarget = $true}
            "west"  {$workTargetRep = $workTarget -replace "west" ,"north"; $replaceTarget = $true}
        }
        if($replaceTarget){$minecraftCommandAllText[$i] = $minecraftCommandAllText[$i] -replace $workTarget,$workTargetRep}
    }

    $replaceTargetN = $false
    $replaceTargetE = $false
    $replaceTargetS = $false
    $replaceTargetW = $false

    if($minecraftCommandAllText[$i] -match "(?<north>north=.*?(\]|,))"){$workTargetN = $Matches.north; $workNValue = ($Matches.north -split ",|=|]")[1]; $replaceTargetN = $true}
    if($minecraftCommandAllText[$i] -match "(?<east>east=.*?(\]|,))")  {$workTargetE = $Matches.east ; $workEValue = ($Matches.east  -split ",|=|]")[1]; $replaceTargetE = $true}
    if($minecraftCommandAllText[$i] -match "(?<south>south=.*?(\]|,))"){$workTargetS = $Matches.south; $workSValue = ($Matches.south -split ",|=|]")[1]; $replaceTargetS = $true}
    if($minecraftCommandAllText[$i] -match "(?<west>west=.*?(\]|,))")  {$workTargetW = $Matches.west ; $workWValue = ($Matches.west  -split ",|=|]")[1]; $replaceTargetW = $true}

    if($replaceTargetN){$workTargetNRep = $workTargetN -replace $workNValue,$workEValue; $minecraftCommandAllText[$i] = $minecraftCommandAllText[$i] -replace $workTargetN,$workTargetNRep}
    if($replaceTargetE){$workTargetERep = $workTargetE -replace $workEValue,$workSValue; $minecraftCommandAllText[$i] = $minecraftCommandAllText[$i] -replace $workTargetE,$workTargetERep}
    if($replaceTargetS){$workTargetSRep = $workTargetS -replace $workSValue,$workWValue; $minecraftCommandAllText[$i] = $minecraftCommandAllText[$i] -replace $workTargetS,$workTargetSRep}
    if($replaceTargetW){$workTargetWRep = $workTargetW -replace $workWValue,$workNValue; $minecraftCommandAllText[$i] = $minecraftCommandAllText[$i] -replace $workTargetW,$workTargetWRep}
}

<# modify output file name
# ex. "objectname.fn.30.5.20.command.txt" --> "objectname.fe.20.5.30.command.txt"

# change output file name facing (fn --> fe, fe --> fs, fs --> fw, fw --> fn)
if    ($filePath -match "\.fn\."){$filePath = $filePath -replace "\.fn\.",".fe."}
elseif($filePath -match "\.fe\."){$filePath = $filePath -replace "\.fe\.",".fs."}
elseif($filePath -match "\.fs\."){$filePath = $filePath -replace ".\fs\.",".fw."}
elseif($filePath -match "\.fw\."){$filePath = $filePath -replace ".\fw\.",".fn."}

# change output file name xz (z --> x, x --> z)
$workFilePath = $filePath -split "\."
$workFilePathX = $workFilePath[2]
$workFilePathZ = $workFilePath[4]
$workFilePath[2] = $workFilePathZ
$workFilePath[4] = $workFilePathX
$filePath = $workFilePath -join "."
#>

# output .command.txt file
Set-Content -LiteralPath $filePath -Value $minecraftCommandAllText