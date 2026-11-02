using Microsoft.Win32;

namespace MacMarker.Windows;

internal static class Startup
{
    private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
    public static void Set(bool enabled)
    {
        // Native smoke is isolated from real preferences and login registration.
        if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("MACMARKER_SETTINGS_DIR"))) return;
        using var key = Registry.CurrentUser.CreateSubKey(RunKey, true);
        if (enabled) key.SetValue("MacMarker", "\"" + Environment.ProcessPath + "\"");
        else key.DeleteValue("MacMarker", false);
    }
}
