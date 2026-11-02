using System.ComponentModel;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using MacMarker.Core;

namespace MacMarker.Windows;

internal sealed class Overlay : Form
{
    private readonly Rectangle monitor;
    private readonly nint dc, dib, oldBitmap;
    private readonly Bitmap surface;
    public int Frames { get; private set; }
    public Overlay(Rectangle bounds)
    {
        monitor = bounds;
        FormBorderStyle = FormBorderStyle.None; ShowInTaskbar = false; StartPosition = FormStartPosition.Manual;
        AutoScaleMode = AutoScaleMode.None; Bounds = bounds; TopMost = true;
        dc = Native.CreateCompatibleDC(0);
        var info = new Native.BitmapInfo { Size = (uint)Marshal.SizeOf<Native.BitmapInfo>(), Width = bounds.Width, Height = -bounds.Height, Planes = 1, BitCount = 32 };
        dib = Native.CreateDIBSection(dc, ref info, 0, out var bits, 0, 0);
        if (dc == 0 || dib == 0 || bits == 0)
        {
            if (dib != 0) Native.DeleteObject(dib);
            if (dc != 0) Native.DeleteDC(dc);
            throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not create drawing overlay.");
        }
        oldBitmap = Native.SelectObject(dc, dib);
        surface = new Bitmap(bounds.Width, bounds.Height, bounds.Width * 4, PixelFormat.Format32bppPArgb, bits);
        Render(new MarkSession(), new MarkerSettings(), 0);
        Show();
        RaiseWithoutActivation();
    }
    internal void RaiseWithoutActivation() => Native.SetWindowPos(Handle, -1, monitor.X, monitor.Y, monitor.Width, monitor.Height, 0x10);
    protected override bool ShowWithoutActivation => true;
    protected override CreateParams CreateParams
    {
        get { var p = base.CreateParams; p.ExStyle |= 0x80000 | 0x20 | 0x80 | 0x8000000; return p; }
    }
    protected override void WndProc(ref Message message)
    {
        if (message.Msg == 0x84) { message.Result = -1; return; } // HTTRANSPARENT
        if (message.Msg == 0x21) { message.Result = 3; return; } // MA_NOACTIVATE
        base.WndProc(ref message);
    }
    public void Render(MarkSession session, MarkerSettings settings, double opacity)
    {
        using (var graphics = Graphics.FromImage(surface))
        {
            graphics.CompositingMode = CompositingMode.SourceCopy;
            graphics.Clear(Color.Transparent);
            graphics.CompositingMode = CompositingMode.SourceOver;
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            graphics.TranslateTransform(-monitor.X, -monitor.Y);
            var rgb = ColorTranslator.FromHtml(settings.Color);
            var alpha = (int)Math.Round(255 * settings.Opacity / 100.0 * opacity);
            using var pen = new Pen(Color.FromArgb(alpha, rgb), settings.Width) { StartCap = LineCap.Round, EndCap = LineCap.Round, LineJoin = LineJoin.Round };
            using var brush = new SolidBrush(pen.Color);
            foreach (var stroke in session.Strokes)
            {
                if (stroke.Points.Count == 1)
                {
                    var p = stroke.Points[0]; var r = settings.Width / 2f;
                    graphics.FillEllipse(brush, p.X - r, p.Y - r, settings.Width, settings.Width);
                }
                else if (stroke.Points.Count > 1)
                    graphics.DrawLines(pen, stroke.Points.Select(p => new Point(p.X, p.Y)).ToArray());
            }
        }
        var destination = new Native.Point(monitor.X, monitor.Y);
        var size = new Native.Size(monitor.Width, monitor.Height);
        var origin = new Native.Point(0, 0);
        var blend = new Native.Blend { Alpha = 255, Format = 1 };
        if (!Native.UpdateLayeredWindow(Handle, 0, ref destination, ref size, dc, ref origin, 0, ref blend, 2))
            throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not update drawing overlay.");
        Frames++;
    }
    protected override void Dispose(bool disposing)
    {
        if (disposing && !IsDisposed)
        {
            surface.Dispose(); Native.SelectObject(dc, oldBitmap); Native.DeleteObject(dib); Native.DeleteDC(dc);
        }
        base.Dispose(disposing);
    }
}
