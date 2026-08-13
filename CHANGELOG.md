# Changelog

## 3.7.0

### Rare mount alerts

Most rares aren't worth stopping for. The ones holding a mount you don't have are, and now you'll know which is which.

**On its own**, MCL sweeps the minimap every few seconds — and reacts immediately when something appears — for any rare that drops a mount still missing from your collection. Nameplates are watched too, for rares that never post a minimap marker.

The alert shows you what you're being called over for: the rare rendered in 3D, its name on a bar you can click, and the mounts it owes you modelled underneath.

- **Click the name** to target the rare, mark it with a skull, and drop a waypoint on it
- **Drag** it anywhere; the position is remembered
- **Right-click** to dismiss it early, otherwise it fades after 8 seconds

### If you use RareScanner

RareScanner already finds rares, and two addons shouting about the same one helps nobody. So when it's installed MCL stops scanning entirely and adds to its alert instead: a **★ Mount** tag on the button, and the mount names on the tooltip when you hover it.

Either way, a rare is only flagged when the mount is genuinely uncollected **and** the rare hasn't already given its daily kill credit — no being called over for something you can't loot today.

### Commands

- `/mcg rares` — turn the alerts on or off (it'll tell you which mode it's in)
- `/mcg raretest` — preview the alert so you can position it without waiting for a spawn

## 3.6.1

### Tooltips no longer say it twice

The **Hexflame Reaver**, **Untainted Grove Crawler** and **Spirit of Tok'jara** notes were written back when the note was the only place instructions could live. Now that those mounts carry step chains, their card was listing the steps under "Extra Steps" and then repeating them word for word under "How to Get".

Each note is trimmed to what the steps can't say — where the drop actually comes from, and what gates it — and the instructions are left to the chain.

## 3.6.0

### Guided routes

A treasure achievement is two dozen pins scattered across a zone, and walking them in whatever order you happen to spot them is a lot further than it needs to be.

**Shift-click any pin** of a multi-location find — a treasure achievement, a zone's rare pool — and the guide plans a route through everything you still need, nearest-first from wherever you're standing.

- Shows **one stop at a time**: its name, its coordinates, waypointed and ready
- **Advances by itself** as each treasure is looted
- The **arrows skip along the route** when you'd rather take a different one
- Looted treasures and rares already killed today drop off it entirely
- Stops that carry an unlock chain are starred — right-click one to open that chain, with a way back to the route

The route is re-planned every time you open it, so wandering off-order costs nothing.

### The guide window, rebuilt

Title bar, the mount being guided with its icon and how much is left, a nav strip that only appears when there's somewhere to navigate, rows as banded cards with a heading and a detail line, and a progress bar along the bottom.

- Row state reads from an **accent stripe** down the left edge rather than a loud coloured band
- Finished steps **swap their number for a tick**
- Step numbers moved into their own gutter, so wrapped lines align with the text
- A chain that stays in one place no longer repeats that location under every step

### Fixes

- **Clicking a row did nothing.** The window sat at the same frame strata as the world map, so the map was taking the clicks meant for it.
- **Shift-clicking a pin dropped the waypoint at the cursor** instead of on the target, because the click carried on down to the map canvas underneath. Waypoints are now re-asserted a frame later so nothing else can quietly replace them.
- Treasure notes lost the paragraphs listing which treasures need extra work — the pins carry that themselves now.

## 3.5.0

### Treasures of Harandar

The achievement had no guide data at all. All nine treasures are now pinned and disappear as you loot them, and the four that need setting up carry full step chains:

| Treasure | What it takes |
| --- | --- |
| Gift of the Cycle | Ball, knife and pillow returned to three altars |
| Impenetrably Sealed Gourd | Red + purple fluid mixed at the Durable Vase |
| Sporespawned Cache | Fungal Mallet buff, then ring the Mycelium Gong |
| Peculiar Cauldron | 150 Crystalized Resin Fragments |

Two of those hand out mounts of their own — the Peculiar Cauldron gives the **Ruddy Sporeglider**, the Sporespawned Cache the **Untainted Grove Crawler** — so those entries carry the same chain and now retire their pin once looted.

### Every 12.0 rare pool

Eight mounts that previously had no coordinates at all now list every rare that can drop them, with per-day kill credit — a rare you've already killed today greys out and comes back at reset.

| Zone | Rares | Mounts |
| --- | --- | --- |
| Harandar | 15 | Rootstalker Grimlynx, Vibrant Petalwing |
| Eversong Woods | 15 | Cerulean Hawkstrider, Cobalt Dragonhawk |
| Zul'Aman | 15 | Amani Sharptalon, Witherbark Pango |
| Voidstorm | 14 | Augmented Stormray, Sanguine Harrower |

### Three more step chains

- **Ancestral War Bear** — the Honored Warrior's Cache and its four Chosen tokens
- **Hexflame Reaver** — unlocking Nightmare mode and summoning Ral'kala
- **Spirit of Tok'jara** — six time-gated quests, one a day

That last one needed a new kind of trigger, so steps can now complete on quest completion as well as on items and buffs.

### On the map

- **Rare pin toggle** in the map toolbar, for when a zone's dozen-plus rare pins are in the way
- **A star** on any pin whose location carries a chain, so it's obvious which ones open a tracker

### Localisation

Every remaining gap closed — all 11 locales are now at parity with English.

## 3.4.0

### Step-by-step guides for treasures that need them

Seven of the 22 Treasures of the Coiled Isle can't just be walked up to and clicked — they want a key assembled, a puzzle solved, or an NPC chain finished first. Those now come with proper instructions.

**On the map.** Hover a treasure pin and the card lists the whole unlock chain. Every spot the chain sends you to is drawn on the map as a numbered marker.

**The step tracker.** Left-click one of those pins and a movable window opens with one row per step. Left-click a row to waypoint that spot, right-click to tick it off by hand. It waypoints the first outstanding step when it opens, and moves on as you go.

**Steps that tick themselves off.** Progress is detected from whatever the game exposes — an item landing in your bags, a buff going up, the treasure's own tracking quest completing. Conversation-only steps are right-click ticks, and because a chain is ordered, finishing any later step sweeps up everything before it.

The seven chains: Amani Privateer's Cache · Sunken Diver's Chest · Profane Ritual Spoils · Lost Spirit · Vul'zahn's Smuggled Treasure · Grave of Someone Forgotten · Brine-Crusted Chest

### Also

- The mount card picks whichever corner of a pin covers the fewest markers, instead of always sitting top-right
- `/mcg debugspent` keeps pins for treasures you've already looted, greyed out and labelled, for checking a finished run

---

Older releases: https://github.com/Camyana/MCL/releases
