using System.Reflection;
using System.Runtime.InteropServices;
using System.Text.Json;
using MacMarker.Core;

namespace MacMarker.Windows;

// Only explicitly enabled by scripts on an isolated CI desktop. Never synthesizes on a user's desktop.
internal static class SmokeTest
{
    public static async Task Run(MarkerApplication app, string receipt)
    {
        var checks = new Dictionary<string, bool>();
        string? error = null;
        object? pointerDiagnostics = null;
        void Check(string name, bool value) { checks[name] = value; if (!value) throw new InvalidOperationException(name); }
        try
        {
            await Task.Delay(300);
            Check("firstLaunchSettingsVisible", app.FirstLaunchShown && app.SettingsWindow is { Visible: true });
            Check("trayAndPerMonitorOverlays", app.TrayVisible && app.OverlayCount == Screen.AllScreens.Length && app.OverlayCount > 0);
            app.SettingsWindow!.Close(); await Task.Delay(150);
            Check("hooksInstalled", app.Hooks.Installed);
            Check("defaultF8", app.Settings.Shortcut.Keys.SequenceEqual([0x77]));
            using var probe = new PointerProbe();
            probe.Show(); probe.Activate(); app.RaiseOverlays(); await Task.Delay(150);
            // Show() alone does not guarantee that this receiver is above the runner console.
            // First establish the real native destination, then reset counters so baseline input
            // cannot satisfy any held-input assertion. The actual overlay remains above the probe.
            Move(-20, -20); await Task.Delay(100);
            Native.GetCursorPos(out var baselineCursor);
            pointerDiagnostics = new { stage = "baseline", cursor = new { baselineCursor.X, baselineCursor.Y },
                hit = Native.WindowFromPoint(baselineCursor).ToInt64(), foreground = Native.GetForegroundWindow().ToInt64(),
                probe = probe.Handle.ToInt64(), bounds = probe.Bounds.ToString(), client = probe.RectangleToScreen(probe.ClientRectangle).ToString(),
                moves = probe.Moves, thread = Environment.CurrentManagedThreadId, syncContext = SynchronizationContext.Current?.GetType().Name };
            Check("pointerProbeReceivesBaseline", probe.Moves > 0);
            Pointer(2); Pointer(4); await Task.Delay(100);
            Key(false); await Task.Delay(150);
            Check("nativeKeyDownHeld", app.Session.IsDrawing && app.Hooks.KeyTransitions > 0);
            probe.ResetCounters();
            Move(20, 10); await Task.Delay(100); Move(15, 8); await Task.Delay(100);
            Check("nativeMouseMovePaintsWithoutButton", app.Session.Strokes.Any(s => s.Points.Count >= 2) && app.Hooks.MouseMoves > 0);
            Check("layeredOverlayRendered", app.RenderedFrames > 1 && app.LastError is null);
            Native.GetCursorPos(out var heldCursor);
            pointerDiagnostics = new { stage = "held", cursor = new { heldCursor.X, heldCursor.Y },
                hit = Native.WindowFromPoint(heldCursor).ToInt64(), foreground = Native.GetForegroundWindow().ToInt64(),
                probe = probe.Handle.ToInt64(), bounds = probe.Bounds.ToString(), client = probe.RectangleToScreen(probe.ClientRectangle).ToString(),
                moves = probe.Moves, thread = Environment.CurrentManagedThreadId, syncContext = SynchronizationContext.Current?.GetType().Name };
            Check("mouseMovePassesThroughOverlay", probe.Moves > 0);
            Pointer(2); Pointer(0x800, 120); await Task.Delay(100);
            Check("heldButtonsAndWheelSuppressed", probe.Downs == 0 && probe.Wheels == 0);
            Key(true); await Task.Delay(150);
            Check("nativeKeyUpRestoresImmediately", !app.Session.IsDrawing);
            Check("releaseFadeInProgress", app.Session.Opacity(app.Now) is > 0 and < 1);
            Pointer(4); await Task.Delay(50); Check("matchingSuppressedUpAfterRelease", probe.Ups == 0);
            Pointer(2); Pointer(4); Pointer(0x800, 120); await Task.Delay(100);
            Check("releasedButtonsAndWheelPassThrough", probe.Downs > 0 && probe.Ups > 0 && probe.Wheels > 0);
            Key(false); await Task.Delay(100); Check("nativeReholdCancelsFade", app.Session.Opacity(app.Now) == 1);
            Key(true); await Task.Delay(1600); Check("fadeClearsGeometry", app.Session.Strokes.Count == 0);
            app.ToggleFromTray(); await Task.Delay(100);
            Check("pauseRemovesBothHooks", !app.Hooks.Installed && !app.Session.IsDrawing);
            Check("pausePersisted", !new SettingsStore(Path.GetDirectoryName(app.SettingsPath)!).Load().Settings.Enabled);
            Key(false); Move(10, 10); Key(true); await Task.Delay(100);
            Check("pausedInputCannotDraw", app.Session.Strokes.Count == 0);
            app.ToggleFromTray(); await Task.Delay(100); Check("reenableInstallsHooks", app.Hooks.Installed);
            Key(false); Move(10, 10); await Task.Delay(100); Check("reenabledDraws", app.Session.IsDrawing && app.Session.Strokes.Count > 0);
            app.ToggleFromTray(); Check("disableDuringHoldReleasesInput", !app.Hooks.Installed && !app.Session.IsDrawing && app.Session.Strokes.Count == 0);
            Key(true);
        }
        catch (Exception ex) { error = ex.Message; Environment.ExitCode = 1; }
        finally
        {
            // Always release our synthesized key, including assertion failures.
            try { Key(true); Pointer(4); } catch (Exception ex) { error ??= ex.Message; Environment.ExitCode = 1; }
            Directory.CreateDirectory(Path.GetDirectoryName(receipt)!);
            File.WriteAllText(receipt, JsonSerializer.Serialize(new
            {
                schemaVersion = 1, pass = error is null, error, checks, pointerDiagnostics,
                version = typeof(Program).Assembly.GetName().Version?.ToString(),
                sourceVersion = typeof(Program).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion,
                desktop = "isolated-ci-native-SendInput", os = Environment.OSVersion.ToString(),
                monitors = Screen.AllScreens.Select(s => new { s.Bounds.X, s.Bounds.Y, s.Bounds.Width, s.Bounds.Height }),
                physicalHardwareAcceptance = "NOT_RUN", unsigned = true
            }, new JsonSerializerOptions { WriteIndented = true }));
            app.ExitThread();
        }
    }
    private sealed class PointerProbe : Form
    {
        public int Moves, Downs, Ups, Wheels;
        public PointerProbe()
        {
            Text = "MacMarker CI pointer probe"; TopMost = true; ShowInTaskbar = false; StartPosition = FormStartPosition.Manual;
            var screen = Screen.PrimaryScreen!.Bounds;
            Bounds = new Rectangle(screen.Left + screen.Width / 2 - 160, screen.Top + screen.Height / 2 - 100, 320, 240);
        }
        public void ResetCounters() { Moves = Downs = Ups = Wheels = 0; }
        protected override void WndProc(ref Message message)
        {
            switch (message.Msg) { case 0x200: Moves++; break; case 0x201: case 0x203: Downs++; break; case 0x202: Ups++; break; case 0x20A: Wheels++; break; }
            base.WndProc(ref message);
        }
    }
    private static void Pointer(uint flags, uint data = 0) => Send(new Native.Input { Type = 0, Data = new Native.InputUnion { Mouse = new Native.MouseInput { Flags = flags, Data = data } } });
    private static void Key(bool up) => Send(new Native.Input { Type = 1, Data = new Native.InputUnion { Key = new Native.KeyInput { Key = 0x77, Flags = up ? 2u : 0 } } });
    private static void Move(int x, int y)
    {
        var desktop = SystemInformation.VirtualScreen;
        var primary = Screen.PrimaryScreen!.Bounds;
        var targetX = primary.Left + primary.Width / 2 + x;
        var targetY = primary.Top + primary.Height / 2 + y;
        Send(new Native.Input { Type = 0, Data = new Native.InputUnion { Mouse = new Native.MouseInput
        {
            X = (int)((targetX - desktop.Left) * 65535L / Math.Max(1, desktop.Width - 1)),
            Y = (int)((targetY - desktop.Top) * 65535L / Math.Max(1, desktop.Height - 1)), Flags = 0xC001
        } } });
    }
    private static void Send(Native.Input input)
    {
        if (Native.SendInput(1, [input], Marshal.SizeOf<Native.Input>()) != 1) throw new InvalidOperationException("SendInput unavailable on this desktop");
    }
}
