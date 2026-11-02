using MacMarker.Core;
using Shortcut = MacMarker.Core.Shortcut;

namespace MacMarker.Windows;

internal sealed class SettingsForm : Form
{
    private readonly Button colorButton = new() { Text = "Choose color…", AutoSize = true };
    private readonly Button shortcutButton = new() { AutoSize = true };
    private readonly TrackBar opacity = new() { Minimum = 0, Maximum = 100, TickFrequency = 10, Width = 300 };
    private readonly TrackBar width = new() { Minimum = 1, Maximum = 100, TickFrequency = 10, Width = 300 };
    private readonly CheckBox login = new() { Text = "Start at login", AutoSize = true };
    private readonly Label opacityLabel = new() { AutoSize = true };
    private readonly Label widthLabel = new() { AutoSize = true };
    private readonly Label status = new() { AutoSize = true, MaximumSize = new Size(340, 0) };
    private readonly Action beginRecording;
    private readonly Func<MarkerSettings, string?> save;
    private MarkerSettings initial;
    private Shortcut shortcut;
    private Color selectedColor;
    public bool WaitingForShortcut { get; private set; }

    public SettingsForm(MarkerSettings settings, Action beginRecording, Func<MarkerSettings, string?> save)
    {
        this.beginRecording = beginRecording; this.save = save; initial = settings; shortcut = settings.Shortcut;
        Icon = Program.ProductIcon; Text = "MacMarker · Settings"; AutoScaleMode = AutoScaleMode.Dpi; FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterScreen; MaximizeBox = false; MinimizeBox = false; ClientSize = new Size(390, 460);
        var panel = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(20), AutoScroll = true };
        panel.Controls.Add(new Label { Text = "Hold the shortcut and move your mouse to draw.\nRelease to fade. Escape clears marks.", AutoSize = true });
        panel.Controls.Add(shortcutButton);
        panel.Controls.Add(new Label { Text = "A single key, chord, or modifier. F8 recommended.\nWindows keys and OS/security chords are reserved.", AutoSize = true });
        selectedColor = ColorTranslator.FromHtml(settings.Color); colorButton.BackColor = selectedColor;
        panel.Controls.Add(colorButton); panel.Controls.Add(opacityLabel); panel.Controls.Add(opacity); panel.Controls.Add(widthLabel); panel.Controls.Add(width); panel.Controls.Add(login);
        var apply = new Button { Text = "Save", AutoSize = true };
        panel.Controls.Add(apply); panel.Controls.Add(status); Controls.Add(panel);
        opacity.Value = settings.Opacity; width.Value = settings.Width; login.Checked = settings.StartAtLogin;
        opacity.ValueChanged += (_, _) => UpdateLabels(); width.ValueChanged += (_, _) => UpdateLabels();
        colorButton.Click += (_, _) => { using var picker = new ColorDialog { Color = selectedColor, FullOpen = true, AnyColor = true }; if (picker.ShowDialog(this) == DialogResult.OK) { selectedColor = picker.Color; colorButton.BackColor = selectedColor; } };
        shortcutButton.Click += (_, _) => { WaitingForShortcut = true; status.Text = "Press and release your shortcut. Escape cancels."; beginRecording(); };
        apply.Click += (_, _) =>
        {
            if (WaitingForShortcut) { status.Text = "Finish recording or press Escape first."; return; }
            var next = initial with { Color = $"#{selectedColor.R:X2}{selectedColor.G:X2}{selectedColor.B:X2}", Opacity = opacity.Value, Width = width.Value, StartAtLogin = login.Checked, Shortcut = shortcut };
            var error = save(next);
            if (error is null) Close(); else status.Text = error;
        };
        UpdateLabels();
    }
    public void ReceiveShortcut(int[] keys)
    {
        WaitingForShortcut = false;
        if (keys.Length == 0) status.Text = "Recording cancelled.";
        else if (new Shortcut(keys).IsValid) { shortcut = new(keys); status.Text = "Shortcut recorded. Save to apply."; }
        else status.Text = "This shortcut is reserved. Try F8 or another key.";
        UpdateLabels();
    }
    internal static string ShortcutName(Shortcut value) => string.Join(" + ", value.Keys.Select(k => ((Keys)k).ToString()));
    private void UpdateLabels()
    {
        opacityLabel.Text = $"Opacity: {opacity.Value}%"; widthLabel.Text = $"Width: {width.Value}";
        shortcutButton.Text = "Shortcut: " + ShortcutName(shortcut) + " (change…)";
    }
}
