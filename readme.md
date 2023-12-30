# life

A [Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life)
implementation in `Zig` and `WebAssembly`.

## installation

Make sure you have both [`Zig`](https://ziglang.org/) and
[`Deno`](https://deno.com) installed and on your `$PATH`.

1. Clone the repository

```bash
git clone https://github.com/Jabolol/life.git .
```

2. Build the `WebAssembly` file and
   [`patterns.json`](./www/static/patterns.json) file using `zig`.

```bash
zig build
```

3. Navigate to the [`www/`](./www/) directory and start the website.

```bash
cd www && deno task start
```

## custom patterns

Custom patterns consist of files in the [`assets/`](./assets/) directory. The
format of these files is as follows:

```txt
0 0 0 0 0 0
0 0 1 1 0 0
0 1 0 0 1 0
0 0 1 1 0 0
0 0 0 0 0 0
```

Where `0` is a dead cell and `1` is a live cell. There is a space between each
cell and a newline between each row.

Every time you change a file in the [`assets/`](./assets/) directory, you need
to rebuild the [`patterns.json`](./www/static/patterns.json) file using `zig`.
The pattern is automatically centered on the canvas.

```bash
zig build
```

## contributing

Contributions are welcome. Please open an issue or a pull request. Please run
the following commands before opening a pull request, and ensure that they all
pass.

```bash
# zig specific commands
zig fmt src
zig fmt www/static/patterns.json
zig test src/main.zig
zig test src/pattern.zig
zig build

# deno specific commands
deno fmt www
deno lint www
```

## license

This project is licensed under the [MIT License](./LICENSE).
