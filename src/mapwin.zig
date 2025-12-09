const sdl3 = @import("sdl3");

test {
    defer sdl3.shutdown();
    try sdl3.init(.{ .video = true });
    defer sdl3.quit(.{.video=true});

    const movWin = try sdl3.video.Window.init("Movement", 128, 320, .{});
    defer movWin.deinit();
    movWin.setSurfaceVSync(.{.on_each_num_refresh = 1});

    var quit=false;
    while (!quit) {
        const surface = try movWin.getSurface();
        try surface.fillRect(null, surface.mapRgb(128, 30, 255));
        try movWin.updateSurface();
    
        // Event logic.
        while (sdl3.events.poll()) |event| switch (event) {
            .quit => quit = true,
            .terminating => quit = true,
            else => {},
        };
    }
}
