const std = @import("std");
const mem = std.mem;
const testing = std.testing;

const Allocator = mem.Allocator;
const Yaml = @import("yaml").Yaml;

const gpa = testing.allocator;

fn testYaml(file_path: []const u8, comptime T: type, eql: fn (T, T) bool, expected: T) !void {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const source = try file.readToEndAlloc(gpa, std.math.maxInt(u32));
    defer gpa.free(source);

    var parsed = try Yaml.load(gpa, source);
    defer parsed.deinit();

    const result = try parsed.parse(T);
    try testing.expect(eql(expected, result));
}

test "simple" {
    const Simple = struct {
        names: []const []const u8,
        numbers: []const i16,
        nested: struct {
            some: []const u8,
            wick: []const u8,
        },
        finally: [4]f16,

        pub fn eql(self: @This(), other: @This()) bool {
            if (self.names.len != other.names.len) return false;
            if (self.numbers.len != other.numbers.len) return false;
            if (self.finally.len != other.finally.len) return false;

            for (self.names) |lhs, i| {
                if (!mem.eql(u8, lhs, other.names[i])) return false;
            }

            for (self.numbers) |lhs, i| {
                if (lhs != other.numbers[i]) return false;
            }

            for (self.finally) |lhs, i| {
                if (lhs != other.finally[i]) return false;
            }

            if (!mem.eql(u8, self.nested.some, other.nested.some)) return false;
            if (!mem.eql(u8, self.nested.wick, other.nested.wick)) return false;

            return true;
        }
    };

    try testYaml("test/simple.yaml", Simple, Simple.eql, .{
        .names = &[_][]const u8{ "John Doe", "MacIntosh", "Jane Austin" },
        .numbers = &[_]i16{ 10, -8, 6 },
        .nested = .{
            .some = "one",
            .wick = "john doe",
        },
        .finally = [_]f16{ 8.17, 19.78, 17, 21 },
    });
}

const LibTbd = struct {
    tbd_version: u3,
    targets: []const []const u8,
    uuids: []const struct {
        target: []const u8,
        value: []const u8,
    },
    install_name: []const u8,
    current_version: []const u8,
    reexported_libraries: []const struct {
        targets: []const []const u8,
        libraries: []const []const u8,
    },

    pub fn eql(self: LibTbd, other: LibTbd) bool {
        if (self.tbd_version != other.tbd_version) return false;
        if (self.targets.len != other.targets.len) return false;

        for (self.targets) |target, i| {
            if (!mem.eql(u8, target, other.targets[i])) return false;
        }

        if (!mem.eql(u8, self.install_name, other.install_name)) return false;
        if (!mem.eql(u8, self.current_version, other.current_version)) return false;
        if (self.reexported_libraries.len != other.reexported_libraries.len) return false;

        for (self.reexported_libraries) |reexport, i| {
            const o_reexport = other.reexported_libraries[i];
            if (reexport.targets.len != o_reexport.targets.len) return false;
            if (reexport.libraries.len != o_reexport.libraries.len) return false;

            for (reexport.targets) |target, j| {
                const o_target = o_reexport.targets[j];
                if (!mem.eql(u8, target, o_target)) return false;
            }

            for (reexport.libraries) |library, j| {
                const o_library = o_reexport.libraries[j];
                if (!mem.eql(u8, library, o_library)) return false;
            }
        }

        return true;
    }
};

test "single lib tbd" {
    try testYaml("test/single_lib.tbd", LibTbd, LibTbd.eql, .{
        .tbd_version = 4,
        .targets = &[_][]const u8{
            "x86_64-macos",
            "x86_64-maccatalyst",
            "arm64-macos",
            "arm64-maccatalyst",
            "arm64e-macos",
            "arm64e-maccatalyst",
        },
        .uuids = &.{
            .{ .target = "x86_64-macos", .value = "F86CC732-D5E4-30B5-AA7D-167DF5EC2708" },
            .{ .target = "x86_64-maccatalyst", .value = "F86CC732-D5E4-30B5-AA7D-167DF5EC2708" },
            .{ .target = "arm64-macos", .value = "00000000-0000-0000-0000-000000000000" },
            .{ .target = "arm64-maccatalyst", .value = "00000000-0000-0000-0000-000000000000" },
            .{ .target = "arm64e-macos", .value = "A17E8744-051E-356E-8619-66F2A6E89AD4" },
            .{ .target = "arm64e-maccatalyst", .value = "A17E8744-051E-356E-8619-66F2A6E89AD4" },
        },
        .install_name = "/usr/lib/libSystem.B.dylib",
        .current_version = "1292.60.1",
        .reexported_libraries = &.{
            .{
                .targets = &.{
                    "x86_64-macos",
                    "x86_64-maccatalyst",
                    "arm64-macos",
                    "arm64-maccatalyst",
                    "arm64e-macos",
                    "arm64e-maccatalyst",
                },
                .libraries = &.{
                    "/usr/lib/system/libcache.dylib",       "/usr/lib/system/libcommonCrypto.dylib",
                    "/usr/lib/system/libcompiler_rt.dylib", "/usr/lib/system/libcopyfile.dylib",
                    "/usr/lib/system/libxpc.dylib",
                },
            },
        },
    });
}
