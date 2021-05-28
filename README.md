# ps1-minecraft-tools
## Table of content
- [Convert-NBT2JSON.ps1](#Convert-NBT2JSON.ps1) .nbt --> .json

## Convert-NBT2JSON.ps1
Convert Minecraft nbt file to json file.

### Minecraft nbt file location (The nbt file must be created using the Structure Block in game.):
```
C:\Users\<UserName>\AppData\Roaming\.minecraft\saves\<WorldName>\generated\minecraft\structures
```

### Directory Structure
Place the nbt file in the same directory as the ps1 file.
```
├── <file name>.nbt
└── Convert-NBT2JSON.ps1
```
If there are multiple nbt files, the latest file will be processed.
