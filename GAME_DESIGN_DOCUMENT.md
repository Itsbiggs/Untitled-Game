# Tactical Souls - Game Design Document

## Project Overview

**Title:** Tactical Souls  
**Genre:** Turn-based Tactical Roguelike with Co-op Multiplayer  
**Platform:** PC (Steam)  
**Engine:** Godot 4  
**Art Style:** Isometric Pixel Art  
**Target Audience:** Fans of tactical RPGs, roguelikes, and co-op games

---

## Core Concept

A turn-based tactical roguelike where players assemble a party of 4 dual-class heroes and battle through dungeon floors. Each run is permadeath - when your party dies, you start fresh. Players customize their builds before each run and earn currency during the run to unlock more abilities from their skill trees.

---

## Key Features

### 1. Dual-Class System
- Players can combine any two of 8 base classes
- Each combination creates a unique skill tree with distinct abilities
- Examples: Ember Blade/Chronomender, Bulwark/Hexweaver, etc.

### 2. Party-Based Tactical Combat
- Control 4 characters on an isometric grid
- Chess-like positioning mechanics
- Turn-based: Player phase → Enemy phase
- Positioning, terrain, and ability combos matter

### 3. Skill Tree Progression
- **Pre-Run:** Spend starting skill points to customize initial build
- **During Run:** Earn currency from combat to unlock more abilities
- **Permadeath:** All progress lost on party wipe

### 4. Co-op Multiplayer
- **Solo Play:** Control all 4 characters
- **2-Player Co-op:** Each player controls 2 characters
- Host controls unassigned characters

### 5. Roguelike Structure
- Procedurally arranged dungeon floors
- Increasing difficulty
- Permadeath - start fresh each run
- Pure roguelike (Option A): No meta-progression between runs

---

## The 8 Classes

Classes are organized into 4 archetypes with 2 classes each:

### Damage Classes

#### 1. Ember Blade (Melee DPS)
**Role:** High-risk melee damage dealer  
**Core Mechanic:** Ignites weapon with each strike
- Attacks leave **burning tiles** on the grid that damage enemies
- Builds **heat** with consecutive attacks
- Higher heat = more damage, but also takes recoil damage
- Risk/reward playstyle

**Key Abilities (Examples):**
- Flame Strike: Melee attack that ignites the target tile
- Blazing Rush: Dash through enemies, igniting path
- Inferno: Detonate all burning tiles for massive damage

#### 2. Riftcaller (Ranged DPS)
**Role:** Ranged damage dealer with positioning tricks  
**Core Mechanic:** Tears holes in space for unusual attack angles
- Attacks can **curve around the grid** using mini-portals
- Can shoot **through obstacles**
- Makes positioning puzzles more complex

**Key Abilities (Examples):**
- Rift Shot: Ranged attack that bends around obstacles
- Portal Step: Short-range teleport
- Dimensional Barrage: Multiple attacks from different angles

### Tank Classes

#### 3. Bulwark (Traditional Tank)
**Role:** Defensive positioning and battlefield control  
**Core Mechanic:** Creates physical barriers on the grid
- Places **shield wall segments** that block movement and projectiles
- Turns battlefield into a maze
- Controls enemy pathing

**Key Abilities (Examples):**
- Shield Wall: Place a barrier segment on the grid
- Fortress Stance: Become immovable, adjacent tiles also block movement
- Bastion: Create a 3x3 protected zone

#### 4. Bloodbound (Life-drain Tank)
**Role:** Aggressive tank that shares damage  
**Core Mechanic:** Tethers to enemies to redistribute damage
- Damage dealt to Bloodbound is **split with tethered enemies**
- More tethers = tankier, but spreads damage around
- High-risk positioning tank

**Key Abilities (Examples):**
- Blood Tether: Link to an enemy, share damage taken
- Crimson Pact: Tether to all adjacent enemies
- Siphon: Deal damage equal to health lost this turn

### Healer Classes

