const sdl3 = @import("sdl3");
const std = @import("std");

const itm = @import("itm.zig");

fn htr_top(w: sdl3.video.Window, p: sdl3.rect.Point(i32), u: ?*void) sdl3.video.HitTestResult {
    _ = u;

    const ww, _ = w.getSizeInPixels() catch .{0,0};

    if (p.y > 32) {
        return .normal;
    } else if (p.x < ww - 32) {
        return .draggable;
    } else {
        return .normal;
    }
}

pub fn main() !void {
    defer sdl3.shutdown();

    // Stupid log dumy
    errdefer std.log.err("SDL ERROR: {s}\n", .{sdl3.errors.get().?});

    // Bootup log
    std.log.info("BOOTING UP!\n", .{});

    // Initialize SDL with subsystems you need here.
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    // Memory allocation
    var gpad = std.heap.DebugAllocator(.{}).init;
    defer _ = gpad.detectLeaks();

    // Initial window setup.
    const window = try sdl3.video.Window.init("Hello SDL3", 640, 480, .{ .borderless = true });
    defer window.deinit();
    try window.setPosition(.{ .centered = null }, .{ .centered = null });
    try window.setHitTest(void, htr_top, null);

    const win2 = try sdl3.video.Window.init("Director [You]", 192, 256, .{ .utility = true, .borderless = true });
    defer win2.deinit();
    try win2.setPosition(.{ .absolute = 32 }, .{ .absolute = 32 });
    try win2.setHitTest(void, htr_top, null);

    try itm.ItemMoveWin.init();
    const itemWin = itm.ItemMoveWin.get();

    // Item test
    const srfItem = try sdl3.image.loadPngIo(try sdl3.io_stream.Stream.initFromFile("src/data/screwdriver.png", .read_binary));
    const srfItem2 = try srfItem.duplicate();
    try srfItem2.setColorMod(128, 128, 255);

    // Slot test
    var slotA = itm.ItemSlot.new(72, 72, &window, srfItem);
    var slotB = itm.ItemSlot.new(72, 72, &win2, null);
    var slotC = itm.ItemSlot.new(156, 72, &window, srfItem2);
    const allSlots = [_]*itm.ItemSlot{&slotA, &slotB, &slotC};

    // Useful for limiting the FPS and getting the delta time.
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 60 } };
    var quit = false;
    while (!quit) {

        // Delay to limit the FPS, returned delta time not needed.
        const dt = fps_capper.delay();
        _ = dt;

        // Update logic.
        for ([_]sdl3.video.Window{ window, win2 }) |win| {
            const winSrf = try win.getSurface();
            try winSrf.fillRect(null, winSrf.mapRgb(128, 30, 255));
            try winSrf.fillRect(.{ .x = 0, .y = 0, .w = @intCast(winSrf.getWidth()), .h = 32 }, winSrf.mapRgb(30, 128, 255));
        }

        for (allSlots) |slt| {
            try slt.draw();
        }

        try window.updateSurface();
        try win2.updateSurface();

        try itm.ItemMoveWin.get().draw();

        // Event logic.
        while (sdl3.events.poll()) |event| {
            try itemWin.handleEvent(event);

            switch (event) {
                .key_down => |key_ev| if (key_ev.key) |key| switch (key) {
                    .q => quit = true,
                    .escape => quit = true,
                    .f => try window.setFullscreen(!window.getFlags().fullscreen),
                    else => {},
                },
                .window_close_requested => quit = true,
                .quit => quit = true,
                .terminating => quit = true,
                .mouse_button_down => |mbd| {
                    for (allSlots) |slt| {
                        if (slt.isHovered()) { // Slot clicked

                            // Special: return to current slot
                            if (slt == itemWin.getSlotDraggedFrom()) {
                                try itemWin.hide();
                            } else if (slt.hasItem()) {

                                // Special: block if slot full
                                if (itemWin.getDraggedItem() != null) {
                                    const heldItem = itemWin.getDraggedItem().?;
                                    itemWin.getSlotDraggedFrom().?.putItem(slt.getItem().?);

                                    slt.putItem(heldItem);
                                    //break;
                                } else {
                                    try itemWin.show(slt);
                                }
                            } else if (mbd.window_id == try itemWin.getId()) {
                                // Drop item!
                                slt.putItem(itemWin.getDraggedItem().?);
                                itemWin.getSlotDraggedFrom().?.putItem(null);

                                try slt.getWindow().raise();

                                try itemWin.hide();
                            }

                            break;
                        }
                    } else {
                        // If background clicked return item
                        //try itemWin.getSlotDraggedFrom().?.getWindow().raise();
                        try itemWin.hide();
                    }
                },
                else => {},
            }
        }
    }
}
