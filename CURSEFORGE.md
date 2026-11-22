# CurseForge texts

## Summary

See which features your WoW Forever camp has and the buff each one gives you, the moment you arrive.

## Description

# Camp Info Forever

**Know your camp at a glance.** When you walk into a player-built camp in WoW Forever, Camp Info Forever opens a small panel. It shows which camp features are active, the exact buff each one gives you, and what the camp is still missing.

No more hovering over the Camp Benefits buff and reading long tooltips.

---

## Features

- **Automatic camp detection.** The panel opens when you reach a camp, and again when a new feature starts giving you a buff. It closes when you leave.
- **Real numbers for your level.** Values come straight from the game's own Camp Benefits aura, for example *Lodestone: Melee Attack Power +20*.
- **What's missing.** Features this camp doesn't have yet are listed in grey. You can turn this off with *Show only available buffs*.
- **Outdoor camps only.** The panel doesn't open by itself in capital cities, dungeons or raids. You can allow capital cities in the settings.
- **Share in chat.** One click posts the camp's buffs, or asks your group who can build the missing features.
- **`!camp` replies (optional).** Anyone who whispers you `!camp` gets the camp info back.
- **Group announce (optional).** Tells your party or raid about the camp when you arrive, at most once every 5 minutes per place.
- **Compact mode, panel scaling, position lock and arrival sound.**
- **11 languages.**

## Supported camp features

| Feature | Buff |
|---|---|
| Lodestone | Melee Attack Power |
| First Aid Kit | Stamina |
| Sharpening Wheel | Strength |
| Incense Candle | Intellect |
| Faction Banner | Spirit |
| Camp Chair | Critical strike chance |
| Fish Bowl | All stats (%) |
| Enchanted Lute | Armor, all attributes and all resistances |
| Mana Well | Mana every 5 seconds |
| Violet Flames | Campfire effects last longer |

The addon also lists features it doesn't know yet, as long as the game shows them in the Camp Benefits tooltip.

## Commands

| Command | What it does |
|---|---|
| `/cif` | Show or hide the panel |
| `/cif options` | Open the settings |
| `/cif reset` | Reset the panel position |
| `/cif debug` | Print the camp buff data to chat (useful for bug reports) |

`/campinfo` works too. You can also open the panel from the Addon Compartment menu next to the minimap.

## Settings

Find them under *Options › AddOns › Camp Info Forever*:

- **General:** open on arrival, also in capital cities, show only available buffs, auto-hide and its delay (5–60 seconds).
- **Appearance:** panel size (70%–150%), compact mode, lock position, sound on arrival.
- **Chat and sharing:** print to your own chat, announce to group, `!camp` replies, share channel (automatic, party, raid, guild or say).

## Languages

The addon's text is translated into these languages:

- English
- Türkçe
- Deutsch
- Français
- Español
- Português (BR)
- Русский
- Italiano
- 한국어
- 简体中文
- 繁體中文

Feature and buff names come from the game itself, in your client's language.

## Feedback

Found a camp feature that isn't listed, or a translation that could be better? Open an issue on [GitHub](https://github.com/simsekahmett/campinfo-forever). If you can, include the output of `/cif debug` taken while you stand in the camp.
