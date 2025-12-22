const sdl3 = @import("sdl3");
const std = @import("std");

const itm = @import("itm.zig");

fn htr_top(w: sdl3.video.Window, p: sdl3.rect.Point(i32), u: ?*void) sdl3.video.HitTestResult {
    _ = w;
    _ = u;
    return if (p.y < 32) sdl3.video.HitTestResult.draggable else sdl3.video.HitTestResult.normal;
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
    //const gpa = gpad.allocator();

    // Grab game storage
    //const strg = try sdl3.storage.Storage.initUser("amyhasnumbers", "draggame", sdl3.properties.Group{ .value = 0 });

    //const |mm| sensitivity = sns: {
    //if (strg.getPathExists("sensitivity")) {} else {
    //try strg.writeFile("sensitivity", "0.5");
    //}
    //const sensBuff = try gpa.alloc(u8, try strg.getFileSize("sensitivity"));
    //defer gpa.free(sensBuff);
    //
    //strg.readFile("sensitivity", sensBuff) catch {
    //try sdl3.log.log("Error loading options: {s}", .{sdl3.errors.get().?});
    //};
    //
    //break :sns try std.fmt.parseFloat(f32, sensBuff);
    //};

    // Initial window setup.
    const window = try sdl3.video.Window.init("Hello SDL3", 640, 480, .{ .borderless = true });
    defer window.deinit();
    try window.setPosition(.{ .centered = null }, .{ .centered = null });
    try window.setHitTest(void, htr_top, null);

    const win2 = try sdl3.video.Window.init("Director [You]", 192, 256, .{ .utility = true, .borderless = true });
    defer win2.deinit();
    try win2.setPosition(.{ .absolute = 32 }, .{ .absolute = 32 });
    try win2.setHitTest(void, htr_top, null);

    // Item test
    const srfItem = try sdl3.image.loadPngIo(try sdl3.io_stream.Stream.initFromFile("src/data/screwdriver.png", .read_binary));
    var itemWin = try itm.ItemMoveWin.init();

    // Slot test
    const slotA = itm.ItemSlot.new(72, 72, &window, srfItem);

    // Useful for limiting the FPS and getting the delta time.
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 60 } };
    var quit = false;
    while (!quit) {

        // Delay to limit the FPS, returned delta time not needed.
        const dt = fps_capper.delay();
        _ = dt;

        // Update logic.
        inline for ([_]sdl3.video.Window{ window, win2 }) |win| {
            const winSrf = try win.getSurface();
            try winSrf.fillRect(null, winSrf.mapRgb(128, 30, 255));
            try winSrf.fillRect(.{ .x = 0, .y = 0, .w = @intCast(winSrf.getWidth()), .h = 32 }, winSrf.mapRgb(30, 128, 255));
        }

        try slotA.draw(!itemWin.visible());

        try window.updateSurface();
        try win2.updateSurface();

        try itemWin.draw();

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
                .mouse_button_down => |mbd| if (slotA.isHovered() and mbd.window_id.? != try itemWin.getId()) try itemWin.show(srfItem),
                else => {},
            }
        }
    }
}
