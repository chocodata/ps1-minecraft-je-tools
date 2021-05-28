# ps1-minecraft-tools
## Table of content
- [Convert-NBT2JSON.ps1](#convert-nbt2jsonps1)         .nbt  --> .json
- [Convert-JSON2Command.ps1](#convert-json2commandps1) .json --> .command.txt

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
├── <nbt file name>.nbt   // input file
└── Convert-NBT2JSON.ps1
```
If there are multiple nbt files, the latest file will be processed.

After executing .ps1, "\<nbt file name\>.json" will be output to the same directory.

## Convert-JSON2Command.ps1
Convert Minecraft json file to command txet file.
