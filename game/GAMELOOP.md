# Roguelike Top-Down Pixel Art Game - MVP Gameloop & Notes

## Core Concept
- Player defends a **core** against waves of enemies.  
- Between waves, the player explores the world for **upgrades, resources, and build evolution**.  
- The game lasts ~10 minutes or until the **player or core dies**.  
- The player progresses via **a single evolving weapon**, creating meaningful builds each run.  
- Day/Night cycle is **event-driven**, not time-based:  
  - **Day** ends when the player runs out of oxygen.  
  - **Night** ends when the current wave is defeated.
---


## Gameloop (Player-Driven Day/Night)

### 1. Start Game

* Spawn player & core at the center.
* Set initial oxygen / exploration limit.
* Give player a **base weapon** (single weapon)

### 2. Day (Exploration Phase)

* Player moves freely in the world.
* **Oxygen mechanic:** Oxygen drains based on distance from core. When it reaches zero → day ends automatically.
* Player can:

  * Loot chests
  * Fight minor enemies (optional)
  * Collect resources for upgrades / defenses

### 3. Transition: Night Preparation

* Once oxygen runs out, player returns (or is pulled back) to core area.
* Night wave spawns based on progression.

### 4. Night (Wave Phase)

* Enemies attack the core.
* Player fights alongside/defends core.
* Wave ends when all enemies for that night are defeated.
* Rewards granted: resources, upgrade points, or items.

### 5. Expansion Mechanic

* Player’s maximum safe exploration distance (oxygen tether) increases gradually:

  * With upgrades (better gear, stamina, lanterns)
  * Or after surviving waves (core-level progression)
* Further areas = rarer loot, tougher minor enemies → natural risk/reward

### 6. Repeat

* Return to **Day (Exploration)** → explore new area until oxygen runs out → **Night (Wave)**.
* Loop continues until:

  * Player dies
  * Core dies
  * Optional: 10-minute soft session limit

---

## Single-Weapon Progression Notes

### Weapon Evolution Mechanics
- Player has **one weapon** that grows over the run  
- Upgrades are **modular and stackable**, forming a “build” within that weapon  
- Types of upgrades:  
  1. **Stat Upgrades** – Increase damage, attack speed, range  
  2. **Behavior Upgrades** – Add AoE, piercing, chain attacks  
  3. **Effect Upgrades** – Add burn, freeze, poison, stun  
  4. **Conditional Mutations** – Unlock special behaviors after prerequisite upgrades  

### Upgrade Flow
1. Pick upgrade from loot, chest, or post-wave reward  
2. Apply upgrade to weapon:
   - Stat increase → direct boost  
   - Behavior/effect → new mechanics unlocked  
   - Conditional mutation → unlocks only if prerequisites met  
3. Weapon continues evolving each wave/day → builds feel distinct by end of run


## Notes for Implementation

### Oxygen

* Can be replenished with consumables.
* Decreased over time with a set amount.

### Wave Design

* Waves scale by number or type of enemies, not time.
* Waves end whenever all enemies die.


### Exploration Incentive

* Farther you go → higher risk → better rewards.
* Can include rarer chests, stronger minor enemies, or special resources.
* Rare enemies?

### Expansion Mechanic

* Gradual progression via gear
* Gear can have rarity (common, uncommon, rare, epic) and level.
* No hard borders; risk/reward is controlled by oxygen and enemy difficulty.

### Optional Enhancements

* Minor enemies or rare spawns during day to make exploration dynamic.
* Visual cues for oxygen or danger zones (fog, dim lighting).

---
