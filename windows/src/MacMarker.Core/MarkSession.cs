namespace MacMarker.Core;

public readonly record struct MarkPoint(int X, int Y);
public sealed class Stroke
{
    public List<MarkPoint> Points { get; } = [];
}

public sealed class MarkSession
{
    public const double FadeSeconds = 1.4;
    private bool cancelled;
    private Stroke? current;
    private double? releasedAt;
    public bool IsHeld { get; private set; }
    public bool IsDrawing => IsHeld && !cancelled;
    public List<Stroke> Strokes { get; } = [];
    public long Revision { get; private set; }

    public void SetHeld(bool held, double now)
    {
        if (held == IsHeld) return;
        IsHeld = held;
        current = null;
        if (held) releasedAt = null; // Rehold freezes all existing marks at full opacity.
        else { cancelled = false; releasedAt = Strokes.Count == 0 ? null : now; }
        Revision++;
    }
    public void Move(int x, int y)
    {
        if (!IsDrawing) return;
        if (current is null) { current = new(); Strokes.Add(current); }
        var point = new MarkPoint(x, y);
        if (current.Points.Count > 0 && current.Points[^1] == point) return;
        current.Points.Add(point);
        // Bound RAM even if the hold key is kept down for hours.
        if (current.Points.Count > 20000) current.Points.RemoveRange(0, 1000);
        if (Strokes.Count > 100) Strokes.RemoveAt(0);
        Revision++;
    }
    public double Opacity(double now)
    {
        if (releasedAt is not { } release) return 1;
        var alpha = Math.Clamp(1 - (now - release) / FadeSeconds, 0, 1);
        if (alpha == 0) ClearGeometry();
        return alpha;
    }
    public void Cancel()
    {
        cancelled = IsHeld;
        ClearGeometry();
    }
    public void Reset()
    {
        IsHeld = false;
        cancelled = false;
        ClearGeometry();
    }
    private void ClearGeometry()
    {
        Strokes.Clear(); current = null; releasedAt = null; Revision++;
    }
}
