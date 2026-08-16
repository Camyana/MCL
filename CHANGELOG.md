# Changelog

## 3.10.3

### Fixes

- **Opening the character sheet could throw an error naming MCL.** Registering the window so Escape would close it meant writing into one of the game's own tables, which spoils it for everything else that reads it afterwards — and in Midnight that turns into errors in places with nothing to do with MCL. Escape still closes the window; MCL just handles the key itself now and leaves the game's tables alone.

## 3.10.2

### Clicking a rare alert sets a waypoint

It used to try to target the rare as well. Midnight no longer lets addons do that — the game refuses the attempt and reports MCL for it — so the alert has stopped trying and now says what it actually does. Clicking still points you at the rare, and right-click still dismisses.

This is the third thing Midnight has closed off here, after raid markers and readable creature IDs. Nothing is lost that was working; the error log is quieter for it.

## 3.10.1

### Fixes

- **Pressing Escape reported an error and blamed MCL.** Registering the ignore-list confirmation touched a Blizzard table in a way that spoiled it for everything else reading it afterwards, and the game menu is one of those things. Anyone on 3.10.0 should update.
- **The rare alert could leave an invisible copy of itself behind.** Hovering where it had been brought its tooltip back with nothing on screen. The alert can't be closed while you're in combat — which is exactly when it usually expires, since you're fighting the rare — so it now falls silent straight away and closes properly once the fight ends.

## 3.10.0

### Rares you'd rather not hear about

Tame a rare as a hunter pet and it keeps its name, so MCL kept announcing it every time its nameplate came back — and then pointed a waypoint at your own pet. Anything under a player's control is no longer treated as a rare, so that stops on its own.

For every other reason to want one quiet, there's now an ignore list:

- **Shift-right-click an alert** and confirm, to stop hearing about that rare
- **Settings → Rare Mount Alerts** names everything on the list, with a **Clear** button
- `/mcg rareignore <name>` toggles one, `/mcg rareignored` lists them

Ignoring silences the alert only — the rare still appears on the map and in routes, since it's still a way to get a mount you don't have.

### New mounts

- Rabbit'ath — BlizzCon 2026 bundles
- Umbral Ashes — Umbral Champion: Midnight Season One

### Fixes

- Right-clicking the alert to dismiss it only worked on the edges; the middle of the card ignored it
- Dismissing no longer targets the rare on the way out

## 3.9.2

### Fixes

- **Thousands of errors a session.** Creature IDs are read from a unit's GUID, and in Midnight that GUID comes back as a value addons aren't allowed to read. Every nameplate and every target change tried anyway. All the paths that read a unit's name, GUID or state now check first, and a value they can't read simply means the alert works from the name instead.
- **The route's `<` and `>` arrows did nothing** and threw an error each time they were clicked.
- **The rare alert left something behind.** After it faded, the space it occupied still answered the mouse, showing its tooltip over empty screen. It now stops listening the moment it goes, whatever made it go.
- **Lucent Hawkstrider** listed its dungeon where its boss should be. It drops from Degentrius.

## 3.9.1

### The route is a loop, and the map shows it

Shift-clicking a pin plans a run round a zone's rares or treasures. That run is now drawn on the world map as a connected loop, so you can see the shape of it rather than reading one stop at a time.

- The route is planned as a **circuit**, not a one-way trip — the walk back to the start counts, and is optimised along with everything else
- Crossings are gone: an improvement pass reworks the order until no two legs cross, which on the Coiled Isle cuts about a quarter off the distance
- The leg you're on is highlighted; legs already walked go grey
- A line on the **minimap** points at the stop you're heading for, so you don't need the map open to follow the route

The plan is now made once and walked, instead of being rebuilt every few seconds. It was anchored to wherever you were standing, so walking reshuffled the order underneath you.

### The route moves on by itself

Reaching a stop advances the route to the next one, whether or not anything was there. Walking to a rare that hasn't spawned no longer leaves you parked on a waypoint that will never clear.

The waypoint also clears itself once you arrive, and when the rare dies — including when somebody else kills it.

### Finishing empty-handed

Walking the whole loop and getting nothing now says so, with the time until the next daily reset, rather than the window quietly reading "0 to go".

### Rare locations corrected

Rare locations were checked against the game's own data. Eleven were wrong:

