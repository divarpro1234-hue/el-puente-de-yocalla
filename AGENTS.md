<!-- fennara-agents-start -->

# Fennara MCP Guidelines

This project uses Fennara MCP for Godot-aware inspection, editing, runtime error capture, diagnostics, scene validation, screenshots, and project settings.

When working on Godot-specific files or behavior, always read:

`addons/fennara/ai/guidelines.md`

This includes work involving:

- `.tscn`
- `.tres`
- `.res`
- `.gd`
- `.cs`
- `.gdshader`
- `project.godot`
- scenes
- nodes
- resources
- shaders
- project settings
- gameplay
- UI
- animation
- rendering
- Fennara addon behavior
- Fennara MCP behavior

For specialized visual, runtime, operational, or client-specific work, use:

`addons/fennara/ai/index.md`

Only read the relevant documentation page required for the task.

Do not read every linked page by default.

Live tool schemas define exact calls and results.

<!-- fennara-agents-end -->


# Project-Specific Rules — Relatos de Bolivia: El Puente de Yocalla


# Project

- Engine: Godot Engine 4.7.1 Stable.
- Language: GDScript.
- Target platform: Windows PC.
- Game type: 2D narrative adventure with light platforming.
- Main playable character: Kespi.
- Current document baseline: GDD v1.0.


# Scope Rules

Kespi is the only playable character.

The project must remain a narrative adventure game.

Do not add systems that transform the project into another genre.

Forbidden unless explicitly authorized by a project update:

- combat systems;
- enemy systems;
- RPG progression;
- inventory systems;
- economy systems;
- multiplayer;
- open-world systems;
- crafting systems;
- skill trees;
- XP or leveling systems.


Additional systems are allowed only when explicitly authorized by a project update.


# Main Mechanics

The main gameplay mechanics defined by the GDD are:

1. Horizontal movement.

2. Simple jump and environmental obstacles.

3. Contextual interaction using E.

4. Investigation and information gathering.

5. Narrative objectives and progression.


Keep these mechanics as the foundation of the project.

Do not replace them with unrelated systems.


# Input

- A / D or Left / Right: movement.
- Space: jump.
- E: interact.
- Escape: pause.


# Player Rules

- No double jump unless explicitly requested.
- No dash unless explicitly requested.
- No wall jump unless explicitly requested.
- No combat actions.
- Keep player physics simple and predictable.
- Failure should use the existing checkpoint system.


# Narrative Rules

- Dialogue is linear.
- Do not create branching story choices.
- Do not alter essential events of El Puente de Yocalla.
- Do not invent historical facts and present them as source material.
- Gameplay adaptations must remain clearly separate from source-derived story events.


# Development Rules

- Inspect existing scenes and scripts before modifying them.
- Use Fennara before modifying Godot-specific files.
- Verify changes after modification.
- Keep folders and files organized.
- Prefer simple reusable systems.
- Avoid over-engineering.
- Make small, verifiable changes.
- Do not hide parser errors or warnings.
- Do not modify original source assets unnecessarily.
- Use placeholder/blockout assets before final art.


# Current Development Priority

The current goal is a minimal complete playable prototype.

Current priorities:

- stable player movement;
- jump and collision;
- camera system;
- NPC interaction;
- simple dialogue;
- mission/objective updates;
- checkpoint and respawn system;
- complete three-level narrative flow;
- simple gameplay support systems explicitly authorized.

Do not implement large systems outside the current requested task.


# Final GDD v1.0 Alignment Addendum

These rules supersede any earlier project-specific rule that conflicts with them.


# Level Structure

The final Week 1 GDD defines exactly 3 main playable levels.

These 3 levels are composed of 5 reusable narrative/environment zones.

Do not interpret the 5 zones as 5 independent playable levels.


## Level 1 - Yocalla y la misión

- E01 Yocalla.
- E02 Complejo del jefe inca.


## Level 2 - Reconocimiento y regreso

- E04-A Senderos de ida.
- E03 Zona de reconocimiento.
- Mensajero encounter.
- E04-B Senderos de regreso / tormenta.


## Level 3 - El Puente de Yocalla

- E05 Río / Puente.
- E01-C Yocalla epílogo.


# Scope Confirmation

Keep the 5 main mechanics defined in the GDD.

Do not add new NPC, mechanics, levels or systems unless explicitly requested.

Additional systems are allowed only when explicitly authorized by a project update.


# Gameplay Update Override: Basic Health System Enabled

This section overrides previous restrictions related to health systems.

A minimal player health system is officially authorized.


## Allowed

The following are allowed:

- Player health only.
- Maximum health: 100.
- Basic damage handling.
- Health HUD during gameplay only.
- Respawn using the existing checkpoint system.


## Purpose

The health system exists only as a foundation for future environmental hazards.

Allowed future uses:

- falls;
- storms;
- environmental dangers.


## Health System Restrictions

Do not implement:

- combat;
- enemies;
- enemy attacks;
- enemy damage;
- inventory;
- hunger;
- thirst;
- stamina;
- XP;
- leveling;
- Game Over screens;
- death menus.


## Architecture Restrictions

The health system must remain simple.

Do not create:

- GameManager;
- PlayerManager;
- HealthManager;
- autoloads;
- global systems;
- state machines.

Do not modify:

- checkpoint architecture;
- player movement;
- narrative systems;
- existing levels unless explicitly required.


# MCP Status

- Codex <-> Fennara MCP <-> Godot 4.7.1 integration has been technically validated.
- Fennara MCP may be used to inspect and modify the active Godot project when explicitly requested.
- Always inspect before modifying.
- Always verify after modifying.


# Current Development Phase

Current phase:

Playable prototype expansion and technical stabilization.

Work in small, verifiable tasks.

Do not implement the complete final game at once.
