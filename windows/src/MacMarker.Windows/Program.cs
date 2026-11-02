using System.Text.Json;
using MacMarker.Core;

namespace MacMarker.Windows;

internal static class Program
{
    internal static Icon ProductIcon { get; } = new(typeof(Program).Assembly.GetManifestResourceStream("MacMarker.Icon.ico")!);
    [STAThread]
    private static int Main(string[] args)
    {
        string? receipt = null;
        if (args.Length > 0)
        {
            if (args.Length != 2 || args[0] != "--smoke-test") return 2;
            receipt = Path.GetFullPath(args[1]);
            if (Environment.GetEnvironmentVariable("MACMARKER_CI_SMOKE") != "1"
                || string.IsNullOrEmpty(Environment.GetEnvironmentVariable("MACMARKER_SETTINGS_DIR"))) return 3;
        }
        Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
        Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
        var directory = Environment.GetEnvironmentVariable("MACMARKER_SETTINGS_DIR")
            ?? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "MacMarker");
        using var mutex = new Mutex(true, @"Local\MacMarker.Desktop", out var firstInstance);
        if (!firstInstance) { if (receipt is null) MessageBox.Show("MacMarker is already running. Open Settings from its tray icon.", "MacMarker"); return 4; }
        try
        {
            using var app = new MarkerApplication(new SettingsStore(directory), receipt);
            Application.Run(app);
            return Environment.ExitCode;
        }
        catch (Exception ex)
        {
            if (receipt is not null) File.WriteAllText(receipt, JsonSerializer.Serialize(new { pass = false, error = ex.Message }));
            else MessageBox.Show("MacMarker stopped and released input.\n" + ex.Message, "MacMarker", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
