# RMS Menotics Cruise Ship Mod (`rms_menotics`) for Luanti / Minetest

> **Notice**: Development on this mod has been stopped because the animation issue is not solvable. We are developing this further in the **CruiseShip** mod.
>
> *Note*: The big tsunami has been preserved as a separate mod in `tsunami_water`.

**RMS Menotics** is a complete, standalone, ocean liner mod for Luanti / Minetest (supporting **Minetest Game**, **Mineclonia**, and **VoxeLibre**).

It introduces a massive, majestic, 100-block long autonomous passenger cruise ship (**RMS Menotics**), featuring extensive walkable open-air decks, buildable interior cabins, moving block & luggage support, and autonomous straight-line cruising.

---

## Key Features

1. **Massive 100-Block Vessel Geometry**:
   - **Dimensions**: 100 blocks long × 15 blocks wide × 15 blocks tall.
   - Solid walkable nodes aligned perfectly with the 3D OBJ mesh (`models/cruiseship.obj`).

2. **Walkable Interior & Open-Air Decks**:
   - **Lower Deck / Hull** (ly = 0 to 2): Hull bottom, engine rooms, cargo holds.
   - **Mid Decks / Cabins** (ly = 3 to 7): Fully enclosed living spaces, interior corridors, and companionway staircases.
   - **Interior Promenade** (ly = 8): Glass-lined walking deck with scenic ocean views.
   - **Top Sun Deck / Open Air** (ly = 9 to 11): Fully open-air deck protected by deck railings, outdoor swimming pool, deck chairs, and open walking paths.
   - **Watertight Envelope**: Keeps interior cavity dry while at sea, displacing surrounding ocean water without leaking and restoring natural water when moving or dismantled.

3. **Moving Blocks & Luggage Preservation Engine**:
   - High-performance **spatial hash engine** tracking active nodes inside the 100×15×15 bounding box.
   - Supports custom player-placed nodes (chests, furnaces, torches, beds, crafting tables, doors, ladders, glass, luggage).
   - Rotates directional nodes (`facedir`, `wallmounted`) accurately and preserves all inventory contents and metadata.

4. **Autonomous Navigation & Navigation Physics**:
   - **60-Second Dock Idle & Whistle**: Idles for 60 seconds upon placement or arrival; plays a steamship horn sound on departure.
   - **Straight-Line Cruising**: Navigates along cardinal directions at ~2.2 m/s speed.
   - **Water Depth & Hazard Checking**: Requires at least 3 blocks of open water under the hull and scans ahead for shores or obstacles.

5. **Obstacle & Hazard Detection**:
   - Actively scans ahead for obstacles and ice hazards (`default:ice`, `mcl_core:packed_ice`, `mcl_core:blue_ice`, snow blocks).
   - On obstacle or hazard detection:
     - Halts the vessel safely.
     - Sounds the ship horn warning.

6. **Tool Interactions & Admin Commands**:
   - **Screwdriver Rotation**: Right-clicking with a screwdriver rotates the ship, cargo, and standing players 90° clockwise.
   - **Pickaxe Dismantling**: Pickaxe dig safely dismantles the ship, returns the ship item, and drops all cargo/chest contents.
   - **Admin Commands**: `/delete_menotics` (aliases: `/clear_ships`, `/delete_cruise`) force-loads mapblocks and cleans up ships safely.

---

## Crafting Recipe

The recipe is expensive to reflect the massive 100-block scale:
- **10x Steel / Iron Blocks**
- **5x Coal Blocks**
- **20x Wood Planks**
- **10x Glass**
- **5x Gold Ingots**

---

## License

- Code: MIT
- Model / Assets: CC0 / Public Domain
