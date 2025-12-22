const sdl3 = @import("sdl3");
const std = @import("std");

inline fn mapF32(comptime T: type, arr: [2]T) [2]f32 {
    return .{ @floatFromInt(arr[0]), @floatFromInt(arr[1]) };
}

pub const ItemSlot = struct {
    cx: i32,
    cy: i32,
    icon: sdl3.surface.Surface,
    window: *const sdl3.video.Window,

    pub fn new(x: i32, y: i32, window: *const sdl3.video.Window, icon: sdl3.surface.Surface) ItemSlot {
        return ItemSlot{ .cx = x, .cy = y, .icon = icon, .window = window };
    }

    pub fn isHovered(self: ItemSlot) bool {
        _, const mx, const my = sdl3.mouse.getGlobalState();

        const winX, const winY = mapF32(isize, self.window.getPosition() catch return false);

        const x1: f32 = @floatFromInt(self.cx);
        const y1: f32 = @floatFromInt(self.cy);

        return mx > x1 + winX - 32 and mx < x1 + 32 + winX and my > y1 - 32 + winY and my < y1 + 32 + winY;
    }

    pub fn draw(self: ItemSlot, showItem: bool) !void {
        const surf = try self.window.getSurface();

        try surf.fillRect(.{ .x = self.cx - 32, .y = self.cy - 32, .w = 64, .h = 64 }, if (self.isHovered()) surf.mapRgb(128, 128, 0) else surf.mapRgb(128, 0, 128));

        if (showItem)
            try self.icon.blit(null, surf, .{ .x = self.cx - 32, .y = self.cy - 32 });
    }
};

pub const ItemMoveWin = struct {
    isVisible: bool,
    handle: sdl3.video.Window,
    surface: ?sdl3.surface.Surface,

    pub fn init() !ItemMoveWin {
        const self = ItemMoveWin{ .handle = try sdl3.video.Window.init("Dummy Item", 128, 128, .{ .utility = true, .borderless = true, .transparent = true, .always_on_top = true }), .surface = null, .isVisible = false };
        try self.handle.hide();

        return self;
    }

    pub fn deinit(self: ItemMoveWin) void {
        self.handle.deinit();
    }

    pub fn draw(self: ItemMoveWin) !void {
        if (!self.visible()) return;
        // Special Item (maybe limit updates for this window HEAVILY)
        const itmSef = try self.handle.getSurface();
        try itmSef.fillRect(null, itmSef.mapRgba(0, 0, 0, 0));
        try self.surface.?.blit(null, itmSef, .{ .x = 32, .y = 32 });
        try self.handle.updateSurface();
    }

    pub fn visible(self: ItemMoveWin) bool {
        return self.isVisible;
    }

    pub fn updatePosition(self: ItemMoveWin) !void {
        _, const mx, const my = sdl3.mouse.getGlobalState();
        try self.handle.setPosition(.{ .absolute = @intFromFloat(mx - 64) }, .{ .absolute = @intFromFloat(my - 64) });
    }

    pub fn handleEvent(self: *ItemMoveWin, event: sdl3.events.Event) !void {
        switch (event) {
            .mouse_motion => if (self.visible()) {
                try self.updatePosition();
            },
            .mouse_button_down => |mbd| if (self.visible() and mbd.button == sdl3.mouse.Button.left and mbd.window_id == try self.handle.getId()) {
                _, const mx, const my = sdl3.mouse.getGlobalState();

                // Raise the window the mouse is over
                for (try sdl3.video.getWindows()) |win| {
                    const wPos = try win.getPosition();
                    const wSize = try win.getSize();

                    const wRect = sdl3.rect.IRect{ .x = @intCast(wPos.@"0"), .y = @intCast(wPos.@"1"), .w = @intCast(wSize.@"0"), .h = @intCast(wSize.@"1") };

                    if (wRect.pointIn(.{ .x = @intFromFloat(mx), .y = @intFromFloat(my) }) and win != self.handle) {
                        try win.raise();
                        break;
                    }
                }

                try self.hide();
            },
            else => {},
        }
    }

    pub fn show(self: *ItemMoveWin, surface: sdl3.surface.Surface) !void {
        try self.handle.show();
        self.isVisible = true;
        self.surface = surface;

        _, const mx, const my = sdl3.mouse.getGlobalState();
        try self.handle.setPosition(.{ .absolute = @intFromFloat(mx - 64) }, .{ .absolute = @intFromFloat(my - 64) });
    }

    pub fn hide(self: *ItemMoveWin) !void {
        try self.handle.hide();
        self.isVisible = false;
    }

    pub fn getId(self: ItemMoveWin) !u32 {
        return self.handle.getId();
    }
};
