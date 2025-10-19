# Roguelike Top-Down Pixel Art Game  
### Game Design Document — Continuous Swarm / Procedural Islands


## Core Concept

A **top-down roguelike action game** where the player fights **continuous swarms** of enemies while exploring a **procedurally generated world** built from **handcrafted islands**.  

Each island offers unique upgrade opportunities, events, or encounters. Combat is **manual aim and movement** — the player’s skill and positioning determine survival.  

The player wields a **single evolving weapon** that mutates through upgrades as the run progresses. The goal: **survive as long as possible** while uncovering new areas and overcoming increasingly difficult foes.



## Game Loop

### 1. Start Run
- Spawn player on the **starting island**.  
- Equip the **base weapon**.  
- Begin low-intensity enemy spawns to introduce movement and aiming.

### 2. Exploration & Combat
- Player moves freely between connected **islands**.  
- Enemies spawn dynamically, scaling with player progress.  
- Combat is **manual** — aim with mouse or right stick, move with WASD or left stick.  
- Enemies drop **XP or upgrade materials** used to evolve the weapon.

### 3. Islands as Dynamic Zones
The world consists of many **handcrafted islands** arranged in a **procedurally generated layout**.  
Each island is part of one large, interconnected world.

Players can **freely move back and forth** between islands as they fight, explore, and gather resources.  
Instead of each island having a fixed role, **events and pickups are dynamically assigned** during the run.

#### Island Dynamics
- **Event Spawns:** Occasionally, islands generate temporary events like:
  - **Upgrade Shrines**
  - **Resource Caches**
  - **Elite Enemy Encounters**
  - **Mini-Boss Fights**
- **Loot & Pickups:** XP orbs, healing items, or special upgrades appear randomly on cleared or quiet islands.  
- **Boss Encounters:** Certain islands may temporarily become **boss arenas**, locking the player in until the boss is defeated.

### 4. Weapon Evolution
- Player wields **one weapon** that evolves via upgrades — no weapon swapping.  
- Upgrades are modular and stackable, allowing deep build variety.

#### Upgrade Categories
1. **Stat Mods** – Damage, fire rate, projectile speed, reload, etc.  
2. **Behavior Mods** – Spread shots, ricochet, piercing, AoE.  
3. **Effect Mods** – Burn, poison, freeze, shock, bleed.  
4. **Synergy Mutations** – Unlock special forms when conditions are met.  
   - Example: *Burn + AoE → Flame Burst*  
   - Example: *Ricochet + Shock → Arc Blades*  

Upgrades are rewarded from:
- Clearing islands  
- Chests or mini-boss drops  
- Upgrade shrines

### 5. Scaling & Pressure
- Difficulty increases as the player explores deeper into the world.  
- Each cleared island raises global enemy strength and spawn rate.  
- No wave phases or downtime — only movement, combat, and decisions between encounters.

### 6. End Condition
- The run ends when the player dies.  
- Optional: meta-progression system (persistent unlocks, new starting weapons, or characters).


---

## Combat System

### Core Mechanics
- **Manual Movement:** WASD or controller left stick.  
- **Manual Aiming:** Mouse or controller right stick.  
- **Dodge Mechanic:** Dash, roll, or blink for evasion.  
- **Physics Feedback:** Knockback, recoil, and hit impact.  
- **Precision Emphasis:** Player control and accuracy are key.

### Design Goals
- Responsive and tactile controls.  
- Clear visual feedback for damage, hits, and criticals.  
- Smooth, readable combat even during chaos.  

---

## Visual & Feedback Direction

- **Readable silhouettes:** Enemies and projectiles remain distinct.  
- **Lighting:** Darker world tones with glowing projectiles and particle effects.  
- **Minimal UI:** Focus on HP, XP, upgrade prompts — no combo meters or wave counters.

---

## Design Pillars

| Pillar | Description |
|--------|--------------|
| **Skill-Based Combat** | Manual aiming & movement ensure survival feels earned. |
| **Evolving Weapon** | A single, upgradeable weapon defines each unique build. |
| **Procedural Exploration** | Handcrafted islands with procedural connections ensure replayability. |
| **Continuous Swarms** | No downtime — constant action and scaling pressure. |
| **Meaningful Upgrades** | Every choice meaningfully alters combat style and effectiveness. |

---

## MVP Goals

1. **Core Combat**
   - Implement responsive player controller (move + aim + shoot)
   - Manual aiming with mouse or right stick
   - Basic enemy AI (chase + attack)
   - Collision, damage, and hit feedback  

2. **Procedural World**
   - Generate a connected overworld made of multiple handcrafted islands
   - Implement smooth transitions between islands
   - Spawn enemies, pickups, and events dynamically across the map  

3. **Dynamic Event System**
   - Periodically populate random islands with events:
     - Upgrade shrines
     - Resource caches
     - Elite enemies or mini-bosses
     - Healing or utility pickups
   - Handle event expiration or replacement over time  

4. **Weapon Upgrade System**
   - XP or resource pickup system
   - Level-up menu offering 2–3 random upgrade choices
   - Apply stat, behavior, and effect upgrades to the single evolving weapon  

5. **Difficulty Scaling**
   - Gradually increase enemy strength and spawn rate based on:
     - Time survived
     - Number of events completed

6. **Basic UI**
   - Display player HP, XP, and available upgrades
   - Simple event indicators or minimap icons for nearby activity  
