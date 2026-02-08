# Tactical Souls

A turn-based tactical roguelike with isometric pixel art, built in Godot 4.6.

## Prerequisites

- [Godot 4.6](https://godotengine.org/download/) (Forward Plus renderer)

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/Itsbiggs/Untitled-Game.git
   cd Untitled-Game
   ```

2. Open the project in Godot:
   - Launch Godot 4.6
   - Click **Import** and navigate to the project folder
   - Select `project.godot` and click **Import & Edit**

3. Run the game:
   - Press **F5** or click the play button in the editor
   - The main scene (`scenes/game.tscn`) will launch automatically

## Controls

| Action | Key |
|--------|-----|
| Pan camera up | W |
| Pan camera down | S |
| Pan camera left | A |
| Pan camera right | D |
| Zoom in | Scroll wheel up |
| Zoom out | Scroll wheel down |
| Pan camera (drag) | Middle mouse button |
| Select unit / Move | Left click |
| End turn | Spacebar |

## How to Play

1. **Select** a player unit by clicking on it during your turn
2. Blue highlights show **reachable cells** and yellow highlights show the **movement path**
3. **Click a highlighted cell** to move the unit along the path
4. Press **Spacebar** to end your turn early, or it ends automatically after all units move
5. Enemies will chase toward your units on their turn

## Project Structure

```
Untitled-Game/
├── assets/
│   ├── characters/       # Character sprite sheets
│   │   ├── units/player/   # Player character art
│   │   └── enemy/basic/    # Enemy character art
│   └── tilesheets/       # Ground and wall tile images
├── resources/
│   └── tilesets/         # Godot tileset resources (Dungeon.tres)
├── scenes/
│   ├── game.tscn         # Main game scene
│   ├── characters/       # Character scenes (Fighter.tscn)
│   └── maps/             # Battle map scenes
└── scripts/
    ├── game.gd           # Game coordinator (selection, movement, turns)
    ├── unit.gd           # Base unit class (movement, grid position)
    ├── fighter.gd        # Player unit
    ├── basic_enemy_ai.gd # Enemy AI (chase nearest player)
    ├── turn_manager.gd   # Turn state machine
    ├── camera_controller.gd # Camera pan/zoom/drag
    └── grid/
        ├── grid_manager.gd   # Grid system, A* pathfinding, unit tracking
        ├── grid_cursor.gd    # Mouse-to-grid conversion, hover/click signals
        └── grid_highlight.gd # Visual highlights (range, path, hover)
```
