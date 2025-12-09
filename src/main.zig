const sdl3 = @import("sdl3");
const std = @import("std");

fn htr_top(w: sdl3.video.Window, p: sdl3.rect.Point(i32), u: ?*void) sdl3.video.HitTestResult {
    _=w;
    _=u;
    return if (p.y<32) sdl3.video.HitTestResult.draggable else sdl3.video.HitTestResult.normal;
}

fn htr_all(w: sdl3.video.Window, p: sdl3.rect.Point(i32), u: ?*void) sdl3.video.HitTestResult {
    _=w;
    _=u;
    _=p;
    return sdl3.video.HitTestResult.draggable;
}

pub fn main() !void {
    defer sdl3.shutdown();

    // Initialize SDL with subsystems you need here.
    const init_flags = sdl3.InitFlags{ .video = true };
    try sdl3.init(init_flags);
    defer sdl3.quit(init_flags);

    // Initial window setup.
    const window = try sdl3.video.Window.init("Hello SDL3", 640, 480, .{.open_gl = true});
    defer window.deinit();
    try window.setPosition(.{ .centered = null }, .{ .centered = null });

    const win2 = try sdl3.video.Window.init("Director [You]", 192, 256, .{.utility = true, .borderless = true, .open_gl = true});
    defer win2.deinit();
    try win2.setPosition(.{ .absolute = 10 }, .{ .absolute = 10 });
    try win2.setHitTest(void, htr_top, null);

    // Item test
    const srfItem = try sdl3.image.loadPngIo(try sdl3.io_stream.Stream.initFromFile("src/data/screwdriver.png", .read_binary));

    const winItem = try sdl3.video.Window.init("Dummy Item", 64, 64, .{.utility = true, .borderless = true, .open_gl = true, .transparent = true});
    defer winItem.deinit();
    try winItem.setPosition(.{ .absolute = 10 }, .{ .absolute = 10 });
    try winItem.setHitTest(void, htr_all, null);

    // Useful for limiting the FPS and getting the delta time.
    var fps_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 30 } };

    var quit = false;
    while (!quit) {

        // Delay to limit the FPS, returned delta time not needed.
        const dt = fps_capper.delay();
        _ = dt;

        // Update logic.
        const surface = try window.getSurface();
        inline for ([_]sdl3.video.Window{window, win2}) |win| {
            const winSrf = try win.getSurface();
            try winSrf.fillRect(null, surface.mapRgb(128, 30, 255));
            try winSrf.fillRect(.{.x=0,.y=0,.w=192,.h=32}, surface.mapRgb(30, 128, 255));
            try win.updateSurface();
        }

        // Special Item
        const itmSef = try winItem.getSurface();
        try itmSef.fillRect(null, itmSef.mapRgba(0, 0, 0, 255));
        try srfItem.blit(null, itmSef, null);
        try winItem.updateSurface();

        // Constantly try to move back to your origin, grabbing will prevent
        try winItem.setPosition(.{ .absolute = 0 }, .{ .absolute = 0 } );

        // Event logic.
        while (sdl3.events.poll()) |event|
            switch (event) {
                .key_down => |key_ev| if (key_ev.key) |key| switch (key) {
                    .q => quit=true,
                    .escape => quit = true,
                    else => {}
                },
                .window_close_requested => quit = true,
                .quit => quit = true,
                .terminating => quit = true,
                else => {},
            };

        // const currPos = try win2.getPosition();
        // try win2.setPosition(.{.absolute = currPos.@"0"+1}, .{ .undefined = null } );
    }
}
