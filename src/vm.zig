const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const value_ = @import("value.zig");
const Value = value_.Value;

pub const InterpretError = error{
    Compile,
    Runtime,
};

pub const Vm = struct {
    const Self = @This();

    debug_trace_execution: bool = false,
    chunk: ?*Chunk = null,
    ip: u32 = 0,

    stack: std.ArrayList(Value),

    pub fn init(allocator: std.mem.Allocator) Self {
        return .{
            .stack = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.stack.deinit();
    }

    pub fn push(self: *Self, value: Value) !void {
        self.stack.append(value) catch return InterpretError.Runtime;
    }

    pub fn pop(self: *Self) !Value {
        const value = self.stack.popOrNull();
        if (value == null) {
            return InterpretError.Runtime;
        }

        return value.?;
    }

    fn reset_stack(self: *Self) void {
        while (self.stack.popOrNull() != null) {}
    }

    fn read_byte(self: *Self) u8 {
        const byte = self.chunk.?.code.items.ptr[self.ip];
        self.ip += 1;
        return byte;
    }

    fn read_const(self: *Self) Value {
        return self.chunk.?.constants.items.ptr[self.read_byte()];
    }

    fn read_const_long(self: *Self) Value {
        const constant = self.read_byte() |
            (@as(u16, @intCast(self.read_byte())) << 8) |
            (@as(u24, @intCast(self.read_byte())) << 16);

        return self.chunk.?.constants.items.ptr[constant];
    }

    pub fn interpret(self: *Self, chunk: *Chunk) InterpretError!void {
        self.chunk = chunk;
        self.ip = 0;
        try self.run();
    }

    fn run(self: *Self) InterpretError!void {
        while (true) {
            if (self.debug_trace_execution) {
                std.debug.print("          ", .{});
                for (self.stack.items) |value| {
                    std.debug.print("[ ", .{});
                    value_.print(value);
                    std.debug.print(" ]", .{});
                }
                std.debug.print("\n", .{});
                _ = self.chunk.?.disassemble_inst(@intCast(self.ip));
            }

            const inst = self.read_byte();
            switch (@as(Chunk.OpCode, @enumFromInt(inst))) {
                .Constant => {
                    const value = self.read_const();
                    try self.push(value);
                    value_.print(value);
                    std.debug.print("\n", .{});
                },
                .ConstantLong => {
                    const value = self.read_const_long();
                    try self.push(value);
                    value_.print(value);
                    std.debug.print("\n", .{});
                },
                .Add => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(a + b);
                },
                .Subtract => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(a - b);
                },
                .Multiply => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(a * b);
                },
                .Divide => {
                    const b = try self.pop();
                    const a = try self.pop();
                    try self.push(a / b);
                },
                .Negate => try self.push(-(try self.pop())),
                .Return => {
                    value_.print(try self.pop());
                    std.debug.print("\n", .{});
                    return;
                },
                _ => return InterpretError.Runtime,
            }
        }
    }
};
