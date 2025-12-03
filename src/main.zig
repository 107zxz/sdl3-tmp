const sdl3 = @import("sdl3");
const std = @import("std");
const builtin = @import("builtin");

comptime {
    _ = sdl3.main_callbacks;
}

pub const _start = void;
pub const WinMainCRTStartup = void;

const cursor_tex = @embedFile("data/cursor.png");
const bg_tex = @embedFile("data/arch.png");

const allocator = if (builtin.os.tag != .emscripten) std.heap.smp_allocator else std.heap.c_allocator;

const AppState = struct {
    window: sdl3.video.Window,
    renderer: sdl3.render.Renderer,
    frame_capper: sdl3.extras.FramerateCapper(f32),
    game_tex: sdl3.render.Texture,

    cursor: sdl3.surface.Surface,
    bg_tex: sdl3.surface.Surface,
};

pub fn init(
    app_state: *?*AppState,
    args: [][*:0]u8,
) !sdl3.AppResult {
    _ = args;

    const state = try allocator.create(AppState);
    errdefer allocator.destroy(state);

    const window, const renderer = try sdl3.render.Renderer.initWithWindow(
        "Hello SDL3",
        640,
        640,
        .{.resizable = true},
    );
    errdefer renderer.deinit();
    errdefer window.deinit();

    const displays = try sdl3.video.getDisplays();
    defer sdl3.free(displays);

    try window.setPosition(.{.centered = displays[0]}, .{.centered = displays[0]});
    const frame_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 60 } };

    const game_tex = try sdl3.render.Texture.init(renderer, .array_rgba_32, .streaming, 128, 128);
    try game_tex.setScaleMode(.nearest);
    
    try renderer.setLogicalPresentation(128, 128, .letter_box) ;

    try sdl3.mouse.hide();

    const cursor = try sdl3.image.loadPngIo(try sdl3.io_stream.Stream.initFromConstMem(cursor_tex));
    const bg = try sdl3.image.loadPngIo(try sdl3.io_stream.Stream.initFromConstMem(bg_tex));

    state.* = .{
        .window = window,
        .renderer = renderer,
        .cursor = cursor,
        .frame_capper = frame_capper,
        .bg_tex = bg,
        .game_tex = game_tex,
    };
    app_state.* = state;

    return .run;
}

pub fn iterate(
    app_state: *AppState,
) !sdl3.AppResult {

    _ = app_state.frame_capper.delay();

    
    const mouseState = sdl3.mouse.getState();
    const wrect = try app_state.renderer.getLogicalPresentationRect();
    const mx = mouseState.@"1" - wrect.x;
    const my = mouseState.@"2" - wrect.y;

    const ww: f32 = wrect.w;
    const wh: f32 = wrect.h;
    
    try app_state.renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
    try app_state.renderer.clear();

    {
        const game_surf = try app_state.game_tex.lockToSurface(null);
        defer app_state.game_tex.unlock();

        try app_state.bg_tex.blit(null, game_surf, null);
        try app_state.cursor.blit(null, game_surf, .{.x=@intFromFloat(mx/ww*128), .y=@intFromFloat(my/wh*128)});
    }

    try app_state.renderer.renderTexture(app_state.game_tex, null, null);

    try app_state.renderer.present();
    return .run;
}

pub fn event(
    app_state: *AppState,
    curr_event: sdl3.events.Event,
) !sdl3.AppResult {
    switch (curr_event) {
        .terminating => return .success,
        .quit => return .success,
        .key_down => |key| switch (key.key.?) {
            .f => try app_state.window.setFullscreen(!app_state.window.getFlags().fullscreen),
            .escape => return .success,
            else => {}
        },
        else => {},
    }
    return .run;
}

pub fn quit(
    app_state: ?*AppState,
    result: sdl3.AppResult,
) void {
    _ = result;
    _ = app_state;
}
