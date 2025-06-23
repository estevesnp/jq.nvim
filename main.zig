const std = @import("std");

const Person = struct {
    first_name: []const u8,
    last_name: []const u8,
    age: u8,
};

pub fn main() !void {
    const gpa = std.heap.smp_allocator;

    var people: std.ArrayListUnmanaged(Person) = .empty;
    defer people.deinit(gpa);

    for (0..256) |idx| {
        const first_name = if (idx % 2 == 0) if (idx % 3 == 0) "Chico" else "Ricardo" else "João";
        const last_name = if (idx % 2 == 0) if (idx % 5 == 0) "Fininho" else "Lopes" else "Ferreira";

        try people.append(gpa, .{ .first_name = first_name, .last_name = last_name, .age = @intCast(idx) });
    }

    try std.json.stringify(people.items, .{ .whitespace = .indent_2 }, std.io.getStdOut().writer());
}
