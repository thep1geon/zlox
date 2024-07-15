const std = @import("std");
const value_mod = @import("value.zig");
const Value = value_mod.Value;

pub const Chunk = struct {
    pub const OpCode = enum(u8) {
        Constant,
        ConstantLong,
        Add,
        Subtract,
        Multiply,
        Divide,
        Negate,
        Return,
        _,
    };

    const Self = @This();

    code: std.ArrayList(u8),
    lines: std.ArrayList(i32),
    constants: std.ArrayList(Value),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .code = std.ArrayList(u8).init(allocator),
            .lines = std.ArrayList(i32).init(allocator),
            .constants = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.code.deinit();
        self.lines.deinit();
        self.constants.deinit();
    }

    pub fn write_opcode(self: *Self, opcode: OpCode, line: i32) !void {
        try self.write_byte(@intFromEnum(opcode), line);
    }

    pub fn write_byte(self: *Self, byte: u8, line: i32) !void {
        try self.code.append(byte);
        try self.lines.append(line);
    }

    pub fn write_const(self: *Self, value: Value, line: i32) !void {
        const constant: u8 = @intCast(try self.add_const(value));
        try self.write_opcode(OpCode.Constant, line);
        try self.write_byte(constant, line);
        try self.lines.append(line);
    }

    pub fn write_const_long(self: *Self, value: Value, line: i32) !void {
        const const_index: u24 = @intCast(try self.add_const(value));
        try self.write_byte(@intFromEnum(OpCode.ConstantLong), line);
        try self.write_byte(@truncate(const_index >> 0), line);
        try self.write_byte(@truncate(const_index >> 8 & 0xff), line);
        try self.write_byte(@truncate(const_index >> 16 & 0xff), line);
        try self.lines.append(line);
    }

    pub fn add_const(self: *Self, value: Value) !usize {
        try self.constants.append(value);
        return self.constants.items.len - 1;
    }

    pub fn disassemble(self: *const Self, name: []const u8) void {
        std.debug.print("== {s} ==\n", .{name});

        var offset: usize = 0;
        while (offset < self.code.items.len) {
            offset = self.disassemble_inst(offset);
        }
    }

    pub fn disassemble_inst(self: *const Self, offset: usize) usize {
        std.debug.print("0x{X:0>4}  ", .{offset});
        if (offset > 0 and self.lines.items.ptr[offset] == self.lines.items.ptr[offset - 1]) {
            std.debug.print("   |  ", .{});
        } else {
            std.debug.print("{d:0>4}  ", .{self.lines.items.ptr[offset]});
        }
        defer std.debug.print("\n", .{});
        const inst: OpCode = @enumFromInt(self.code.items.ptr[offset]);
        switch (inst) {
            .Constant => {
                const constant = self.code.items.ptr[offset + 1];
                std.debug.print("{s: <16} {d:0>4} '", .{ "CONSTANT", constant });
                value_mod.print(self.constants.items.ptr[constant]);
                std.debug.print("'", .{});
                return offset + 2;
            },
            .ConstantLong => {
                const constant = (self.code.items.ptr[offset + 1] << 0) |
                    (@as(u16, @intCast(self.code.items.ptr[offset + 2])) << 8) |
                    (@as(u24, @intCast(self.code.items.ptr[offset + 3])) << 16);
                std.debug.print("{s: <16} {d:0>4} '", .{ "CONSTANT_LONG", constant });
                value_mod.print(self.constants.items.ptr[constant]);
                std.debug.print("'", .{});
                return offset + 4;
            },
            .Add => {
                std.debug.print("ADD", .{});
                return offset + 1;
            },
            .Subtract => {
                std.debug.print("SUBTRACT", .{});
                return offset + 1;
            },
            .Multiply => {
                std.debug.print("MULTIPLY", .{});
                return offset + 1;
            },
            .Divide => {
                std.debug.print("DIVIDE", .{});
                return offset + 1;
            },
            .Negate => {
                std.debug.print("NEGATE", .{});
                return offset + 1;
            },
            .Return => {
                std.debug.print("RETURN", .{});
                return offset + 1;
            },
            _ => {
                std.debug.print("{}", .{self.code.items.ptr[offset]});
                return offset + 1;
            },
        }
        return offset + 1;
    }
};
