import { Context } from "~/types.ts";
import { Signal, useComputed } from "@preact/signals";
import IconRepeat from "icons/repeat.tsx";
import IconPause from "icons/player-pause.tsx";
import IconPlayerPlay from "icons/player-play.tsx";

type MenuProps = {
  context: Signal<Context>;
};

export default function Menu({ context }: MenuProps) {
  const playing = useComputed(() => context.value.running);
  const keys = useComputed(() => Object.keys(context.value.figures));

  const execute = (selected: string) => {
    context.value = {
      ...context.value,
      step: "LOAD_WASM",
      pause: false,
      change: true,
      selected,
    };
  };

  const toggle = (pause: boolean) => {
    context.value = {
      ...context.value,
      step: pause ? "END" : "LOAD_WASM",
      pause: true,
      change: true,
      running: false,
    };
  };

  return (
    <div class="w-full flex items-center justify-end gap-2">
      {playing.value
        ? (
          <IconPause
            onClick={() => toggle(true)}
            class="hover:cursor-pointer border-4 border-black rounded-lg h-12 w-[25%]"
          />
        )
        : (
          <IconPlayerPlay
            onClick={() => toggle(false)}
            class="hover:cursor-pointer border-4 border-black rounded-lg h-12 w-[25%]"
          />
        )}
      <IconRepeat
        onClick={() => execute(context.value.selected)}
        class="hover:cursor-pointer border-4 border-black rounded-lg h-12 w-[25%]"
      />
      <select
        onChange={({ currentTarget: { value } }) => execute(value)}
        name="pattern"
        class="hover:cursor-pointer focus:outline-none border-4 border-black rounded-lg py-2 w-[50%] h-12"
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
              class="border-4 border-black rounded-lg py-2 max-w-[50%] w-full"
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