#### 5. Chronomender (Time-manipulation Healer)
**Role:** Proactive healer requiring planning  
**Core Mechanic:** Rewinds characters to previous health states
- **Doesn't heal directly** - restores to marked states
- Can "snapshot" allies at full health
- Later restore them to that snapshot
- Requires forward planning

**Key Abilities (Examples):**
- Temporal Mark: Save an ally's current health state
- Rewind: Restore an ally to their marked state
- Mass Recall: Restore all allies to marked states

#### 6. Lifebinder (Shared Health Pool Healer)
**Role:** Group health management  
**Core Mechanic:** Links party into collective health pool
- Party members share a **collective health pool**
- Lethal damage is absorbed by the pool instead
- Manages total party health rather than individuals
- Makes group positioning critical

**Key Abilities (Examples):**
- Life Link: Connect two allies to share health
- Vital Network: All allies share one health pool
- Redistributive Pulse: Balance health across all linked allies

### Support Classes

#### 7. Hexweaver (Debuff Specialist)
**Role:** Area denial and enemy weakening  
**Core Mechanic:** Places cursed tiles with debuffs
- **Cursed tiles** apply different debuffs (slow, weaken, silence)
- Can detonate hexes for damage
- Area denial specialist

**Key Abilities (Examples):**
- Curse Tile: Place a hex that slows enemies
- Withering Hex: Debuff that reduces enemy damage
- Hex Detonation: Explode all hexes for AOE damage

#### 8. Echowright (Action Manipulator)
**Role:** Combo enabler and action economy  
**Core Mechanic:** Copies and replays ally actions
- **Stores ally abilities** and casts them again
- Reduced power on replays
- Creates wild combo potential

**Key Abilities (Examples):**
- Echo: Store an ally's last ability
- Replay: Cast the stored ability at reduced power
- Cascade: Cast stored ability multiple times

---

## Dual-Class Combinations

Any two classes can be combined to create unique builds:
- Total possible combinations: 8 × 7 = 56 unique dual-class builds (excluding duplicates)
- Each combination gets its own **hybrid skill tree**
- Skills draw from both class identities

**Example Combinations:**
- **Ember Blade / Chronomender:** Aggressive DPS that can rewind after risky plays
- **Bulwark / Lifebinder:** Ultimate defensive tank with shared health pools
- **Riftcaller / Hexweaver:** Ranged control with debuff zones
- **Bloodbound / Echowright:** Tank that can replay tether abilities for massive AOE

---

## Progression System

### Pre-Run Phase
1. **Character Creation:** Choose dual-class for each of 4 party members
2. **Skill Point Allocation:** All dual-classes start with the **same amount of skill points**
3. **Build Customization:** Spend starting points on initial abilities
4. **Enter Dungeon:** Lock in your build and begin the run

### During Run
1. **Combat:** Fight enemies on dungeon floors
2. **Earn Currency:** Gain currency from defeating enemies/completing floors
3. **Unlock Skills:** Spend currency to unlock more abilities from your skill tree
4. **Progress:** Continue through increasingly difficult floors

### Death & Reset
- **Permadeath:** When party wipes, all progress is lost
- **No Meta-Progression:** Each run starts completely fresh
- **Pure Roguelike:** Success depends on skill and decision-making, not grinding

---

## Combat System

### Turn Structure
1. **Player Phase:** Control all 4 party members, take actions in any order
2. **Enemy Phase:** All enemies act
3. **Repeat**

### Grid System
- **Isometric tile-based grid**
- Movement costs action points
- Positioning matters (flanking, line of sight, terrain)
- Some abilities create persistent tile effects (burning tiles, shield walls, hexes)

### Action Economy
Each character has:
- **Movement:** Limited tiles per turn
- **Actions:** Abilities cost action points
- Characters can typically move and use 1-2 abilities per turn

### Tile Effects
Persistent effects on the grid that last multiple turns:
- **Burning Tiles** (Ember Blade): Damage enemies who stand on them
- **Shield Walls** (Bulwark): Block movement and projectiles
- **Cursed Hexes** (Hexweaver): Apply debuffs to enemies

---

## Enemy AI

### Basic AI Logic
Enemies use simple but effective turn-based AI:

