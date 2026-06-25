# Invasion Game

A mobile tower defense game built in Godot 4. Defend a living tree from an
18-minute swarm of insects using forest-animal towers, level up mid-run with
upgrade cards, and unlock skills from the tree itself.

This README is a walkthrough. Read top to bottom and you'll understand how
to play, how the systems fit together, and where to find things in the code.

## Playing the game

### Before you start

You begin with a starting coin stash and a small unlocked patch of grass
around the tree. An objectives screen explains the goal before the run
starts. Press **Start Defending** when you're ready.

### Controls

| Action | How |
|---|---|
| Place the selected tower | Tap an unlocked grass tile |
| Switch which tower is selected | Tap a tower button (top-left) |
| Sell a tower | Tap **Sell** (bottom-right), then tap the tower |
| Vacuum up coins/essence | Drag your finger (or right-click-drag on desktop) near a pickup |
| Open the skill tree | Tap the tree itself, or the **Skills** button (bottom-left) |
| Activate Shield | Tap the **Shield** button (bottom-left), see Skills below |
| Zoom | Pinch (mobile) or scroll wheel (desktop) |

### The goal

Survive **18 minutes**. The countdown timer is at the top of the screen. If
the tree's HP (top-right) reaches zero, the run ends. Survive to 00:00 and
you win.

### The economy

- **Coins** buy towers and refund 50% when you sell one. Coin value per
  kill rises slowly over the run, and gold-ringed "wealthy" enemies drop a
  big bonus.
- **Essence** (the green-tinted pickups) levels you up. Leveling pauses the
  game and offers 3 upgrade cards, pick one. Cards are either global stat
  boosts, tower-specific upgrades, or rare attachments that bind
  permanently to one tower you tap next (and are lost forever if that tower
  dies).
- The grid unlocks more space automatically as the run progresses. You
  don't have to pay for it, just wait.

### Towers

| Tower | Animal | Identity |
|---|---|---|
| Arrow | Frog | Cheap, fast-firing, short range |
| Cannon | Bear | Slow, splash damage, tanky |
| Sniper | Monkey | Long range, high damage, hits the nearest target |

### Enemies

Regular insects start simple and gain new behaviors one wave at a time as
the run progresses:

- **Normal**: straight line to the tree.
- **Fast**: accelerates the longer it's alive.
- **Tanky**: high HP, slow.
- **Flanker**: arcs around before committing to a straight approach.
- **Flying**: ignores towers entirely, only damage stops it.

Mini-bosses are bigger, telegraphed several seconds in advance with a
warning marker, and target whichever side of your base is weakest:

- **Brute / Marksman**: bulldoze through anything in their path, then siege
  the tree once they arrive.
- **Stag Beetle**: sweeps around the perimeter hitting towers before
  beelining to the tree.
- **Goliath Beetle**: knocks towers to a random open tile instead of
  damaging them.
- **Hornet**: flies, ignoring towers completely. The toughest, latest
  arrival.

### The wave rhythm

Waves climb from a calm trickle to a full-surround climax. Most wave
transitions roll straight into the next wave, just resetting the pace back
to calm, a brief "slow down" rather than a full stop. A real breather (no
spawns at all) happens specifically when a new enemy type is about to be
introduced, and periodically otherwise. Breathers get shorter as the clock
runs down, so the second half of the run stays relentless.

### The skill tree

Tap the tree to open it:

- **Shield**: free, available immediately. Tap it to make every tower
  briefly invulnerable. It has a cooldown, so save it for a mini-boss or a
  moment you're about to lose towers.
- **Vines** (unlock with coins): periodically slows enemies near the tree.
- **Weaken Boss** (unlock with coins): every mini-boss that spawns
  afterward has reduced HP and damage.

## Project structure

```
autoloads/        Global singletons (GameState, BuildState, SkillTree, SFX)
scripts/
  systems/         Game.gd (orchestrator), WaveManager, camera, coins, upgrades
  grid/            Hex math, grid rendering, the centerpiece tree
  enemies/         EnemyBase, MiniBoss, and their data resources
  towers/          TowerBase, Projectile, and tower/rare-attachment data
  ui/              HUD, level-up/skill-tree/objectives/end screens, icons
scenes/            .tscn files mirroring the script folders
resources/         .tres data: tower stats, mini-boss stats, rare attachments, theme
```

### How the systems fit together

- **`Game`** (`scripts/systems/game.gd`) is the root orchestrator. It wires
  every other system together, handles tap input (placing/selling towers,
  opening the skill tree), and reacts to win/lose.
- **`WaveManager`** owns all enemy/mini-boss spawning and the wave-rhythm
  state machine. It doesn't know about rendering or UI, it just spawns
  things and emits signals (`wave_cleared`, `wave_incoming`,
  `mini_boss_spawned`, `enemy_killed`).
- **`GameState`** (autoload) holds run-scoped numbers: coins, essence,
  level, the countdown clock, `RUN_DURATION`. Anything that needs "how much
  time is left" or "how many coins does the player have" reads this.
- **`BuildState`** (autoload) holds global per-tower-type stat multipliers
  from upgrade cards. Towers read it live every frame, so a card picked
  mid-run instantly affects towers already on the field.
- **`SkillTree`** (autoload) holds Shield/Vines/Weaken state. Towers check
  `SkillTree.shield_active` directly in `take_damage()`.
- Enemies, towers, and mini-bosses are all **data-driven**: `TowerData`,
  `MiniBossData`, and `RareAttachmentData` are `Resource` files you can
  tune or duplicate in the Godot Inspector without touching code. Adding a
  new tower or mini-boss is "create a new `.tres`, add it to the relevant
  pool array", no script changes required.
- All visuals are **procedurally drawn** (`_draw()` calls), not sprites.
  There's no art asset pipeline. Sound effects are likewise synthesized at
  runtime by the `SFX` autoload (see `autoloads/sfx.gd`), so there are no
  audio asset files either.

## Running the project

1. Open the project folder in Godot 4.6+.
2. Press Play. `Game.tscn` is the main scene.
3. The mobile viewport is portrait (1080x1920). Resize the editor window or
   use the device preview to test at phone proportions.

## Tuning the game

Everything below is exposed as plain constants or `.tres` resources, no
code changes needed for most balance tweaks:

- **Run length**: `GameState.RUN_DURATION`.
- **Tower stats**: `resources/towers/*.tres`.
- **Mini-boss stats/timing**: `resources/minibosses/*.tres` (`min_minute`
  controls when each one starts appearing).
- **Upgrade card pool**: `scripts/systems/upgrade_pool.gd`, add a line to
  add a new card.
- **Wave pacing**: constants at the top of `scripts/systems/wave_manager.gd`
  (`WAVE_ACTIVE_DURATION`, `UNLOCK_WAVES`, rest durations).
