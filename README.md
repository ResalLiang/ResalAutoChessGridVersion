# Game Development Log

## Overview
This is a notepad for recording completed and incomplete features during game development.
Completed items start with **"✔️"** and incomplete items start with **"🕗"** .

## Feature List
### ⭐Start Scene
- ✔️ Title -Done, @2025/09/02
- ✔️ Start Game Button -Done, @2025/09/02
- ✔️ Options Button -Done, @2025/09/02
- ✔️ Game Codex Button -Done, @2025/09/02
- ✔️ Game Statistics Button -Done, @2025/09/02
- ✔️ Use virtual mouse to implement scene image transitions -Done, @2025/09/02
- 🕗 Game music & sound effects
- ✔️ Fixed game resolution
- ✔️ Save/Load functionality (username, achievement stats, dead piece statistics...) -Done, wait debug @2025/09/02
- 🕗 Meta progression effects, meta coins, upgrade starting coins, etc., unlock races
- ✔️ Current player name display
- ✔️ Current game version display

### ⭐Battle System
#### Basic Battle Buttons
- ✔️ Battle start button
- ✔️ Game restart button
- ✔️ Prioritize high HP action button
- ✔️ Prioritize low HP action button
- ✔️ Prioritize close to center action button
- ✔️ Prioritize away from center action button
- ✔️ Pause button (for inspecting AI piece properties)
- ✔️ Certain buttons should be disabled during gameplay

---

#### Piece Movement & Combat Logic
- ✔️ If target is within attack range, choose ranged or melee attack based on distance
- ✔️ Critical hit animation
- ✔️ When not dodged, deal damage to target and accumulate damage to piece MP
- ✔️ After attack, may trigger special effect interface (debuff, etc.) -Done @2025/08/28
- ✔️ If MP is full and has spell ability, cast spell and clear MP (hero spells not complete)
- ✔️ Buff/Debuff affects piece actions based on effects
- ✔️ In-battle summoning skill logic -Done @2025/08/28
- ✔️ Battle log recording functionality
- ✔️ Buff/Debuff status icon display
- 🕗 Critical/dodge/spell particle effects
- ✔️ Long press piece to show stats - Done @2025/08/28
- 🕗 Battle music and sound effects
- ✔️ Population limit system -Done @2025/08/29
- 🕗 New item logic (bombs, obstacles, pieces...) and usable items (potions...)
- ✔️ Display specific values in UI (including bonuses), terminology explanations (spd)
- ✔️ Change piece selection placement to click instead of drag, show movement direction with arrow at current mouse position

---

#### Win/Loss Conditions
- ✔️ Game ends when player achieves specified victory or defeat conditions

---

#### Synergy System
- ✔️ When pieces of the same faction reach specific numbers, trigger synergy effects (buffs or special attributes) -Done, wait debug @2025/08/29

---

### ⭐Waiting Area
- ✔️ Pieces in waiting area do not move or act
- ✔️ Pieces in waiting area do not count towards synergy abilities

---

### ⭐Shop System
- ✔️ Number and rarity of shop refresh pieces affected by shop level
- ✔️ Shop upgrade requires spending coins
- ✔️ Auto-refresh at end of each round if shop not locked -Done, @2025/08/28
- 🕗 Show synergy hints when buying pieces
- ✔️ Piece buy and sell effect interface

---

### ⭐Game End Scene
- ✔️ Show animation when game fails or succeeds
- ✔️ Game restart button
- ✔️ Data statistics scoring interface

---

### ⭐Options Scene
- 🕗 Faction unlock and selection
- ✔️ Difficulty adjustment
- 🕗 Volume settings
- ✔️ Game speed adjustment -Done, wait debug @2025/09/02

---

### ⭐Codex Scene
- ✔️ Obtained pieces are unlocked in codex, other pieces appear grayed out

---

### ⭐Statistics Scene
- ✔️ Track game time, victory count, purchased piece count -Done, wait debug @2025/09/02
- ✔️ Track each piece's purchase, sell, death, refresh count
- ✔️ Data reset button -Done, wait debug @2025/09/02
- 🕗 Mini-games (use killed enemy pieces for Tetris, card games, Minesweeper, create memorial for dead allied pieces)
