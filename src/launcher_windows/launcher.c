/*
 * Minimal Windows launcher - executes a .cmd script
 * with the same name as the .exe (without extension).
 *
 * Compile: x86_64-w64-mingw32-gcc launcher.c -o bitbot.exe
 * Usage:   bitbot.exe [args...]
 * Looks for: bitbot.cmd
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#define MAX_PATH_LEN 4096

int main(int argc, char *argv[]) {
    char exePath[MAX_PATH_LEN];
    char scriptPath[MAX_PATH_LEN];
    char cmdLine[MAX_PATH_LEN * 2];
    char *lastDot;
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    DWORD exitCode = 1;

    // Get executable path
    if (GetModuleFileName(NULL, exePath, MAX_PATH_LEN) == 0) {
        return 1;
    }

    // Remove .exe extension
    lastDot = strrchr(exePath, '.');
    if (lastDot != NULL && _stricmp(lastDot, ".exe") == 0) {
        *lastDot = '\0';
    }

    // Build .cmd script path
    snprintf(scriptPath, MAX_PATH_LEN, "%s.cmd", exePath);

    // Check if file exists
    if (GetFileAttributes(scriptPath) == INVALID_FILE_ATTRIBUTES) {
        return 1;
    }

    // Build command line: cmd.exe /c "script.cmd" [args...]
    snprintf(cmdLine, sizeof(cmdLine), "cmd.exe /c \"%s\"", scriptPath);

    // Append arguments
    for (int j = 1; j < argc; j++) {
        strcat(cmdLine, " ");
        strcat(cmdLine, argv[j]);
    }

    // Execute script
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);
    ZeroMemory(&pi, sizeof(pi));

    if (!CreateProcess(NULL, cmdLine, NULL, NULL, TRUE, 0,
                      NULL, NULL, &si, &pi)) {
        return 1;
    }

    // Wait for completion
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &exitCode);

    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return exitCode;
}
