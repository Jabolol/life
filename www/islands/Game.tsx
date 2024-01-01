import { useRef } from "preact/hooks";
import Menu from "~/islands/Menu.tsx";
import { Context } from "~/types.ts";
import { useComputed, useSignal } from "@preact/signals";
import { useAsyncEffect } from "~/hooks/useAsyncEffect.tsx";
import { fnMap, HEIGHT, init, next, WIDTH } from "~/utils.ts";

export default function Game() {
  const ref = useRef<HTMLCanvasElement>(null);
  const context = useSignal<Context>(init(ref));
  const kind = useComputed(() => context.value.step);
  const fn = useComputed(() => (fnMap[context.value.step] ?? next));
  const instance = useComputed(() => generate());

  useAsyncEffect(instance, context);

  function generate() {
    return async function* () {
      while (kind.value !== "END") {

        yield await fn.value(context);
      }
    };
  }

  return (
    <div class="flex items-center justify-center flex-col gap-5 m-5">
      <canvas
        width={WIDTH}
        height={HEIGHT}
        class={`w-full h-full border-4 border-black rounded-md`}
        ref={ref}
      />
      <Menu context={context} />
    </div>
  );
}
