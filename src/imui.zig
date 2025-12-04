const sdl3 = @import("sdl3");

pub fn IM_Button(renderer: sdl3.render.Renderer, text_renderer: sdl3.ttf.RendererTextEngine, font: sdl3.ttf.Font, x: f32, y: f32, text: []const u8) !bool {
    const c_mouse_state = struct {
        var last_pressed = false;
    };
    
    const btn_rect = sdl3.rect.FRect{.x=x,.y=y,.w=@floatFromInt(text.len*4+1),.h=7};
    const mouse_btns, const mouse_x, const mouse_y = sdl3.mouse.getState();

    const logical_rect = try renderer.getLogicalPresentation();
    const tru_rect = try renderer.getOutputSize();

    const mpt = sdl3.rect.FPoint{
        .x=mouse_x*@as(f32,@floatFromInt(logical_rect.@"0"))/@as(f32,@floatFromInt(tru_rect.@"0")),
        .y=mouse_y*@as(f32,@floatFromInt(logical_rect.@"1"))/@as(f32,@floatFromInt(tru_rect.@"1")),
    };
    const in_rect = btn_rect.pointIn(mpt);
    const valid_click=mouse_btns.left and !c_mouse_state.last_pressed;

    // Text
    const text_obj = try sdl3.ttf.Text.init(.{.value=text_renderer.value}, font, text);

    // Render button
    if (in_rect) {
        if (valid_click) {
            try renderer.setDrawColor(.{.r=255,.g=255,.b=255,.a=255});
        } else {
            try renderer.setDrawColor(.{.r=0,.g=255,.b=255,.a=255});
        }
    } else {
        try renderer.setDrawColor(.{.r=0,.g=0,.b=255,.a=255});
    }
    try renderer.renderFillRect(btn_rect);

    try sdl3.ttf.drawRendererText(text_obj, x+1, y);

    c_mouse_state.last_pressed=mouse_btns.left;
    return in_rect and valid_click;
}
