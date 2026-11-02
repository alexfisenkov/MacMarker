using System.Diagnostics;
using MacMarker.Core;
using Microsoft.Win32;

namespace MacMarker.Windows;

internal sealed class MarkerApplication : ApplicationContext
{
    private readonly SettingsStore store;
    private readonly NotifyIcon tray;
    private readonly ToolStripMenuItem enabledItem;
    private readonly System.Windows.Forms.Timer timer = new() { Interval = 16 };
    private readonly Control dispatcher = new();
    private readonly List<Overlay> overlays = [];
    private readonly Stopwatch clock = Stopwatch.StartNew();
    private long lastRevision = -1;
    private double lastAlpha = -1;
    private bool closing, rebuilding, wasDrawing;
    internal readonly MarkSession Session = new();
    internal readonly InputHooks Hooks;
    internal MarkerSettings Settings { get; private set; }
    internal SettingsForm? SettingsWindow { get; private set; }
    internal bool FirstLaunchShown { get; private set; }
    internal bool TrayVisible => tray.Visible;
    internal int OverlayCount => overlays.Count;
    internal int RenderedFrames => overlays.Sum(o => o.Frames);
    internal double Now => clock.Elapsed.TotalSeconds;
    internal bool IsSmoke { get; }
    internal string? LastError { get; private set; }
    internal string SettingsPath => store.FilePath;

