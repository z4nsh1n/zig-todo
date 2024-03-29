const std = @import("std");
const args = @import("parseargs.zig");

const Todo = struct {
    title: []const u8,
    done: bool = false,
};

var alloc: std.mem.Allocator = undefined;

pub fn main() !void {
    var gps = std.heap.GeneralPurposeAllocator(.{}){};
    //defer _ = gps.deinit();
    const stdout = std.io.getStdOut().writer();
    alloc = gps.allocator();

    // TODO arraylists
    var todos = std.ArrayList(Todo).init(alloc);
    var done = std.ArrayList(Todo).init(alloc);
    defer todos.deinit();
    defer done.deinit();

    // Open todo file
    const todo_file = "todos.txt";

    const file = std.fs.cwd().openFile(todo_file, std.fs.File.OpenFlags{ .mode = .read_write });
    if (file) |f| {
        //defer open_file.close();
        const todo_text = try f.readToEndAlloc(alloc, 1024 * 1024);
        var iter = std.mem.splitScalar(u8, todo_text, '\n');
        // var iter = std.mem.split(u8, todo_text, "\n");
        while (iter.next()) |todo| {
            if (!std.mem.eql(u8, todo, "")) {
                var iter2 = std.mem.split(u8, todo, "->");
                const title = iter2.next() orelse "no title";
                const d = iter2.rest();
                if (std.mem.eql(u8, d, "false")) {
                    try todos.append(Todo{ .done = false, .title = title });
                } else {
                    try todos.append(Todo{ .done = true, .title = title });
                }
            }
        }
        defer f.close();
    } else |err| {
        std.debug.print("Error: {}\nNo \"todos.txt\" file yet\n", .{err});
    }

    // Parse args
    var argp = args.CmdArgs(){};
    argp.init(alloc);
    defer argp.deinit();

    const cmds: std.ArrayList(args.Cmd) = try argp.parse();
    for (cmds.items) |cmd| {
        switch (cmd) {
            args.CmdType.todo => |todo| try todos.append(Todo{ .done = false, .title = todo }),
            args.CmdType.done => |index| todos.items[index - 1].done = true,
            args.CmdType.del => |index| _ = todos.orderedRemove(index - 1),
            args.CmdType.toggle => |index| todos.items[index - 1].done = !todos.items[index - 1].done,
            args.CmdType.list => {
                try std.fmt.format(stdout, "\x1b[2J\x1b[H", .{});
                for (todos.items, 1..) |todo, idx| {
                    if (todo.done) {
                        try std.fmt.format(stdout, "\x1b[38;2;0;255;0m", .{});
                        try std.fmt.format(stdout, "({})[X] {s}\n", .{ idx, todo.title });
                        try std.fmt.format(stdout, "\x1b[0m", .{});
                    } else {
                        try std.fmt.format(stdout, "({})[ ] {s}\n", .{ idx, todo.title });
                    }
                }
            },
        }
    }

    var wfile = try std.fs.cwd().createFile(todo_file, .{});
    const wwriter = wfile.writer();
    for (todos.items) |todo| {
        try std.fmt.format(wwriter, "{s}->{}\n", .{ todo.title, todo.done });
    }
    wfile.close();
}
