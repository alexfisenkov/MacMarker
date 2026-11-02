using MacMarker.Core;

var assertions = 0;
void Check(bool value, string scenario) { assertions++; if (!value) throw new Exception(scenario); }
var session = new MarkSession();
session.Move(1, 2); Check(session.Strokes.Count == 0, "No drawing while released");
session.SetHeld(true, 0); session.Move(-200, 2); session.Move(-190, 5);
Check(session.IsDrawing && session.Strokes[0].Points.Count == 2, "Physical hold + move, no button needed; negative coordinates");
Check(session.Opacity(999) == 1, "Held marks never fade");
session.SetHeld(false, 1000); Check(!session.IsDrawing, "Key-up immediately restores input state");
Check(Math.Abs(session.Opacity(1000.7) - .5) < .00001, "Release fades1.4seconds");
session.SetHeld(true, 1000.8); Check(session.Opacity(1002) == 1, "Rehold cancels stale fade");
session.Move(40, 50); Check(session.Strokes.Count == 2, "Rehold starts a separate stroke");
session.Cancel(); session.Move(5, 5); Check(!session.IsDrawing && session.Strokes.Count == 0, "Escape cancels until trigger released");
session.SetHeld(false, 1003); session.SetHeld(true, 1004); session.Move(5, 5);
Check(session.Strokes.Count == 1, "Release re-arms cancelled hold");
session.SetHeld(false, 1005); Check(session.Opacity(1006.5) == 0 && session.Strokes.Count == 0, "Fade clears RAM geometry");
session.SetHeld(true, 1007); session.Move(1, 1); session.Reset(); session.Move(2, 2);
Check(!session.IsDrawing && session.Strokes.Count == 0, "Pause/lock clears and gates drawing");
Check(Shortcut.Default.Matches(new HashSet<int> { 0x77 }), "Default F8");
Check(!Shortcut.Default.Matches(new HashSet<int> { 0x77, 0xA2 }), "Extra modifiers do not steal chords");
Check(new Shortcut([0xA0]).Matches(new HashSet<int> { 0xA0 }), "Modifier-only binding");
Check(!new Shortcut([0xA2, 0xA5]).IsValid, "AltGr/Control+Alt reserved");
Check(!new Shortcut([27]).IsValid && !new Shortcut([0xA4, 0x73]).IsValid, "Escape and Alt+F4 remain available");
var path = Path.Combine(Path.GetTempPath(), "MacMarker-CoreTests-" + Guid.NewGuid());
try
{
    var store = new SettingsStore(path); Check(store.Load().FirstLaunch, "First launch");
    var settings = new MarkerSettings { Color = "#00FF11", Width = 100, Opacity = 0, Enabled = false, Shortcut = new([0xA0]) };
    store.Save(settings); var loaded = store.Load();
    Check(loaded.Warning is null && !loaded.Settings.Enabled && loaded.Settings.Opacity == 0 && loaded.Settings.Width == 100
        && loaded.Settings.Shortcut.Keys.SequenceEqual(settings.Shortcut.Keys), "Atomic settings roundtrip");
    store.Save(settings with { Width = 1 }); Check(File.Exists(store.FilePath + ".previous"), "Prior settings retained");
    File.WriteAllText(store.FilePath, "{bad");
    Check(store.Load().Warning is not null && File.ReadAllText(store.FilePath) == "{bad", "Invalid input visible and preserved");
    File.WriteAllText(store.FilePath, "{\"Width\":101}");
    Check(store.Load().Warning is not null, "Invalid ranges recovered visibly");
}
finally { if (Directory.Exists(path)) Directory.Delete(path, true); }
Console.WriteLine($"PASS {assertions} core assertions");
