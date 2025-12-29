const sdl3 = @import("sdl3");
const std = @import("std");

inline fn mapF32(comptime T: type, arr: [2]T) [2]f32 {
    return .{ @floatFromInt(arr[0]), @floatFromInt(arr[1]) };
}

pub const ItemSlot = struct {
    cx: i32,
    cy: i32,
    icon: ?sdl3.surface.Surface,
    window: *const sdl3.video.Window,

    pub fn new(x: i32, y: i32, window: *const sdl3.video.Window, icon: ?sdl3.surface.Surface) ItemSlot {
        return ItemSlot{ .cx = x, .cy = y, .icon = icon, .window = window };
    }

    pub fn isHovered(self: ItemSlot) bool {
        _, const mx, const my = sdl3.mouse.getGlobalState();

        const winX, const winY = mapF32(isize, self.window.getPosition() catch return false);

        const x1: f32 = @floatFromInt(self.cx);
        const y1: f32 = @floatFromInt(self.cy);

        return mx > x1 + winX - 32 and mx < x1 + 32 + winX and my > y1 - 32 + winY and my < y1 + 32 + winY;
    }

    pub fn draw(self: ItemSlot) !void {

        const showItem = ItemMoveWin.get().getSlotDraggedFrom() != &self;

        const surf = try self.window.getSurface();

        try surf.fillRect(.{ .x = self.cx - 32, .y = self.cy - 32, .w = 64, .h = 64 }, if (!showItem or self.isHovered()) surf.mapRgb(128, 128, 0) else surf.mapRgb(128, 0, 128));

        if (showItem and self.icon != null)
            try self.icon.?.blit(null, surf, .{ .x = self.cx - 32, .y = self.cy - 32 });
    }

    pub fn getItem(self: ItemSlot) ?sdl3.surface.Surface {
        return self.icon;
    }

    pub fn hasItem(self: ItemSlot) bool {
        return self.icon != null;
    }

    pub fn putItem(self: *ItemSlot, item: ?sdl3.surface.Surface) void {
        self.icon = item;
    }

    pub fn getWindow(self: ItemSlot) *const sdl3.video.Window {
        return self.window;
    }
};

pub const ItemMoveWin = struct {

    handle: sdl3.video.Window,
    slotDraggedFrom: ?*ItemSlot,

    var  singleton: ?ItemMoveWin = null;
    pub fn get() *ItemMoveWin {
        return &singleton.?;
    }

    pub fn init() !void {
        const self = ItemMoveWin{ .handle = try sdl3.video.Window.init("Dummy Item", 128, 128, .{ .utility = true, .borderless = true, .transparent = true, .always_on_top = true }), .slotDraggedFrom = null };
        try self.handle.hide();

        singleton = self;
    }

    pub fn deinit(self: ItemMoveWin) void {
        self.handle.deinit();
    }

    pub fn draw(self: ItemMoveWin) !void {
        if (!self.visible()) return;
        // Special Item (maybe limit updates for this window HEAVILY)
        const itmSef = try self.handle.getSurface();
        try itmSef.fillRect(null, itmSef.mapRgba(0, 0, 0, 0));
        if (self.slotDraggedFrom.?.getItem()) |icon|
            try icon.blit(null, itmSef, .{ .x = 32, .y = 32 });
        try self.handle.updateSurface();
    }

    pub fn visible(self: ItemMoveWin) bool {
        return self.slotDraggedFrom != null;
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
            else => {},
        }
    }

    pub fn show(self: *ItemMoveWin, slotDraggedFrom: *ItemSlot) !void {
        try self.handle.show();
        self.slotDraggedFrom = slotDraggedFrom;

        _, const mx, const my = sdl3.mouse.getGlobalState();
        try self.handle.setPosition(.{ .absolute = @intFromFloat(mx - 64) }, .{ .absolute = @intFromFloat(my - 64) });
    }

    pub fn hide(self: *ItemMoveWin) !void {
        try self.handle.hide();
        self.slotDraggedFrom = null;
    }

    pub fn getId(self: ItemMoveWin) !u32 {
        return self.handle.getId();
    }

    pub fn getSlotDraggedFrom(self: ItemMoveWin) ?*ItemSlot {
        return self.slotDraggedFrom;
    }

    pub fn getDraggedItem(self: ItemMoveWin) ?sdl3.surface.Surface {
        if (self.getSlotDraggedFrom()) |slt| {
            return slt.getItem();
        }

        return null;
    }
};
