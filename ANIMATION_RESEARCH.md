# Plutoniumships Animation Research

Based on the exploration of `https://github.com/The-Fabulous-Plutonium/plutoniumships` (v10), the animation and movement of their ships are handled significantly better than standard node teleportation.

Here is how they achieve it:

## Dual Entity Architecture

Plutoniumships uses two parallel structures to represent a moving ship:
1.  **`block_part_visual`**: These are entities that handle the **visuals** (the model, textures). Crucially, these are attached to the main ship entity (or driver) using Minetest's `set_attach` function. Attaching them allows the Minetest engine/client to interpolate their positions natively, resulting in extremely smooth movement and rotation on the client side without jitter. They have `physical = false`.
2.  **`block_part_physics`**: These are invisible entities (`physical = true`, `collide_with_objects = true`) that handle **collision**. Since `set_attach` removes physics and collision in Minetest, these blocks cannot be attached. Instead, they are independently teleported/repositioned every server tick (or frame) to follow the ship.

## Key Observations
*   **Rotation:** By attaching the visual parts, they can apply smooth 3D rotations via yaw/pitch/roll matrices without the blocky snapping you get from changing `param2` of static nodes.
*   **Performance vs Visuals:** The server only has to compute hard physics updates for the invisible collision blocks. The client does the heavy lifting of smoothly rendering the attached visual blocks.
*   **Movement Interpolation:** `lerp_vel` (linear interpolation of velocity) is heavily used to smoothly accelerate/decelerate the ship entity, providing a sense of momentum (e.g. `vel = lerp_vel(vel, tgt.x, tgt.z, cfg.accel_factor * mf)`).

This dual-architecture is a robust workaround to Minetest's engine limitations regarding moving solid structures smoothly.