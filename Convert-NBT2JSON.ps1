# input .nbt file
$filePath = (Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.nbt" | Sort-Object -Property LastWriteTime | Select-Object -Last 1).FullName
#$filePath = Join-Path $PSScriptRoot "<fileName>.nbt"

# decompress gzip
$inStream     = New-Object System.IO.FileStream($filePath, [System.IO.FileMode]::Open)
$inStreamGZip = New-Object System.IO.Compression.GZipStream($inStream, [System.IO.Compression.CompressionMode]::Decompress)
$inMStream    = New-Object System.IO.MemoryStream
$inStreamGZip.CopyTo($inMStream)

$Script:nbtData = $inMStream.ToArray()

$inStream.Close()
$inStreamGZip.Close()
$inMStream.Close()

$Script:resultText = ""

# jump tag function
function Select-NbtTag($Script:nbtData, $i, $listType, $Script:resultText)
{
    if($listType -eq $null)
    {
        $tagType = $Script:nbtData[$i]
    }
    else
    {
        $tagType = $listType
    }

    switch($tagType)
    {
         {$_ -eq  0}                {$i = Get-DataTagEnd      $Script:nbtData $i $listType $Script:resultText} # TAG_End
         {$_ -eq  8}                {$i = Get-DataTagString   $Script:nbtData $i $listType $Script:resultText} # TAG_String
         {$_ -eq  9}                {$i = Get-DataTagList     $Script:nbtData $i $listType $Script:resultText} # TAG_List
         {$_ -eq 10}                {$i = Get-DataTagCompound $Script:nbtData $i $listType $Script:resultText} # TAG_Compound
         {$_ -in (1, 2, 3, 4, 5, 6)}{$i = Get-DataTagBSILFD   $Script:nbtData $i $listType $Script:resultText} # TAG_Byte, TAG_Short, TAG_Int, TAG_Long, TAG_Float, TAG_Double
         {$_ -in (7, 11,12)}        {$i = Get-DataTagBILArray $Script:nbtData $i $listType $Script:resultText} # TAG_Byte_Array, TAG_Int_Array, TAG_Long_Array
    }

    return $i
}

# TAG_End
# [Header]tagType 0
# [Data] none
function Get-DataTagEnd($Script:nbtData, $i, $listType, $Script:resultText)
{
    $Script:resultText += "}"

    $i++
    
    return $i
}

# TAG_String
# [Header]tagType             0
# [Header]tagNameByteCount 1..2
# [Header]tagName          3..(3+TagNameByteCount-1)
# [Data]stringByteCount    0..1
# [Data]string             2..(2+StringByteCount-1)
function Get-DataTagString($Script:nbtData, $i, $listType, $Script:resultText)
{
    # [Header]
    if($listType -eq $null)
    {
        #[Header]tagNameByteCount
        $tagNameByteCount = [int][System.BitConverter]::ToInt16(@($Script:nbtData[$i+2],$Script:nbtData[$i+1]), 0)

        if($tagNameByteCount -ne 0)
        {
            # [Header]tagName
            $Script:resultText += """" + [System.Text.Encoding]::UTF8.GetString($Script:nbtData[($i+3)..($i+3+$tagNameByteCount-1)]) + """:"
        }
        else
        {
            # [Header]tagName(none)
            $Script:resultText += """none"":"
        }

        $i = $i + 3 + $tagNameByteCount
    }

    # [Data]
    # [Data]stringByteCount
    $stringByteCount = [int][System.BitConverter]::ToInt16(@($Script:nbtData[$i+1],$Script:nbtData[$i]),0)
    
    if($stringByteCount -ne 0)
    {
        # [Data]string
        $Script:resultText += """" + [System.Text.Encoding]::UTF8.GetString($Script:nbtData[($i+2)..($i+2+$stringByteCount-1)]) + """"
    }
    else
    {
        # [Data]string(none)
        $Script:resultText += """"""
    }

    $i = $i + 2 + $stringByteCount
        
    return $i
}

# TAG_List
# [Header]tagType             0
# [Header]tagNameByteCount 1..2
# [Header]tagName          3..(3+TagNameByteCount-1)
# [Data]listItemTagType       0
# [Data]listItemCount      1..4
# [Data]listItems          5..n n=ListItemCount*X (X is ListItemTagType) --> Select-NbtTag
function Get-DataTagList($Script:nbtData, $i, $listType, $Script:resultText)
{
    # [Header]
    if($listType -eq $null)
    {
        # [Header]tagNameByteCount
        $tagNameByteCount = [int][System.BitConverter]::ToInt16(@($Script:nbtData[$i+2],$Script:nbtData[$i+1]), 0)

        if($tagNameByteCount -ne 0)
        {
            # [Header]tagName
            $Script:resultText += """" + [System.Text.Encoding]::UTF8.GetString($Script:nbtData[($i+3)..($i+3+$tagNameByteCount-1)]) + """:["
        }
        else
        {
            # [Header]tagName(none)
            $Script:resultText += "["
        }

        $i = $i + 3 + $tagNameByteCount
    }
    else
    {
        # if list skip header
        $Script:resultText += "["
    }
    
    # [Data]
    # [Data]listItemTagType
    $listItemTagType = [int]$Script:nbtData[$i]
    
    # [Data]listItemCount
    $listItemCount = [System.BitConverter]::ToInt32(@($Script:nbtData[$i+4],$Script:nbtData[$i+3],$Script:nbtData[$i+2],$Script:nbtData[$i+1]), 0)
    
    $i = $i + 5
    for($j = 0; $j -lt $listItemCount; $j++)
    {
        $i = Select-NbtTag $Script:nbtData $i $listItemTagType $Script:resultText
        $Script:resultText += ","
    }
    $Script:resultText = $Script:resultText -replace ",$",""
    $Script:resultText += "]"
        
    return $i
}

# TAG_Compound
# [Header]tagType             0
# [Header]tagNameByteCount 1..2
# [Header]tagName          3..(3+TagNameByteCount-1)
# [Data] none              0..n n= next NBTTag --> Select-NbtTag, until TAG_END --> Get-DataTagEnd
function Get-DataTagCompound($Script:nbtData, $i, $listType, $Script:resultText)
{
    # [Header]
    if($listType -eq $null)
    {
        # [Header]tagNameByteCount
        $tagNameByteCount = [int][System.BitConverter]::ToInt16(@($Script:nbtData[$i+2],$Script:nbtData[$i+1]), 0)

        if($tagNameByteCount -ne 0)
        {
            # [Header]tagName
            $Script:resultText += """" + [System.Text.Encoding]::UTF8.GetString($Script:nbtData[($i+3)..($i+3+$tagNameByteCount-1)]) + """:{"
        }
        else
        {
            # [Header]tagName(none)
            $Script:resultText += "{"
        }

        $i = $i + 3 + $tagNameByteCount
    }
    else
    {
        # if list skip header
        $Script:resultText += "{"
    }

    # next NBTTags
    while($Script:nbtData[$i] -ne 0)
    {
        $i = Select-NbtTag $Script:nbtData $i $null $Script:resultText
        $Script:resultText += ","
    }
    $Script:resultText = $Script:resultText -replace ",$",""
    $i = Get-DataTagEnd $Script:nbtData $i $null $Script:resultText

    return $i
}

# TAG_Byte, TAG_Short, TAG_Int, TAG_Long, TAG_Float, TAG_Double
# [Header]tagType             0
# [Header]tagNameByteCount 1..2
# [Header]tagName          3..(3+TagNameByteCount-1)
# [Data] Byte 0(1) | Short 0..1(2) | Int 0..3(4) | Long 0..7(8) | Float 0..3(4) | Double 0..7(8)
function Get-DataTagBSILFD($Script:nbtData, $i, $listType, $Script:resultText)
{
    # [Header]
    if($listType -eq $null)
    {
        # [Header]tagType
        $tagType = $Script:nbtData[$i]

        # [Header]tagNameByteCount
        $tagNameByteCount = [int][System.BitConverter]::ToInt16(@($Script:nbtData[$i+2],$Script:nbtData[$i+1]), 0)

        if($tagNameByteCount -ne 0)
        {
            # [Header]tagName
            $Script:resultText += """" + [System.Text.Encoding]::UTF8.GetString($Script:nbtData[($i+3)..($i+3+$tagNameByteCount-1)]) + """:"
        }
        else
        {
            # [Header]tagName(none)
            $Script:resultText += """none"":"
        }

        $i = $i + 3 + $tagNameByteCount
    }
    else
    {
        # if list skip header
        $tagType = $listType
    }

    # [Data] Byte 0(1) | Short 0..1(2) | Int 0..3(4) | Long 0..7(8) | Float 0..3(4) | Double 0..7(8)
    if    ($tagType -eq 1){$dataByteCount = 1; $Script:resultText += """" +                                 $Script:nbtData[$i]                            + "b"""}
    elseif($tagType -eq 2){$dataByteCount = 2; $Script:resultText += """" + [System.BitConverter]::ToInt16( $Script:nbtData[($i+$dataByteCount-1)..$i], 0) + "s"""}
    elseif($tagType -eq 3){$dataByteCount = 4; $Script:resultText += ""   + [System.BitConverter]::ToInt32( $Script:nbtData[($i+$dataByteCount-1)..$i], 0)        }
    elseif($tagType -eq 4){$dataByteCount = 8; $Script:resultText += """" + [System.BitConverter]::ToInt64( $Script:nbtData[($i+$dataByteCount-1)..$i], 0) + "l"""}
    elseif($tagType -eq 5){$dataByteCount = 4; $Script:resultText += """" + [System.BitConverter]::ToSingle($Script:nbtData[($i+$dataByteCount-1)..$i], 0) + "f"""}
    elseif($tagType -eq 6){$dataByteCount = 8; $Script:resultText += """" + [System.BitConverter]::ToDouble($Script:nbtData[($i+$dataByteCount-1)..$i], 0) + "d"""}
    
    $i = $i + $dataByteCount
            
    return $i
}

# TAG_Byte_Array, TAG_Int_Array, TAG_Long_Array
# [Header]tagType             0
# [Header]tagNameByteCount 1..2
# [Header]tagName          3..(3+TagNameByteCount-1)
# [Data]itemCount          0..3
# [Data]items              4..n n= ItemCount*( Byte 0(1) | Int 0..3(4) | Long 0..7(8) ) --> Get-DataTagBSILFD
function Get-DataTagBILArray($Script:nbtData, $i, $listType,$Script:resultText)
{
    # [Header]
    if($listType -eq $null)
    {
        # [Header]tagType
        $tagType = $Script:nbtData[$i]

        # [Header]tagNameByteCount
        $tagNameByteCount = [int][System.BitConverter]::ToInt16(@($Script:nbtData[$i+2],$Script:nbtData[$i+1]), 0)

        if($tagNameByteCount -ne 0)
        {
            # [Header]tagName
            $Script:resultText += """" + [System.Text.Encoding]::UTF8.GetString($Script:nbtData[($i+3)..($i+3+$tagNameByteCount-1)]) + """:["
        }
        else
        {
            # [Header]tagName(none)
            $Script:resultText += "["
        }

        $i = $i + 3 + $tagNameByteCount
    }
    else
    {
        # if list skip header
        $tagType = $listType
        $Script:resultText += "["
    }

    # [Data]
    # [Data]itemCount
    $itemCount = [System.BitConverter]::ToInt32(@($Script:nbtData[$i+3],$Script:nbtData[$i+2],$Script:nbtData[$i+1],$Script:nbtData[$i]), 0)
    
    # [Data]items
    $i = $i + 4

    if    ($tagType -eq  7){$tagType = 1}
    elseif($tagType -eq 11){$tagType = 3}
    elseif($tagType -eq 12){$tagType = 4}
    
    for($j = 0; $j -lt $itemCount; $j++)
    {   
        $i = Get-DataTagBSILFD $Script:nbtData $i $tagType $Script:resultText
        $Script:resultText += ","
    }
    $Script:resultText = $Script:resultText -replace ",$",""
    $Script:resultText += "]"

    return $i
}

# start
Select-NbtTag $Script:nbtData 0 $null $Script:resultText | Out-Null

# output .json file
$Script:resultText = $Script:resultText | ConvertFrom-Json | ConvertTo-Json -Depth 64
$filePath = $filePath.Substring(0, $filePath.Length - 4) + ".json"
Set-Content -Value $Script:resultText -LiteralPath $filePath
