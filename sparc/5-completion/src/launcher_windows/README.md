# Windows Launcher

Minimal C launcher that executes a corresponding `.cmd` script file with the same name as the executable.

## Build

```bash
./build.sh
```

This compiles `launcher.c` to `launcher.exe` and copies it to the project root as `bitbot.exe`.

Or manually with MinGW:

```bash
x86_64-w64-mingw32-gcc launcher.c -o launcher.exe -Os -s -ffunction-sections -fdata-sections -Wl,--gc-sections
```

## How It Works

The launcher will:

- Find the `.cmd` file with the same name as the .exe (without extension)
- Execute it using `cmd.exe /c "script.cmd" [args...]`
- Pass all command-line arguments through
- Return the script's exit code
- Silent operation (no error messages to stderr)

## Deployment

When deployed to project root, `launcher.exe` is renamed to `bitbot.exe` and expects `bitbot.cmd` in the same directory.

## Example

```
launcher.exe init
  → Looks for launcher.cmd
  → Runs: cmd.exe /c "launcher.cmd" init
```

## Testing

Run automated tests:

```bash
./test.sh
```

This runs 3 tests:
- **Test 1:** No arguments
- **Test 2:** Multiple arguments (test arg1 arg2 --flag)
- **Test 3:** Exit code propagation

## Size Optimization

The binary is optimized for size:

- **Current size:** 38 KB (91% reduction from 465 KB unoptimized)
- Uses: `-Os -s -ffunction-sections -fdata-sections -Wl,--gc-sections`