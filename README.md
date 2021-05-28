# ps1-minecraft-je-tools
## Table of content
- [Convert-NBT2JSON.ps1](#convert-nbt2jsonps1)         .nbt  --> .json
- [Convert-JSON2Command.ps1](#convert-json2commandps1) .json --> .command.txt
- [Convert-Command2McFunction.ps1](#convert-command2mcfunctionps1) .command.txt --> .mcfunction

## Convert-NBT2JSON.ps1
Convert Minecraft nbt file to json file.

### Minecraft nbt file location
The nbt file must be created using the Structure Block in game.
```
C:\Users\<UserName>\AppData\Roaming\.minecraft\saves\<WorldName>\generated\minecraft\structures
```

### Directory Structure
Place the nbt file in the same directory as the ps1 file.
```
├── <nbt file name>.nbt
└── Convert-NBT2JSON.ps1
```
If there are multiple nbt files, the latest file will be processed.

After executing PowerShell Script, "\<nbt file name\>.json" will be output to the same directory.

## Convert-JSON2Command.ps1
Convert Minecraft json file to command txet file.

### Directory Structure
Place the json file in the same directory as the ps1 file. Create commands such as ”/setblock” and ”/summon”.
```
├── <json file name>.json
└── Convert-JSON2Command.ps1
```
If there are multiple json files, the latest file will be processed.

After executing PowerShell Script, "\<json file name\>.command.txt" will be output to the same directory.

## Convert-Command2McFunction.ps1
Place the command txt file in the same directory as the ps1 file.
```
├── <command txt file name>.command.txt
├── Convert-Command2McFunction.ps1
└── Convert-Command2McFunction.ps1.Config.txt   // base pos x y z info
```
If there are multiple command txt files, the latest file will be processed.

After executing PowerShell Script, "\<command txt file name\>.pos.<base pos x>.<base pos y>.<base pos z>.mcfunction" will be output to the same directory.