    public MarkerApplication(SettingsStore store, string? receipt)
    {
        this.store = store; IsSmoke = receipt is not null;
        var loaded = store.Load(); Settings = loaded.Settings;
        _ = dispatcher.Handle;
        Hooks = new InputHooks(Session, () => Settings.Shortcut, () => Now);
        enabledItem = new ToolStripMenuItem("Enabled", null, (_, _) => SetEnabled(!Settings.Enabled));
        var menu = new ContextMenuStrip();
        menu.Items.Add("Settings…", null, (_, _) => ShowSettings()); menu.Items.Add(enabledItem);
        menu.Items.Add(new ToolStripSeparator()); menu.Items.Add("Quit", null, (_, _) => ExitThread());
        tray = new NotifyIcon { Icon = Program.ProductIcon, Text = "MacMarker", ContextMenuStrip = menu, Visible = true };
        tray.DoubleClick += (_, _) => ShowSettings();
        RebuildOverlays();
        if (Settings.Enabled) TryInstall();
        RefreshTray();
        SystemEvents.DisplaySettingsChanged += DisplayChanged;
        SystemEvents.SessionSwitch += SessionChanged;
        timer.Tick += (_, _) => Tick(); timer.Start();
        if (loaded.FirstLaunch || loaded.Warning is not null)
        {
            ShowSettings(); FirstLaunchShown = true;
            if (loaded.FirstLaunch) TrySave(Settings);
        }
        if (loaded.Warning is not null) Report(loaded.Warning);
        if (receipt is not null) _ = SmokeTest.Run(this, receipt);
    }
    private void DisplayChanged(object? sender, EventArgs e) => Dispatch(() => rebuilding = true);
    private void SessionChanged(object sender, SessionSwitchEventArgs e)
    {
        if (e.Reason is SessionSwitchReason.SessionLock or SessionSwitchReason.SessionLogoff or SessionSwitchReason.ConsoleDisconnect or SessionSwitchReason.RemoteDisconnect)
            Dispatch(() => { Hooks.Dispose(); Session.Reset(); });
        else if (e.Reason is SessionSwitchReason.SessionUnlock or SessionSwitchReason.ConsoleConnect or SessionSwitchReason.RemoteConnect)
            Dispatch(() => { if (Settings.Enabled) TryInstall(); });
    }
    private void Dispatch(Action action) { if (!closing && !dispatcher.IsDisposed) dispatcher.BeginInvoke(action); }
    private void RebuildOverlays()
    {
        foreach (var overlay in overlays) overlay.Dispose(); overlays.Clear();
        try { foreach (var screen in Screen.AllScreens) overlays.Add(new Overlay(screen.Bounds)); }
        catch (Exception ex) { foreach (var overlay in overlays) overlay.Dispose(); overlays.Clear(); Hooks.Dispose(); Settings = Settings with { Enabled = false }; RefreshTray(); Report(ex.Message); }
        lastRevision = -1;
    }
    private void Tick()
    {
        if (rebuilding) { rebuilding = false; Session.Reset(); RebuildOverlays(); }
        if (Hooks.Fault is { } fault) { Hooks.Dispose(); Settings = Settings with { Enabled = false }; RefreshTray(); Report(fault); }
        if (Hooks.Recorded is { } keys)
        {
            Hooks.ClearRecorded(); SettingsWindow?.ReceiveShortcut(keys);
            if (!Settings.Enabled) Hooks.Dispose();
        }
        if (Session.IsDrawing && !wasDrawing) RaiseOverlays();
        wasDrawing = Session.IsDrawing;
        var alpha = Session.Opacity(Now);
        if (lastRevision == Session.Revision && Math.Abs(lastAlpha - alpha) < .002) return;
        try { foreach (var overlay in overlays) overlay.Render(Session, Settings, alpha); }
        catch (Exception ex) { Hooks.Dispose(); Settings = Settings with { Enabled = false }; Session.Reset(); foreach (var overlay in overlays) overlay.Dispose(); overlays.Clear(); RefreshTray(); Report(ex.Message); }
        lastRevision = Session.Revision; lastAlpha = alpha;
    }
    internal void ShowSettings()
    {
        if (SettingsWindow is { IsDisposed: false }) { SettingsWindow.Activate(); return; }
        Session.Reset(); Hooks.Suspended = true;
        SettingsWindow = new SettingsForm(Settings,
            () => { try { Hooks.BeginRecording(); } catch (Exception ex) { SettingsWindow?.ReceiveShortcut([]); Report(ex.Message); } },
            next =>
            {
                try
                {
                    next = next with { Enabled = Settings.Enabled };
                    next.Validate(); Startup.Set(next.StartAtLogin); store.Save(next); Settings = next;
                    Session.Reset(); lastRevision = -1; RefreshTray(); return null;
                }
                catch (Exception ex) { return "Could not save: " + ex.Message; }
            });
        SettingsWindow.FormClosed += (_, _) =>
        {
            Hooks.EndRecording(); Hooks.Suspended = false;
            if (!Settings.Enabled) Hooks.Dispose();
            SettingsWindow = null;
        };
        SettingsWindow.Show();
    }
    internal void RaiseOverlays() { foreach (var overlay in overlays) overlay.RaiseWithoutActivation(); }
    internal void ToggleFromTray() => enabledItem.PerformClick();
    internal void SetEnabled(bool enabled)
    {
        if (SettingsWindow?.WaitingForShortcut == true) SettingsWindow.ReceiveShortcut([]);
        Hooks.Dispose(); Session.Reset(); Settings = Settings with { Enabled = enabled };
        TrySave(Settings);
        if (enabled) { if (overlays.Count == 0) RebuildOverlays(); TryInstall(); }
        RefreshTray(); lastRevision = -1;
    }
    private void TryInstall()
    {
        if (overlays.Count == 0) { Settings = Settings with { Enabled = false }; return; }
        try { Hooks.Install(); Hooks.Suspended = SettingsWindow is { IsDisposed: false }; }
        catch (Exception ex) { Settings = Settings with { Enabled = false }; TrySave(Settings); Report(ex.Message); }
    }
    private void TrySave(MarkerSettings value) { try { store.Save(value); } catch (Exception ex) { Report("Preferences could not be saved: " + ex.Message); } }
    private void RefreshTray()
    {
        enabledItem.Checked = Settings.Enabled;
        enabledItem.Text = Settings.Enabled ? "Enabled (click to pause)" : "Paused (click to enable)";
        tray.Text = "MacMarker · " + (Settings.Enabled ? SettingsForm.ShortcutName(Settings.Shortcut) : "Paused");
    }
    private void Report(string text)
    {
        LastError = text;
        if (!IsSmoke && tray is not null) tray.ShowBalloonTip(8000, "MacMarker", text, ToolTipIcon.Warning);
    }
    protected override void ExitThreadCore()
    {
        if (closing) return;
        closing = true; timer.Stop(); Hooks.Dispose();
        SystemEvents.DisplaySettingsChanged -= DisplayChanged; SystemEvents.SessionSwitch -= SessionChanged;
        SettingsWindow?.Close(); foreach (var overlay in overlays) overlay.Dispose(); overlays.Clear();
        tray.Visible = false; tray.Dispose(); timer.Dispose(); dispatcher.Dispose();
        base.ExitThreadCore();
    }
}
