const sdl3 = @import("sdl3");
const std = @import("std");

fn htr_top(w: sdl3.video.Window, p: sdl3.rect.Point(i32), u: ?*void) sdl3.video.HitTestResult {
    _ = w;
    _ = u;
    return if (p.y < 32) sdl3.video.HitTestResult.draggable else sdl3.video.HitTestResult.normal;
}

pub fn main() !void {
    defer sdl3.shutdown();

    // Stupid log dumy
    errdefer std.debug.print("SDL ERROR: {s}\n", .{sdl3.errors.get().?});

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

    // Read setty-cmd{"ok": false, "error": "Remote control is disabled"}nsitivity
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
    const window = try sdl3.video.Window.init("Hello SDL3", 640, 480, .{ .open_gl = true });
    defer window.deinit();
    try window.setPosition(.{ .centered = null }, .{ .centered = null });

    const win2 = try sdl3.video.Window.init("Director [You]", 192, 256, .{ .utility = true, .borderless = true });
    defer win2.deinit();
    try win2.setPosition(.{ .absolute = 10 }, .{ .absolute = 10 });
    try win2.setHitTest(void, htr_top, null);

    // Item test
    const srfItem = try sdl3.image.loadPngIo(try sdl3.io_stream.Stream.initFromFile("src/data/screwdriver.png", .read_binary));

    const winItem = try sdl3.video.Window.init("Dummy Item", 128, 128, .{ .utility = true, .borderless = true, .transparent = true, .always_on_top = true });
    defer winItem.deinit();
    //try winItem.setShape(srfItem);
    try winItem.hide();
    //try winItem.setPosition(.{ .absolute = 10 }, .{ .absolute = 10 });

    // Gamestate???
    var itemPos: [2]isize = .{ 32, 32 };
    var dropping = true;

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
            try winSrf.fillRect(.{ .x = 0, .y = 0, .w = 192, .h = 32 }, winSrf.mapRgb(30, 128, 255));

            if (winItem.getFlags().hidden) {
                const iwx, const iwy = itemPos;
                const wwx, const wwy = try win.getPosition();
                try srfItem.blit(null, winSrf, .{ .x = @intCast(iwx - wwx + 32), .y = @intCast(iwy - wwy + 32) });
            }

            try win.updateSurface();
        }

        // Special Item (maybe limit updates for this window HEAVILY)
        const itmSef = try winItem.getSurface();
        try itmSef.fillRect(null, itmSef.mapRgba(0, 0, 0, 0));
        try srfItem.blit(null, itmSef, .{.x=32,.y=32});
        try winItem.updateSurface();

        // Event logic.
        while (sdl3.events.poll()) |event|
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
                .mouse_motion => if (!dropping) {
                    // const wx, const wy = try winItem.getPosition();
                    _, const mx, const my = sdl3.mouse.getGlobalState();                    //try winItem.setPosition(.{ .absolute = @intFromFloat(mm.x_rel * sensitivity + @as(f32, @floatFromInt(wx))) }, .{ .absolute = @intFromFloat(mm.y_rel * sensitivity + @as(f32, @floatFromInt(wy))) });
                    try winItem.setPosition(.{ .absolute = @intFromFloat(mx-64) } , .{ .absolute = @intFromFloat(my-64) } );
                },
                .window_moved => {
                    //const wix, const wiy = try winItem.getPosition();
                    //winItem.setPosition(.{ .absolute =  } )
                },
                .mouse_button_down => {
                    // const dropping = sdl3.mouse.getWindowRelativeMode(winItem);


                    _, const mx, const my = sdl3.mouse.getGlobalState();
                    // try sdl3.mouse.setWindowRelativeMode(winItem, !dropping);

                    dropping = !dropping;

                    // Drop
                    if (dropping) {
                        itemPos = try winItem.getPosition();
                        //sdl3.mouse.warpInWindow(winItem, 32, 32);

                        try winItem.hide();

                        try window.raise();
                    } else {
                        try winItem.setPosition(.{ .absolute = @intFromFloat(mx-64) } , .{ .absolute = @intFromFloat(my-64) } );
                        try winItem.show();
                    }
                },
                .window_focus_lost => |w| if (w.id == try winItem.getId()) try winItem.hide(),
                else => {},
            };
    }
}
