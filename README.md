# zig-yaml

YAML parser for Zig

## What is it?

This lib is meant to serve as a basic (or maybe not?) YAML parser for Zig. It will strive to be YAML 1.2 compatible
but one step at a time.

This is very much a work-in-progress, so expect things to break on a regular basis. Oh, I'd love to get the
community involved in helping out with this btw! Feel free to fork and submit patches/enhancements, and of course
issues.

## Basic usage

The parser currently understands a few YAML primitives such as:
* explicit documents (`---`, `...`)
* mappings (`:`)
* sequences (`-`)

In fact, if you head over to `examples/` dir, you will find YAML examples that have been tested against this
parser. This reminds me to add a TODO to convert `examples/` into end-to-end tests!

If you want to use the parser as a library, add it as a package the usual way, and then:

```zig
const std = @import("std");
const yaml = @import("yaml");

const source =
  \\ints:
  \\- 0
  \\- 1
  \\- 2
  ;

pub fn main() !void {
  var decoder = yaml.Yaml.init(std.testing.allocator);
  defer decoder.deinit();

  try decoder.load(source);
  
  try std.testing.expectEqual(decoder.docs.items.len, 1);

  const list = decoder.docs.items[0].list;
  try std.testing.expectEqual(list.len, 3);

  try std.testing.expect(std.mem.eql(u8, "0", list[0].string));
  try std.testing.expect(std.mem.eql(u8, "1", list[1].string));
  try std.testing.expect(std.mem.eql(u8, "2", list[2].string));
}
```
