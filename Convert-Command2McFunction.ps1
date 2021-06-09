# input .command.txt file
$filePath = (Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.command.txt" | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
#$filePath = Join-Path $PSScriptRoot "<fileName>.txt"

$commandText = @()
$commandText += Get-Content -LiteralPath $filePath -Encoding UTF8

# input ps1.config.txt
$workPosXYZ = ((Get-Content -LiteralPath ($PSCommandPath + ".config.txt")) -split "`r`n")[0] -split " "

# get symbol ~(tilde) or ^(caret)
$symbolX = $workPosXYZ[0] -replace "[0-9]*","" -replace "\-",""
$symbolY = $workPosXYZ[1] -replace "[0-9]*","" -replace "\-",""
$symbolZ = $workPosXYZ[2] -replace "[0-9]*","" -replace "\-",""

$posBaseX = [int]($workPosXYZ[0] -replace "\~","" -replace "\^","")
$posBaseY = [int]($workPosXYZ[1] -replace "\~","" -replace "\^","")
$posBaseZ = [int]($workPosXYZ[2] -replace "\~","" -replace "\^","")

$resultText = ""

for($i = 0; $i -lt $commandText.Count; $i++)
{
    $workCommand = $commandText[$i] -split " "
    
    Switch($workCommand[0])
    {
        {$_ -eq "/setblock"}
        {
            $workCommand[1] = $symbolX + [string]([int]$workCommand[1] + $posBaseX)
            $workCommand[2] = $symbolY + [string]([int]$workCommand[2] + $posBaseY)
            $workCommand[3] = $symbolZ + [string]([int]$workCommand[3] + $posBaseZ)
        }
        {$_ -eq "/summon"}
        {
            $workCommand[2] = $symbolX + [string]([double]$workCommand[2] + [double]$posBaseX)
            $workCommand[3] = $symbolY + [string]([double]$workCommand[3] + [double]$posBaseY)
            $workCommand[4] = $symbolZ + [string]([double]$workCommand[4] + [double]$posBaseZ)
        }
    }

    $workCommand[0] = $workCommand[0] -replace "/",""
    $resultText += ($workCommand -join " ") + "`r`n"
}

$resultText = $resultText -replace "`r`n$",""

# output .mcfunction file
$posBaseXYZ  = "pos."
$posBaseXYZ += ($symbolX -replace "\~","t" -replace "\^","c") + $posBaseX + "."
$posBaseXYZ += ($symbolY -replace "\~","t" -replace "\^","c") + $posBaseY + "."
$posBaseXYZ += ($symbolZ -replace "\~","t" -replace "\^","c") + $posBaseZ
$filePath    = $filePath.Substring(0, $filePath.Length - 12) + "." + $posBaseXYZ + ".mcfunction"
Set-Content -Value $resultText -LiteralPath $filePath -Encoding UTF8

# utf8 no bom
$utf8 = New-Object System.Text.UTF8Encoding $false
Set-Content -Value $utf8.GetBytes((Get-Content -LiteralPath $filePath -Raw)) -LiteralPath $filePath -Encoding Byte
