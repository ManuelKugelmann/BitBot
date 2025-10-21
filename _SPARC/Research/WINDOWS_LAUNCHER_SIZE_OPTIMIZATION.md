# Windows Launcher Binary Size Optimization Research

**Current Status:** 465K binary (launcher.c compiled with MinGW)
**Goal:** Minimize binary size for distribution
**Date:** 2025-10-21

---

## Summary

MinGW-compiled Windows executables tend to be large due to static linking of C/C++ runtime libraries. Current research shows multiple approaches to reduce binary size from 465K to potentially under 10K.

---

## Optimization Techniques

### 1. Compiler Optimization Flags

#### Basic Size Optimization
```bash
# Current build
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe

# Size-optimized build
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe \
  -Os \                              # Optimize for size
  -s \                               # Strip symbols
  -ffunction-sections \              # Place functions in separate sections
  -fdata-sections \                  # Place data in separate sections
  -Wl,--gc-sections                  # Garbage collect unused sections
```

**Expected reduction:** ~50-70% size reduction

#### Aggressive Size Optimization
```bash
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe \
  -Os \
  -s \
  -ffunction-sections \
  -fdata-sections \
  -Wl,--gc-sections \
  -Wl,--section-alignment,16,--file-alignment,16  # Minimal alignment
```

**Expected reduction:** Can produce <1KB binaries (may have compatibility issues)

### 2. Manual Stripping

Strip debug symbols and unused code after compilation:

```bash
# Compile
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe -Os

# Strip
x86_64-w64-mingw32-strip bitbot.exe
```

**Expected reduction:** "Hello World" from ~65KB → 9KB

### 3. Runtime Library Linking

#### Static vs Dynamic Linking

```bash
# Dynamic linking (smaller if DLLs already on system)
-shared-libstdc++ -shared-libgcc

# Static linking (larger but self-contained)
-static-libstdc++ -static-libgcc

# No default libraries (extreme - avoid for our case)
-nostdlib -nodefaultlibs
```

**Note:** Our launcher uses Windows API only, no C++ stdlib needed.

### 4. UPX Compression

**UPX (Ultimate Packer for eXecutables)** - Executable compression tool

```bash
# After building
upx --best bitbot.exe

# Or ultra brute force
upx --ultra-brute bitbot.exe
```

#### Pros ✓
- **50-70% file size reduction** (typical)
- Free and open source (GPL)
- Faster loading on slow storage (HDD)
- Self-extracting at runtime
- Good for CLI tools and distribution

#### Cons ✗
- **AV false positives** - Common with packers
- **Higher RAM usage** - ~2.7x more RSS (full decompression in memory)
- **Slower startup on fast storage** - Decompression overhead on SSD
- **Compatibility issues** - Some programs may not work correctly
- Not suitable if density/memory is critical

#### Recommendation
- **Good for:** Distribution packages, downloads, USB tools
- **Avoid for:** Server deployments, memory-constrained systems
- **Test:** Always test with Windows Defender and major AV vendors

---

## Alternative Compilers

### Tiny C Compiler (TCC)
- No optimization, but produces very small binaries
- Supports Win32 PE format
- Fast compilation
- Not recommended for production (no optimizations)

### Visual Studio / MSVC
```bash
# Size optimization flags
cl /O1 /Os /GS- /GR- /NODEFAULTLIB launcher.c
```

**Note:** Requires Visual Studio toolchain, less portable than MinGW

---

## Recommended Approach

### Phase 1: Compiler Flags (Safe)
```bash
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe \
  -Os \
  -s \
  -ffunction-sections \
  -fdata-sections \
  -Wl,--gc-sections
```

**Expected:** 465KB → ~50-150KB
**Risk:** Low
**Compatibility:** High

### Phase 2: Optional UPX (Distribution Only)
```bash
upx --best bitbot.exe
```

**Expected:** Additional 50-70% reduction (25-75KB)
**Risk:** Medium (AV false positives)
**Compatibility:** Medium (test required)

### Phase 3: Aggressive Flags (Testing Required)
```bash
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe \
  -Os -s \
  -ffunction-sections -fdata-sections \
  -Wl,--gc-sections \
  -Wl,--section-alignment,16,--file-alignment,16
```

**Expected:** <10KB possible
**Risk:** High (compatibility issues)
**Compatibility:** Requires testing on Win7/8/10/11

---

## Testing Matrix

After optimization, test on:

| Platform     | Version           | Priority |
|--------------|-------------------|----------|
| Windows 11   | 23H2              | High     |
| Windows 10   | 22H2              | High     |
| Windows 10   | LTSC 2019         | Medium   |
| Windows 8.1  | Update 3          | Low      |
| Windows 7    | SP1               | Low      |

Test scenarios:
- ✓ Launch with no arguments
- ✓ Launch with arguments (including special chars)
- ✓ Exit code propagation
- ✓ Working directory preservation
- ✓ Long path support (260+ chars)
- ✓ Unicode arguments

---

## Size Comparison Results

```
Before:       465 KB  (unoptimized MinGW)
After:         38 KB  (Phase 1: optimized flags)
Reduction:    427 KB  (91% reduction)

Status:       ✓ ACHIEVED - Exceeded expectations
Target 1:     100 KB  ✓ BEAT by 62 KB
Target 2:      50 KB  ✓ BEAT by 12 KB
Target 3:      25 KB  (+ UPX - not needed!)
Aggressive:   <10 KB  (extreme flags - not needed)
```

### Optimization Applied (2025-10-21)

Compiler flags used in `build.sh`:
```bash
x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe \
  -Os \                    # Optimize for size
  -s \                     # Strip symbols
  -ffunction-sections \    # Separate sections
  -fdata-sections \
  -Wl,--gc-sections       # Garbage collect unused
```

**Result:** 465K → 38K (91% reduction)
**Testing:** ✓ All tests pass (no arguments, with arguments, exit codes)
**Compatibility:** Not yet tested on multiple Windows versions

---

## Implementation Plan

1. ✓ **Update build.sh** with optimization flags (DONE - 2025-10-21)
2. ✓ **Measure actual size reduction** (DONE - 91% reduction achieved)
3. ✓ **Document results** in this file (DONE)
4. **Test on Windows 10/11** for compatibility (PENDING)
5. **Optional:** Create separate UPX build target (NOT NEEDED - 38K is small enough)
6. **Optional:** Test aggressive alignment flags (NOT NEEDED - current size is excellent)

---

## References

- [Stack Overflow: MinGW executable size reduction](https://stackoverflow.com/questions/7973274/how-to-reduce-the-size-of-executable-produced-by-mingw-g-compiler)
- [Stack Overflow: Tiny PE executables with MinGW](https://stackoverflow.com/questions/42022132/how-to-create-tiny-pe-win32-executables-using-mingw)
- [UPX Homepage](https://upx.github.io/)
- [GCC Optimization Options](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html)

---

## Notes

- Current launcher uses only Windows API (no C++ stdlib)
- Binary is statically linked by default (no external DLL dependencies)
- Size bloat likely from MinGW runtime and default alignment
- stdio.h usage minimal (fprintf for errors - now removed)
- Future: Consider removing stdio.h entirely if all output removed
