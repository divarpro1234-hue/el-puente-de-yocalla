<!-- fennara-agents-start -->
# Fennara MCP Guidelines

This project uses Fennara MCP for Godot-aware inspection, editing, runtime error capture, diagnostics, scene validation, screenshots, and project settings.

When working on Godot-specific files or behavior, always read `addons/fennara/ai/guidelines.md` first. This includes work involving `.tscn`, `.tres`, `.res`, `.gd`, `.cs`, `.gdshader`, `project.godot`, scenes, nodes, resources, shaders, project settings, gameplay, UI, animation, rendering, Fennara addon behavior, or Fennara MCP behavior.

For specialized visual, runtime, operational, or client-specific work, use `addons/fennara/ai/index.md` to find the one relevant page. Do not read every linked page by default. Live tool schemas define exact calls and results.
<!-- fennara-agents-end -->

# Project-Specific Rules — Relatos de Bolivia: El Puente de Yocalla

## Project
- Engine: Godot Engine 4.7.1 Stable.
- Language: GDScript.
- Target platform: Windows PC.
- Game type: 2D narrative adventure with light platforming.
- Main playable character: Kespi.
- Current document baseline: GDD v1.0.

## Scope Rules
- Kespi is the only playable character.
- Do not add combat.
- Do not add health points or health bars.
- Do not add lives.
- Do not add inventory.
- Do not add currency.
- Do not add XP or leveling.
- Do not add crafting.
- Do not add skill trees.
- Do not add multiplayer.
- Do not add open-world systems.
- Do not add mechanics that are not defined in the GDD.

## Main Mechanics
1. Horizontal movement.
2. Simple jump and environmental obstacles.
3. Contextual interaction using E.
4. Investigation/information gathering.
5. Narrative objectives and progression.

## Input
- A / D or Left / Right: movement.
- Space: jump.
- E: interact.
- Escape: pause.

## Player Rules
- No double jump.
- No dash.
- No wall jump.
- No combat actions.
- Failure returns the player to the latest checkpoint.
- Keep player physics simple and predictable.

## Narrative Rules
- Dialogue is linear.
- Do not create branching story choices.
- Do not alter essential events of El Puente de Yocalla.
- Do not invent historical facts and present them as source material.
- Gameplay adaptations must remain clearly separate from source-derived story events.

## Development Rules
- Prefer simple reusable systems.
- Do not over-engineer the prototype.
- Inspect existing scenes and scripts before modifying them.
- Keep folders and files organized.
- After meaningful modifications, run the project and check for errors.
- Do not hide parser errors or warnings.
- Do not modify original source assets unnecessarily.
- Use placeholder/blockout assets before final art.
- Make small, verifiable changes instead of attempting the entire game at once.

## Current Priority
The current goal is a minimal functional Week 1 prototype:
- Player movement.
- Jump.
- Basic collision.
- Camera.
- One functional NPC interaction.
- Simple dialogue.
- Mission/objective update in the HUD.

Do not implement later chapters yet.
