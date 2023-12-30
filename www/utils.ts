import { RefObject } from "preact";
import { Signal } from "@preact/signals";
import { Context, Exports, Step } from "~/types.ts";

export const WIDTH = 500;
export const HEIGHT = 500;
export const DELAY = 100;
export const CELL_SIZE = 5;
export const QUANTITY = 3000;

const COLOR = "black";
const WASM_SOURCE = "/life.wasm";

let memory: WebAssembly.Memory | null = null;

const calculateCenter = <T extends "x" | "y">(
  figure: number[][],
  param: T,
): number => {
  const values = figure.map(([x, y]) => param === "x" ? x : y);
  return (Math.min(...values) + Math.max(...values)) / 2;
};

export const getCenter = (figure: number[][]): [number, number][] => {
  const centerX = Math.floor(WIDTH / CELL_SIZE / 2);
  const centerY = Math.floor(HEIGHT / CELL_SIZE / 2);
  const figureX = calculateCenter(figure, "x");
  const figureY = calculateCenter(figure, "y");

  return figure.map((
    [x, y],
  ) => [x + (centerX - figureX), y + (centerY - figureY)]);
};

export const randomFigure = (): [number, number][] =>
  Array.from({ length: QUANTITY }, () => [
    Math.floor(Math.random() * WIDTH / CELL_SIZE),
    Math.floor(Math.random() * HEIGHT / CELL_SIZE),
  ]);

export const next = (context: Signal<Context>) => {
  const steps: Step[] = [
    "START",
    "LOAD_FIGURES",
    "LOAD_WASM",
    "INIT",
    "ANIMATE",
    "END",
  ];
  const currentIndex = steps.indexOf(context.value.step);
  const nextIndex = (currentIndex + 1) % steps.length;
  context.value = { ...context.value, step: steps[nextIndex] };
};

const makeEnv = () =>
  new Proxy({
    print: (ptr: number, len: number) => {
      if (!memory) {
        return console.error(`Missing memory: 0x${ptr} -> ${len} bytes`);
      }
      const bytes = new Uint8Array(memory.buffer, ptr, len);
      console.log(
        `%c[zig]%c ${new TextDecoder().decode(bytes)}`,
        "color: rgb(236, 177, 66); font-weight: bold;",
        "color: inherit; font-weight: normal;",
      );
    },
  }, {
    get: (t, p) => {
      if (!Reflect.has(t, p)) {
        return (...args: unknown[]) => {
          console.error(`Missing export: ${String(p)}`, args);
        };
      }
      return Reflect.get(t, p);
    },
  });

function assert<
  T extends "START" | "LOAD_FIGURES" | "LOAD_WASM" | "INIT" | "ANIMATE" | "END",
>(step: Step, expected: T): asserts step is T {
  if (step !== expected) {
    throw new Error(`Expected step ${expected}, got ${step}`);
  }
}

export const initWasm = async (context: Signal<Context>) => {
  assert(context.value.step, "START");

  try {
    const response = await fetch(WASM_SOURCE);
    const buffer = await response.arrayBuffer();
    const env = makeEnv();
    const module = await WebAssembly.instantiate(buffer, { env });
    context.value.exports = module.instance.exports as Exports;
    memory = context.value.exports.memory;
    context.value.exports.init();
    next(context);
  } catch (error) {
    console.error("Failed to instantiate, have you run `zig build`?", error);
  }
};

const initFigures = async (context: Signal<Context>) => {
  assert(context.value.step, "LOAD_FIGURES");

  try {
    const response = await fetch("/patterns.json");
    const figures = await response.json() as Context["figures"];
    context.value.figures = figures;
    next(context);
  } catch (error) {
    console.error(
      "Failed to load figures, have you run `zig build parse`?",
      error,
    );
  }
};

export const initMap = (context: Signal<Context>) => {
  assert(context.value.step, "LOAD_WASM");

  if (!context.value) {
    return console.error("Couldn't load the context");
  }
  if (!context.value.canvas.current) {
    return console.error("Couldn't load the canvas");
  }

  const ctx = context.value.canvas.current.getContext("2d");
  if (!ctx) {
    return console.error("Couldn't load the canvas context");
  }

  context.value.figures[context.value.selected] = getCenter(
    context.value.figures[context.value.selected] ?? [],
  );

  context.value.figures["random"] = randomFigure();

  const item = context.value.figures[context.value.selected];

  context.value.exports.reset();
  ctx.clearRect(0, 0, WIDTH, HEIGHT);

  for (const [x, y] of item) {
    context.value.exports.set_cell(x, y, 1);
    ctx.fillStyle = COLOR;
    ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE);
  }

  next(context);
};

export const initLoop = (context: Signal<Context>) => {
  assert(context.value.step, "INIT");

  if (!context.value) {
    return console.error("Couldn't load the context");
  }
  if (!context.value.canvas.current) {
    return console.error("Couldn't load the canvas");
  }

  const ctx = context.value.canvas.current.getContext("2d");
  if (!ctx) {
    return console.error("Couldn't load the canvas context");
  }

  const animation = () => {
    context.value.exports.step();

    ctx.clearRect(0, 0, WIDTH, HEIGHT);

    const coordinates = Array.from(
      { length: WIDTH / CELL_SIZE },
      (_, x) => Array.from({ length: HEIGHT / CELL_SIZE }, (_, y) => [x, y]),
    ).flat();

    coordinates.forEach(([x, y]) => {
      if (context.value.exports.get_cell(x, y) === 0) return;
      ctx.fillStyle = COLOR;
      ctx.fillRect(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE, CELL_SIZE);
    });

    setTimeout(() => requestAnimationFrame(animation), DELAY);
  };
  if (!context.value.running) {
    context.value = {...context.value, running: true};
    requestAnimationFrame(animation);
  }
  next(context);
};

export const fnMap: { [k in Step]?: CallableFunction } = {
  START: initWasm,
  LOAD_FIGURES: initFigures,
  LOAD_WASM: initMap,
  INIT: initLoop,
};

export const init = (ref: RefObject<HTMLCanvasElement>) => ({
  step: "START",
  exports: {},
  canvas: ref,
  figures: {},
  change: false,
  running: false,
  selected: "koks_galaxy",
} as Context);
