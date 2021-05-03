.\rasm_win64.exe .\OS\main.asm

Write-Host "`r`n`r`n"

format-hex rasmoutput.bin

$confirmation = Read-Host "`r`nContinue (y)"

if ($confirmation -eq 'y') {

    python.exe uploadProgram.py
}

pause