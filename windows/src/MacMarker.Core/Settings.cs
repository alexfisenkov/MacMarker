using System.Text.Json;

namespace MacMarker.Core;

public sealed record Shortcut(int[] Keys)
{
    public static Shortcut Default => new([0x77]); // F8
    public bool IsValid => Keys is { Length: > 0 and <= 8 } && Keys.Distinct().Count() == Keys.Length
        && Keys.All(k => k is >= 8 and <= 254 && k != 27 && k is not (0x5B or 0x5C))
        && !IsReserved;
    // Windows/security and standard destructive OS chords remain owned by the OS.
    public bool IsReserved => (Keys.Any(k => k is 0xA2 or 0xA3 or 0x11)
        && Keys.Any(k => k is 0xA4 or 0xA5 or 0x12))
        || (Keys.Any(k => k is 0xA4 or 0xA5 or 0x12) && Keys.Any(k => k is 0x09 or 0x73 or 0x20));
    public bool Matches(IReadOnlySet<int> pressed) => IsValid && Keys.All(pressed.Contains)
        && !pressed.Any(k => IsModifier(k) && !Keys.Contains(k));
    public static bool IsModifier(int k) => k is 0x10 or 0x11 or 0x12 or >= 0xA0 and <= 0xA5 or 0x5B or 0x5C;
}

public sealed record MarkerSettings
{
    public int SchemaVersion { get; init; } = 1;
    public bool Enabled { get; init; } = true;
    public bool StartAtLogin { get; init; }
    public string Color { get; init; } = "#FF3B30";
    public int Opacity { get; init; } = 85;
    public int Width { get; init; } = 8;
    public Shortcut Shortcut { get; init; } = Shortcut.Default;
    public void Validate()
    {
        if (SchemaVersion != 1 || Opacity is < 0 or > 100 || Width is < 1 or > 100
            || Color is null || Color.Length != 7 || Color[0] != '#'
            || !Color.AsSpan(1).ToString().All(Uri.IsHexDigit) || Shortcut?.IsValid != true)
            throw new InvalidDataException("Invalid preferences. Expected a valid shortcut, #RRGGBB, opacity0–100 and width1–100.");
    }
}

public sealed record SettingsLoad(MarkerSettings Settings, bool FirstLaunch, string? Warning);

public sealed class SettingsStore(string directory)
{
    private static readonly JsonSerializerOptions Options = new() { WriteIndented = true };
    public string FilePath => Path.Combine(directory, "settings.json");
    public SettingsLoad Load()
    {
        if (!File.Exists(FilePath)) return new(new(), true, null);
        try
        {
            var settings = JsonSerializer.Deserialize<MarkerSettings>(File.ReadAllText(FilePath))
                ?? throw new InvalidDataException("Preferences are empty.");
            settings.Validate();
            return new(settings, false, null);
        }
        catch (Exception ex) when (ex is IOException or UnauthorizedAccessException or JsonException or ArgumentException or InvalidDataException)
        {
            return new(new(), false, "Could not load preferences; defaults are active. The original file is preserved until you save. " + ex.Message);
        }
    }
    public void Save(MarkerSettings settings)
    {
        settings.Validate();
        Directory.CreateDirectory(directory);
        var temp = Path.Combine(directory, ".settings-" + Guid.NewGuid().ToString("N") + ".tmp");
        try
        {
            using (var stream = new FileStream(temp, FileMode.CreateNew, FileAccess.Write, FileShare.None, 4096, FileOptions.WriteThrough))
            {
                JsonSerializer.Serialize(stream, settings, Options);
                stream.Flush(true);
            }
            if (File.Exists(FilePath)) File.Replace(temp, FilePath, FilePath + ".previous", true);
            else File.Move(temp, FilePath);
        }
        finally { if (File.Exists(temp)) File.Delete(temp); }
    }
}
