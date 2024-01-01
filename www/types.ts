import { RefObject } from "preact";

type Cell = 0 | 1;

export type Step =
  | "START"
  | "LOAD_FIGURES"
  | "LOAD_WASM"
  | "INIT"
  | "ANIMATE"
  | "END";

export type Exports = {
  memory: WebAssembly.Memory;
  get_neighbours: (x: number, y: number) => number;
  step: () => number;
  set_cell: (x: number, y: number, value: Cell) => void;
  get_cell: (x: number, y: number) => Cell;
  init: () => void;
  reset: () => void;
} & { [k: string]: CallableFunction };

type Figures = {
  [name: string]: [number, number][];
};

export type Context = {
  step: Step;
  exports: Exports;
  selected: string;
  figures: Figures;
  change: boolean;
  pause: boolean;
  running: boolean;
  canvas: RefObject<HTMLCanvasElement>;
};