1. **Threat Assessment:** Identify closest or most vulnerable player character
2. **Ability Check:** Can I use a special ability? Evaluate if beneficial
3. **Attack Check:** Am I in range to attack? Execute attack
4. **Movement:** If not in range, move toward target
5. **End Turn**

### AI Complexity Tiers
- **Early Floors:** Simple melee enemies (move toward player, attack when adjacent)
- **Mid Floors:** Ranged enemies, basic ability usage
- **Late Floors:** Coordinated tactics, advanced ability combos

### Pathfinding
- Use **A* pathfinding** for grid navigation
- Enemies navigate around obstacles and shield walls
- Avoid hazard tiles when possible

---

## Multiplayer Structure

### Solo Play (1 Player)
- Player controls all 4 party members
- Full tactical control over entire party

### Co-op Play (2 Players)
- **Each player brings 2 characters** to the party
- **Host controls any unassigned slots**
- Both players act during the player phase
- Synchronized turn-based play

### Technical Implementation
- **Godot 4's built-in multiplayer nodes**
- Lobby system for matchmaking
- Turn synchronization between clients

---

## Development Roadmap

### Phase 1: Core Movement (Weeks 1-2)
- [ ] Isometric grid system
- [ ] Click to move one character
- [ ] Turn-based structure (player turn → enemy turn)
- [ ] Basic camera controls

### Phase 2: Basic Combat (Weeks 2-3)
- [ ] One attack ability
- [ ] Simple enemy AI (move toward player, attack when adjacent)
- [ ] Health and damage system
- [ ] Death system

### Phase 3: First Playable (Weeks 3-5)
- [ ] 2 classes with 1-2 abilities each
- [ ] 3 floor types with basic variety
- [ ] Basic skill tree (spend currency to unlock 1 new ability)
- [ ] Win/loss conditions
- [ ] UI for health, abilities, currency

### Phase 4: Dual Classes (Weeks 5-7)
- [ ] Implement all 8 base classes
- [ ] Create hybrid skill trees for combinations
- [ ] Balance starting skill points
- [ ] Pre-run character builder UI

### Phase 5: Co-op Multiplayer (Weeks 7-9)
- [ ] Multiplayer networking implementation
- [ ] Lobby system for 2 players
- [ ] Turn synchronization
- [ ] Character control distribution

### Phase 6: Content & Polish (Weeks 9-12)
- [ ] More enemy types and behaviors
- [ ] Additional floor layouts
- [ ] Full skill trees for all dual-class combinations
- [ ] Pixel art implementation
- [ ] UI/UX polish
- [ ] Sound effects and music
- [ ] Balance tuning

---

## Technical Specifications

### Engine
**Godot 4.3** (or latest stable)

**Why Godot:**
- Free and open-source (no revenue sharing)
- Excellent 2D/pixel art pipeline
- Built-in multiplayer support
- Beginner-friendly
- Lightweight and fast iteration
- GDScript (Python-like) or C# support

### Core Systems to Build

#### 1. Grid System
- Isometric tile map
- Coordinate system (grid → world position conversion)
- Tile highlighting and selection
- Pathfinding (A* algorithm)

#### 2. Character System
- Character stats (health, movement range, action points)
- Ability system
- Dual-class implementation
- Skill tree data structure

#### 3. Combat System
- Turn manager
- Action queue
- Damage calculation
- Status effects

#### 4. AI System
- Enemy behavior trees / state machines
- Pathfinding integration
- Threat assessment
- Ability decision-making

#### 5. Progression System
- Currency tracking
- Skill unlock logic
- Pre-run character builder

#### 6. Multiplayer System
- Lobby creation/joining
- Turn synchronization
- Character ownership
- Network state management

#### 7. UI System
- Character portraits and health bars
- Ability hotbar
- Skill tree interface
- Currency display
- Turn indicator

---

## Art Style & Visual Design

### Isometric Pixel Art
- **Tile Size:** 32x32 or 64x64 pixels (to be determined)
- **Character Size:** Proportional to tiles
- **Color Palette:** Cohesive fantasy dungeon aesthetic

