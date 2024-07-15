const std = @import("std");
const Chunk = @import("chunk.zig").Chunk;
const OpCode = Chunk.OpCode;
const Vm = @import("vm.zig").Vm;

pub fn main() !void {
    // Allocator setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    // Freeing all the allocator stuff
    defer {
        arena.deinit();

        const deinit_status = gpa.deinit();

        if (deinit_status == .leak) {
            std.log.err("{}", .{gpa.detectLeaks()});
        }
    }

    var chunk = Chunk.init(allocator);

    try chunk.write_const(1.2, 123);
    try chunk.write_const(3.4, 123);
    try chunk.write_opcode(OpCode.Add, 123);
    try chunk.write_const(5.6, 123);
    try chunk.write_opcode(OpCode.Divide, 123);
    try chunk.write_opcode(OpCode.Negate, 123);
    try chunk.write_opcode(OpCode.Return, 123);

    var vm = Vm.init(allocator);
    defer vm.deinit();
    // vm.debug_trace_execution = true;
    try vm.interpret(&chunk);
}
