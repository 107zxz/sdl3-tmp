const sdl3 = @import("sdl3");
const std = @import("std");
const builtin = @import("builtin");

comptime {
    _ = sdl3.main_callbacks;
}

const window_width = 640;
const window_height = 480;

pub const _start = void;
pub const WinMainCRTStartup = void;

const cursor_tex = @embedFile("data/cursor.png");
const bg_tex = @embedFile("data/arch.png");

const allocator = if (builtin.os.tag != .emscripten) std.heap.smp_allocator else std.heap.c_allocator;

const AppState = struct {
    window: sdl3.video.Window,
    renderer: sdl3.render.Renderer,
    frame_capper: sdl3.extras.FramerateCapper(f32),

    cursor: sdl3.render.Texture,
    bg_tex: sdl3.render.Texture,
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
        window_width,
        window_height,
        .{.resizable = true,},
    );
    errdefer renderer.deinit();
    errdefer window.deinit();

    const frame_capper = sdl3.extras.FramerateCapper(f32){ .mode = .{ .limited = 60 } };
    
    try renderer.setLogicalPresentation(128, 128, .letter_box) ;

    try sdl3.mouse.hide();

    const cursor = try sdl3.image.loadTextureIo(
        renderer,
        try sdl3.io_stream.Stream.initFromConstMem(cursor_tex),
        true
    );
    try cursor.setScaleMode(.nearest);

    const bg = try sdl3.image.loadTextureIo(
        renderer,
        try sdl3.io_stream.Stream.initFromConstMem(bg_tex),
        true
    );
    try bg.setScaleMode(.nearest);

    state.* = .{
        .window = window,
        .renderer = renderer,
        .cursor = cursor,
        .frame_capper = frame_capper,
        .bg_tex = bg
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

    const wx: f32 = wrect.w;
    const wy: f32 = wrect.h;
    
    try app_state.renderer.setDrawColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
    try app_state.renderer.clear();

    try app_state.renderer.renderTexture(app_state.bg_tex, null, null);

    // try app_state.renderer.renderDebugText(.{.x=@round(mx/wx*128),.y=@round(my/wy*128)}, "Mouse X: ");

    // Cool way to do gradients, hopefully find a way to do this better
    // try app_state.renderer.renderGeometry(app_state.bg_tex, &[_]sdl3.render.Vertex{
        // .{.position=.{.x=0,.y=0},.color=.{.r=1,.g=1,.b=1,.a=1},.tex_coord=.{.x=0,.y=0}},
        // .{.position=.{.x=128,.y=0},.color=.{.r=1,.g=1,.b=1,.a=1},.tex_coord=.{.x=1,.y=0}},
        // .{.position=.{.x=128,.y=128},.color=.{.r=0,.g=0,.b=0,.a=1},.tex_coord=.{.x=1,.y=1}},
        // .{.position=.{.x=0,.y=128},.color=.{.r=0,.g=0,.b=0,.a=1},.tex_coord=.{.x=0,.y=1}},
    // }, &[_]c_int{
        // 0,1,2,
        // 0,2,3
    // });

    try app_state.renderer.renderTexture(app_state.cursor, null, .{.x=@round(mx/wx*128),.y=@round(my/wy*128),.w=8,.h=8});

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
