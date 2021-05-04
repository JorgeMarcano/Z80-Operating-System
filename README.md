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

Currently, the I/O map of my Z80 computer is extremely simple:

| I/O Addr    | Peripheral |
|-------------|------------|
| 0bxxxxx100  | LCD Instr  |
| 0bxxxxx101  | LCD Data   |
|             |            |
| 0bxxxx1x00  | PIO A Data |
| 0bxxxx1x01  | PIO B Data |
| 0bxxxx1x10  | PIO A Ctrl |
| 0bxxxx1x11  | PIO B Ctrl |