import Game from "~/islands/Game.tsx";

export default function Home() {
  return (
    <div class="flex items-center justify-center h-screen flex-col gap-20">
      <h1 class="text-4xl">Conway's Game of Life</h1>
      <Game />
    </div>
  );
}
