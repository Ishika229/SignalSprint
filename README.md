# Signal Sprint — Godot 4 Prototype

A small 3D collection-and-dodge prototype built with Godot's built-in shapes and GDScript.

## Gameplay
- Move the teal robot with **WASD** or **arrow keys**.
- Collect all **5 yellow energy cells** to win.
- Avoid the moving **red security drone**; touching it ends the run.
- Use **Play Again** to restart after winning or losing.

## Run
1. Install Godot 4.x.
2. Open Godot Project Manager and choose **Import**.
3. Select this folder's `project.godot` file.
4. Run the project (F6/F5 or the Play button).

## Project structure
- `project.godot` — project settings and main scene.
- `scenes/Main.tscn` — main scene.
- `scripts/main.gd` — creates the arena, player, collectibles, drone, UI and game loop.

## Git setup
The project is version-controlled in this repository. To clone it:
```bash
git clone https://github.com/Ishika229/SignalSprint.git
```

This is an early prototype. Test it in Godot 4.x and adjust if your installed version reports any API differences.