- **Lady Liminus** carried Garsecg's kill credit, so killing either marked both done for the day — dropping a rare you hadn't touched off your route and silencing its mount alert
- **Nar'zira** had the coordinates of its other spawn zone, putting its pin a long way from where it actually appears on the Coiled Isle
- **Szarith the Fanged** was on the wrong map entirely, and has been removed — every mount it drops comes from eleven other rares in the same zone
- Eight more were off by up to three map units

### Fixes

- The guide window can be resized by dragging its right edge, and remembers the width
- Hovering a map pin no longer resets it mid-hover, which made tooltips impossible to read while a route was open
- The minimap line points *at* the waypoint rather than near it — the direction was being skewed by the zone's aspect ratio, which was also biasing which stop the route thought was nearest
- Map pins no longer fill the error log with blocked-action messages

## 3.9.0

### Five rares that never alerted, now do

The rare mount alert matches the name the game gives a rare against the name in MCL's data, exactly. Five of those names were stored short, so those rares were sighted and silently ignored:

- **Lockjaw** → Lockjaw the Snapper
- **Hisstara** → Hisstara the Raiser
- **Siltmouth** → Siltmouth, the Unflappable
- **Sss'alik** → Sss'alik, The Rotten Claw
- **Cre'van** → Cre'van, Cruel Taskmaster

All 71 rare names have been checked against the game's own vignette table. A name that doesn't match exactly now falls back to a prefix match at a word boundary, so a short name still works instead of failing silently.

### The alert, redesigned

The rare's model now stands above the card rather than clipping into it, framed as a bust so a long-tailed drake and a humanoid arrive at the same size — previously one filled the box and the other rendered as a speck. The card underneath:

- The rare's name as a headline, bracketed by hairlines, shrinking to fit rather than truncating mid-word
- A **RARE SIGHTING** label in the top band, alongside a proper dismiss button
- Larger, brighter instruction and reward text — both were close to unreadable at their old size
- Mount rewards sit in framed wells; hovering one names it on the reward line and shows its full tooltip
- A drop shadow, so the card doesn't disappear into a dark zone
- A rule along the bottom edge draining over the alert's life, so you can see it about to go

### The waypoint retires itself

Clicking a rare alert sets a waypoint. That waypoint now clears when you get there — within 40 yards — as well as when the rare dies, including when somebody else kills it. **Clear the waypoint on arrival** in Rare Mount Alerts turns it off. Only waypoints MCL set are ever cleared; if you've pointed somewhere else since, yours is left alone.

### Fixes

- The alert's click target no longer sits under the mount icons, which were swallowing clicks meant for targeting
- Fixed a crash when showing a rare whose model was still loading
- Map pins no longer flood the error log with blocked-action messages, once per pin drawn
- Raid marking removed. It never worked: the game refuses the call from an addon in any form, and every attempt only added an error to the log
- `/mcg raredebug` now distinguishes a rare MCL has no record of from one whose mounts you've already collected or looted today

## 3.8.0

### Settings for everything the guide has grown

The guide picked up a lot recently — step chains, routes, pin stars, rare alerts — and most of it had no home in the settings panel. Now it does.

**Map Pin Options** gains two switches that were previously only reachable from the map toolbar, or not at all:

- **Show Rare Pins** — a zone's rare pool is a dozen-plus pins; turn them off when they're in the way
- **Star pins with a guide** — the star marking locations that open a step-by-step tracker

**Guide Window** is a new section for the step and route window:

- **Show numbered step markers** — the numbered spots drawn on the map for a chain
- **Window Size** — 0.5× to 2×
- **Reset Position**

**Rare Mount Alerts** is a new section too:

- **Enable**, and **Play a sound** — ticking the sound plays it, so you can hear what you've chosen
- **Alert Size** — 0.4× to 1.5×
- **Move Alert** — parks the alert on screen with a sample in it so you can drag it where you want; alerts are too brief to aim otherwise
- **Reset Position**

### The alert is smaller, and audible with RareScanner

The alert now defaults to **70% size** — it was generous at full scale — and the slider above covers the rest.

It also plays its cue when RareScanner is doing the detecting. RareScanner beeps for every rare it finds; this is the second, distinct cue that means the one in front of you is actually carrying a mount you don't have.

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
