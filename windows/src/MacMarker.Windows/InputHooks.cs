using System.ComponentModel;
using System.Runtime.InteropServices;
using MacMarker.Core;
using Shortcut = MacMarker.Core.Shortcut;

namespace MacMarker.Windows;

internal sealed class InputHooks : IDisposable
{
    private readonly MarkSession session;
    private readonly Func<Shortcut> shortcut;
    private readonly Func<double> now;
    private nint keyboard, mouse;
    private readonly Native.HookProc keyboardCallback = null!;
    private readonly Native.HookProc mouseCallback = null!;
    private readonly HashSet<int> pressed = [], blockedKeys = [], forwardedKeys = [], blockedButtons = [], forwardedButtons = [];
    private bool recording;
    private int[] candidate = [];
    public bool Installed => keyboard != 0 && mouse != 0;
    public bool Recording => recording;
    public bool Suspended { get; set; }
    public int[]? Recorded { get; private set; }
    public string? Fault { get; private set; }
    public int MouseMoves { get; private set; }
    public int KeyTransitions { get; private set; }

    // Delegates are rooted for the complete hook lifetime, including callbacks during disposal.
    public InputHooks(MarkSession session, Func<Shortcut> shortcut, Func<double> now)
    { this.session = session; this.shortcut = shortcut; this.now = now; keyboardCallback = Keyboard; mouseCallback = Mouse; }

    public void Install()
    {
        if (Installed) return;
        DisposeHooks(); Fault = null;
        var module = Native.GetModuleHandle(null);
        keyboard = Native.SetWindowsHookEx(13, keyboardCallback, module, 0);
        if (keyboard != 0) mouse = Native.SetWindowsHookEx(14, mouseCallback, module, 0);
        if (!Installed) { var error = Marshal.GetLastWin32Error(); DisposeHooks(); throw new Win32Exception(error, "Input hooks could not start. Drawing is off."); }
        // Only seed at installation, outside LLKeyboardProc. Never swallow an up whose down predated our hooks.
        for (var key = 8; key <= 254; key++)
            if (key is not (0x10 or 0x11 or 0x12) && Native.GetAsyncKeyState(key) < 0) { pressed.Add(key); forwardedKeys.Add(key); }
    }
    public void BeginRecording()
    {
        session.Reset(); pressed.Clear(); candidate = []; Recorded = null;
        Install(); recording = true;
    }
    public void EndRecording() { recording = false; pressed.Clear(); session.Reset(); }
    public void ClearRecorded() => Recorded = null;
    private static int KeyCode(Native.KeyboardData data) => data.Key switch
    {
        0x10 => data.ScanCode == 0x36 ? 0xA1 : 0xA0,
        0x11 => (data.Flags & 1) != 0 ? 0xA3 : 0xA2,
        0x12 => (data.Flags & 1) != 0 ? 0xA5 : 0xA4,
        _ => (int)data.Key
    };
    private nint Keyboard(int code, nuint message, nint data)
    {
        if (code < 0) return Native.CallNextHookEx(keyboard, code, message, data);
        try
        {
            var key = KeyCode(Marshal.PtrToStructure<Native.KeyboardData>(data));
            var down = message is 0x100 or 0x104;
            var up = message is 0x101 or 0x105;
            if (!down && !up) return Native.CallNextHookEx(keyboard, code, message, data);
            KeyTransitions++;
            if (down) pressed.Add(key); else pressed.Remove(key);
            if (recording)
            {
                if (key == 27) { Recorded = []; recording = false; }
                else if (down && pressed.Count <= 8) candidate = pressed.Order().ToArray();
                else if (up && candidate.Length > 0) { Recorded = candidate; recording = false; }
                if (down && !forwardedKeys.Contains(key)) { blockedKeys.Add(key); return 1; }
                if (up && blockedKeys.Remove(key)) return 1;
            }
            else if (!Suspended)
            {
                session.SetHeld(shortcut().Matches(pressed), now());
                if (down && key == 27) { var drawing = session.IsDrawing; session.Cancel(); if (drawing) { blockedKeys.Add(key); return 1; } }
            }
            if (up)
            {
                forwardedKeys.Remove(key);
                if (blockedKeys.Remove(key)) return 1;
            }
            else if (blockedKeys.Contains(key) || (!forwardedKeys.Contains(key) && session.IsDrawing))
            { blockedKeys.Add(key); return 1; }
            else forwardedKeys.Add(key);
        }
        catch { Fault = "Input processing stopped; drawing was cleared."; Suspended = true; session.Reset(); }
        return Native.CallNextHookEx(keyboard, code, message, data);
    }
    private nint Mouse(int code, nuint message, nint data)
    {
        if (code < 0) return Native.CallNextHookEx(mouse, code, message, data);
        try
        {
            if (message == 0x200)
            {
                MouseMoves++;
                if (!Suspended) { var position = Marshal.PtrToStructure<Native.MouseData>(data).Point; session.Move(position.X, position.Y); }
                return Native.CallNextHookEx(mouse, code, message, data); // Cursor movement MUST pass through.
            }
            var button = message switch { 0x201 or 0x202 or 0x203 => 1, 0x204 or 0x205 or 0x206 => 2, 0x207 or 0x208 or 0x209 => 3, 0x20B or 0x20C or 0x20D => 3 + (int)(Marshal.PtrToStructure<Native.MouseData>(data).Mouse >> 16), _ => 0 };
            var down = message is 0x201 or 0x203 or 0x204 or 0x206 or 0x207 or 0x209 or 0x20B or 0x20D;
            if (button != 0)
            {
                if (!down)
                {
                    forwardedButtons.Remove(button);
                    if (blockedButtons.Remove(button)) return 1;
                }
                else if (!Suspended && session.IsDrawing && !forwardedButtons.Contains(button)) { blockedButtons.Add(button); return 1; }
                else forwardedButtons.Add(button);
            }
            if (!Suspended && session.IsDrawing && message is 0x20A or 0x20E) return 1;
        }
        catch { Fault = "Pointer processing stopped; drawing was cleared."; Suspended = true; session.Reset(); }
        return Native.CallNextHookEx(mouse, code, message, data);
    }
    private void DisposeHooks()
    {
        if (keyboard != 0) { Native.UnhookWindowsHookEx(keyboard); keyboard = 0; }
        if (mouse != 0) { Native.UnhookWindowsHookEx(mouse); mouse = 0; }
        pressed.Clear(); blockedKeys.Clear(); forwardedKeys.Clear(); blockedButtons.Clear(); forwardedButtons.Clear();
        recording = false; session.Reset();
    }
    public void Dispose() { DisposeHooks(); Fault = null; GC.KeepAlive(keyboardCallback); GC.KeepAlive(mouseCallback); }
}
