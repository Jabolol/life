import { Context } from "~/types.ts";
import {
  ReadonlySignal,
  Signal,
  useSignal,
  useSignalEffect,
} from "@preact/signals";

export function useAsyncEffect<T, K, V>(
  instance: ReadonlySignal<() => AsyncGenerator<T, K, V>>,
  context: Signal<Context>,
) {
  const signal = useSignal<T>({} as T);
  const fired = useSignal<boolean>(false);

  const runEffect = async (asyncGenerator: AsyncGenerator<T, K, V>) => {
    let result = await asyncGenerator.next();

    while (!result.done) {
      signal.value = result.value;
      result = await asyncGenerator.next();
    }
  };

  useSignalEffect(() => {
    switch (true) {
      case context.value.change:
        context.value = { ...context.value, change: false };
        /* falls through */
      case !fired.value:
        fired.value = true;
        runEffect(instance.value());
    }
  });

  return [signal] as const;
}
