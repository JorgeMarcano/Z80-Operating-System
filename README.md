# Z80-Operating-System
A Basic Operating System for the Z80 CPU

To build the current OS files, run "compDump.ps1"
Make sure you have "rasm_win64.exe" in the same folder. You can get it in the [Official Repo](https://github.com/EdouardBERGE/rasm). Credits for the Assembler go to EdouardBERGE

The ps1 file will also automatically allow you to upload to an eeprom if you so choose.

Currently, the memory map of my Z80 computer is very simple:

```
0x0000  *-------*
        |       |
        |  ROM  |
        |       |
0x7FFF  *-------*
0x8000  *-------*
        |       |
        |  RAM  |
        |       |
0xFFFF  *-------*
```