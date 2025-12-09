const std = @import("std");

const Character = struct {
    name: []const u8,
    say_hi: []const []const u8
};

const characters: []const Character = @import("characters.zon");

test "Test Making and retrieving character data" {
    try std.testing.expectEqualStrings("Hello, World!", characters[0].name);
    try std.testing.expectEqualStrings("Damn", characters[0].say_hi[0]);

    try std.testing.expect(std.mem.eql(u8, characters[0].name, "Hello, World!"));

    // Really no point in doing this as a queue
    const dlgIdx = 0;
    try std.testing.expectEqualStrings("Damn", characters[0].say_hi[dlgIdx]);
}
