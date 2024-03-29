const std = @import("std");

pub const CmdType = enum { todo, list, done, toggle, del };
pub const Cmd = union(CmdType) {
    todo: []const u8,
    list: void,
    done: u32,
    toggle: u32,
    del: u32,
    //swap: .{ u32, u32 },
};
pub fn CmdArgs() type {
    return struct {
        allocator: std.mem.Allocator = undefined,
        args: std.process.ArgIterator = undefined,
        cmdlist: std.ArrayList(Cmd) = undefined,

        pub fn init(self: *CmdArgs(), allocator: std.mem.Allocator) void {
            self.allocator = allocator;
            self.cmdlist = std.ArrayList(Cmd).init(allocator);
            self.args = try std.process.ArgIterator.initWithAllocator(allocator);
            _ = self.args.skip(); // skip prog name
        }

        pub fn deinit(self: *CmdArgs()) void {
            self.cmdlist.deinit();
        }

        pub fn parse(self: *CmdArgs()) !std.ArrayList(Cmd) {
            if (self.args.next()) |cmd| {
                if (std.mem.eql(u8, cmd, "todo")) {
                    var task: []u8 = "";
                    while (self.args.next()) |str| {
                        if (std.mem.eql(u8, task, "")) {
                            task = try std.mem.concat(self.allocator, u8, &[_][]const u8{ task, str });
                        } else {
                            task = try std.mem.concat(self.allocator, u8, &[_][]const u8{ task, " ", str });
                        }
                    }
                    try self.cmdlist.append(Cmd{ .todo = task });
                } else if (std.mem.eql(u8, cmd, "list")) {
                    try self.cmdlist.append(Cmd{ .list = {} });
                } else if (std.mem.eql(u8, cmd, "done")) {
                    const idx = self.args.next() orelse "0";
                    try self.cmdlist.append(Cmd{ .done = try std.fmt.parseInt(u32, idx, 10) });
                } else if (std.mem.eql(u8, cmd, "toggle")) {
                    const idx = self.args.next() orelse "0";
                    try self.cmdlist.append(Cmd{ .toggle = try std.fmt.parseInt(u32, idx, 10) });
                } else if (std.mem.eql(u8, cmd, "del")) {
                    const idx = self.args.next() orelse "0";
                    try self.cmdlist.append(Cmd{ .del = try std.fmt.parseInt(u32, idx, 10) });
                } else {
                    std.debug.print("Unknow command!!!", .{});
                    unreachable;
                }
            }
            return self.cmdlist;
        }
    };
}