### Visual Elements Needed
- **Tiles:** Floor, walls, obstacles
- **Characters:** 8 base classes × multiple animation states
- **Enemies:** Various types with animations
- **Effects:** Abilities, burning tiles, shield walls, hexes, etc.
- **UI:** Buttons, panels, icons for abilities

### Animation States
- Idle
- Walking (8 directions for isometric)
- Attack
- Ability cast
- Hit/damaged
- Death

---

## Audio Design

### Sound Effects
- Footsteps on different tile types
- Ability sounds (unique per class)
- Attack impacts
- UI feedback (clicks, hovers)
- Death sounds

### Music
- Menu/lobby music
- Combat music (intensity builds with difficulty)
- Victory/defeat stingers

---

## Scope Management

### Minimum Viable Product (MVP)
To launch on Steam, the game needs:
- ✅ 4 dual-class combinations (not all 56)
- ✅ 5-10 enemy types
- ✅ 10-15 floor layouts
- ✅ Basic skill trees (3-5 abilities per combination)
- ✅ Solo play functional
- ✅ Co-op functional
- ✅ Win/loss conditions
- ✅ Basic pixel art (can be simple initially)
- ✅ Core audio (essential SFX, 1-2 music tracks)

### Post-Launch Content
- Additional dual-class combinations
- More enemies and floor types
- Expanded skill trees
- New mechanics and abilities
- Quality of life improvements

---

## Design Principles

### 1. Clarity Over Complexity
- Grid should be easy to read
- Ability effects should be clear
- UI should be intuitive

### 2. Meaningful Choices
- Every skill point matters
- Positioning is critical
- Risk/reward decisions

### 3. Rewarding Skill
- No grinding or meta-progression
- Success through smart play and build optimization
- Learn from failures

### 4. Replayability
- 56 dual-class combinations offer variety
- Roguelike structure encourages multiple runs
- Different party compositions change tactics

### 5. Co-op Fun
- Coordinate with your partner
- Combo abilities between players
- Shared challenge, shared victory

---

## Success Metrics

### Development Goals
- Complete game in 12 weeks
- Launch on Steam
- Positive player feedback
- Stable multiplayer experience

### Post-Launch Goals
- 500+ wishlists before launch
- 1,000 copies sold in first month
- 75%+ positive Steam reviews
- Active player base for co-op

---

## FAQ & Design Decisions

**Q: Why no meta-progression?**  
A: Keeps the game focused on skill and decision-making. Each run is a fresh challenge. Simpler for first game project.

**Q: Why 4-character parties?**  
A: Enough for tactical depth, not overwhelming for beginners. Perfect for 2-player co-op split.

**Q: Why dual-classes?**  
A: Creates build variety without needing 50+ unique classes. 8 classes → 56 combinations.

**Q: Why turn-based?**  
A: Easier to implement AI, easier to balance, and allows for thoughtful tactical play. Better for multiplayer synchronization.

**Q: Why isometric?**  
A: Visually appealing for tactical games, clear spatial relationships, classic aesthetic.

---

## File Structure (Recommended)

```
tactical_souls/
├── scenes/
│   ├── game.tscn (main game scene)
│   ├── characters/
│   │   ├── ember_blade.tscn
│   │   ├── riftcaller.tscn
│   │   └── ...
│   ├── enemies/
│   ├── ui/
│   └── levels/
├── scripts/
│   ├── grid_manager.gd
│   ├── turn_manager.gd
│   ├── character.gd
│   ├── enemy_ai.gd
│   └── ...
├── assets/
│   ├── sprites/
│   ├── tiles/
│   ├── audio/
│   └── fonts/
└── resources/
    ├── abilities/
    └── skill_trees/
```

---

## Next Steps

1. **Set up Godot project**
2. **Create basic grid with placeholder tiles**
3. **Implement one character with movement**
4. **Add one enemy with basic AI**
5. **Iterate and expand**

---

**Version:** 1.0  
**Last Updated:** February 2026  
**Team:** Indie Development Team  
**Contact:** [Your contact info]
