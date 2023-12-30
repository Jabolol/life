import { Context } from "~/types.ts";
import { Signal, useComputed } from "@preact/signals";
import { sort } from "$std/semver/sort.ts";

type MenuProps = {
  context: Signal<Context>;
};

export default function Menu({ context }: MenuProps) {
  const keys = useComputed(() => Object.keys(context.value.figures));

  return (
    <div class="w-full flex items-center justify-end">
      <select
        onChange={(evt) => {
          context.value = {
            ...context.value,
            step: "LOAD_WASM",
            change: true,
            selected: evt.currentTarget.value,
          };
        }}
        name="pattern"
        class="border-4 border-black rounded-lg py-2 max-w-[25%] w-full"
      >
        {keys.value.length
          ? (
            Object.keys(context.value.figures)
              .sort((a, b) =>
                a.toLowerCase().charCodeAt(0) - b.toLowerCase().charCodeAt(0)
              ).map((key) => (
                <option value={key} selected={context.value.selected === key}>
                  {key}
                </option>
              ))
          )
          : (
            <option
              value="loading"
              class="border-4 border-black rounded-lg py-2 max-w-[25%] w-full"
              disabled
              selected
            >
              loading..
            </option>
          )}
      </select>
    </div>
  );
}
