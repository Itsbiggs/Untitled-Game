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

# Tactical Souls

A turn-based tactical roguelike with dual-class system and co-op multiplayer.

## Project Structure
```
Untitled-Game/
├── assets/
│   ├── characters/          # Character sprite sheets
│   │   ├── enemy/
│   │   │   └── basic/      # Basic enemy sprites
│   │   └── units/
│   │       └── player/     # Player character sprites
│   └── tilesheets/          # Ground and wall tile images
│       └── dungeon/         # Dungeon tileset art
│
├── resources/               # Data files and configurations
│   ├── stats/              # Character stat templates (.tres files)
│   │   ├── classes/        # Single class stat templates (8 base classes)
│   │   └── dual_classes/   # Dual-class combinations (56 builds)
│   └── tilesets/           # Godot tileset resources
│       └── Dungeon.tres    # Main dungeon tileset
│
├── scenes/
│   ├── game.tscn           # Main game scene
│   ├── characters/         # Character scene files
│   │   ├── enemies/
│   │   │   └── BasicEnemy.tscn
│   │   └── fighter/
│   │       └── Fighter.tscn
│   └── maps/               # Battle map scenes
│       ├── battle_map.tscn
│       └── example_map.tscn
│
└── scripts/
	├── core/               # Core game systems
	│   ├── grid_manager.gd     # Grid system, A* pathfinding, unit tracking
	│   ├── turn_manager.gd     # Turn state machine (player/enemy phases)
	│   ├── unit.gd             # Base unit class (stats, modifiers, combat)
	│   ├── unit_stats.gd       # Stat resource definition (exported to .tres)
	│   └── stat_modifier.gd    # Buff/debuff/item modifier system
	│
	├── ui/                 # User interface controllers
	│   ├── camera_controller.gd  # Camera pan/zoom/drag
	│   ├── floating_text.gd      # Damage numbers, status text
	│   ├── grid_cursor.gd        # Mouse-to-grid conversion, hover/click
	│   ├── grid_highlight.gd     # Visual highlights (range, path, hover)
	│   └── health_bar.gd         # Unit health bar display
	│
	├── basic_enemy_ai.gd   # Enemy AI (chase nearest player)
	├── fighter.gd          # Player fighter unit
	└── game.gd             # Game coordinator (selection, movement, orchestration)
```

## Key Systems

### Grid System (`core/grid_manager.gd`)
- Isometric grid with A* pathfinding
- Unit tracking and registration
- Line of sight calculations
- Area of effect queries (radius, cone, line)
- Tile effects system (burning tiles, hexes, shield walls)

### Stats System (`core/unit.gd`, `unit_stats.gd`, `stat_modifier.gd`)
- Resource-based stat templates
- Dynamic stat calculation
- Modifier system for buffs/debuffs/items
- Supports 56 dual-class combinations

### Turn Management (`core/turn_manager.gd`)
- Player phase → Enemy phase alternation
- Turn state tracking
- Animation handling

### UI Systems (`ui/`)
- Grid cursor with hover detection
- Movement range highlighting
- Camera controls (pan, zoom, drag)
- Health bars and floating text

## Getting Started

1. Open `game.tscn` to see the main game scene
2. Character stats are configured in `resources/stats/`
3. Modify grid manager settings in `scenes/maps/battle_map.tscn`
4. Player units extend `Unit` class from `scripts/core/unit.gd`

## Development Notes

- All units inherit from `Unit` base class
- Stats are data-driven through `.tres` resource files
- Grid manager handles all pathfinding and spatial queries
- Modifier system allows dynamic stat changes (items, buffs, terrain effects)
