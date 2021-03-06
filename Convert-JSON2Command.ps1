# input .json file
$filePath = (Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.json" | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
#$filePath = Join-Path $PSScriptRoot "<fileName>.json"

$nbtJson = Get-Content -LiteralPath $filePath -Encoding UTF8 | ConvertFrom-Json

$resultText = ""

foreach($workBlock in $nbtJson.blocks)
{
    $resultText += "/setblock "
    $resultText += [string]$workBlock.pos[0] + " "
    $resultText += [string]$workBlock.pos[1] + " "
    $resultText += [string]$workBlock.pos[2] + " "

    $resultText += $nbtJson.palette[$workBlock.state].Name

    if($nbtJson.palette[$workBlock.state].Properties -ne $null)
    {
        $propertiesWork = $nbtJson.palette[$workBlock.state].Properties  | ConvertTo-Json -Compress -Depth 64
        $propertiesWork = $propertiesWork -replace "^{","[" -replace "}$","]" -replace ":","=" -replace """",""
        
        $resultText += $propertiesWork
    }

    if($workBlock.nbt -ne $null)
    {
        $nbtWork = $workBlock.nbt | ConvertTo-Json -Compress -Depth 64
        if($nbtWork -notmatch "Text")
        {
            $nbtWork = $nbtWork -replace """minecraft:(.*?)""","#00#minecraft:`$1#00#"
            $nbtWork = $nbtWork -replace """",""
            $nbtWork = $nbtWork -replace "#00#",""""
        }

        $resultText += $nbtWork
    }

    $resultText += "`r`n"
}

foreach($workEntity in $nbtJson.entities)
{
    if($workEntity.nbt.id -ne $null)
    {
        $resultText += "/summon "
        $resultText += $workEntity.nbt.id + " "

        # int value
        $resultText += [string]$workEntity.blockPos[0] + " "
        $resultText += [string]$workEntity.blockPos[1] + " "
        $resultText += [string]$workEntity.blockPos[2] + " "
        
        # update nbt.Pos
        #$workEntity.nbt.Pos = $workEntity.blockPos | ForEach-Object {[string]$_ + "d"}

        # delete nbt.Pos
        $workEntity.nbt.psobject.properties.remove("Pos")

        <# double value
        $resultText += ($workEntity.pos[0] -replace "d","") + " "
        $resultText += ($workEntity.pos[1] -replace "d","") + " "
        $resultText += ($workEntity.pos[2] -replace "d","") + " "

        # update nbt.Pos
        $workEntity.nbt.Pos = $workEntity.pos
        #>


        $resultText += $workEntity.nbt | ConvertTo-Json -Compress -Depth 64

        $resultText += "`r`n"
    }
}

$resultText = $resultText -replace "`r`n$",""

# delete /setblock x y z minecraft:air
$resultText = $resultText -split "`r`n" | ?{$_ -notmatch "minecraft:air"}

# output .command.txt file
$filePath = $filePath.Substring(0, $filePath.Length - 5) + ".command.txt"
Set-Content -Value $resultText -LiteralPath $filePath -Encoding UTF8

# utf8 no bom
$utf8 = New-Object System.Text.UTF8Encoding $false
Set-Content -Value $utf8.GetBytes((Get-Content -LiteralPath $filePath -Raw)) -LiteralPath $filePath -Encoding Byte
