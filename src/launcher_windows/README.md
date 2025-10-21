# Windows Launcher

Minimal C launcher that executes a corresponding script file with the same name as the executable.

## Build

```cmd
gcc launcher.c -o bitbot.exe
```

Or with MinGW:
```cmd
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe
```

## Usage

1. Compile `launcher.c` to create `bitbot.exe`
2. Create a script with the same name: `bitbot.cmd`, `bitbot.bat`, or `bitbot.ps1`
3. Run: `bitbot.exe [arguments...]`

The launcher will:
- Search for scripts in this order: `.cmd` → `.bat` → `.ps1`
- Execute the first one found
- Pass all command-line arguments through
- Return the script's exit code

## Priority Order

1. **`.cmd`** - Preferred (modern Windows standard)
2. **`.bat`** - Fallback (maximum compatibility)
3. **`.ps1`** - PowerShell (most powerful, but may have execution policy issues)

## Example

```
bitbot.exe init
  → Looks for bitbot.cmd
  → Runs: cmd.exe /c "bitbot.cmd" init
```
