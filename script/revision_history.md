# **V1.00.04:**
2025/10/14

---


## **Add:**# 
- add snake game and minesweeper mini game

## **Remove:**
- remove

## **Modify:**
- pause the game when skill tree opened

## **Balance:**
- 

## **Plan:**

---

# **V1.00.03:**
2025/10/13

---


## **Add:**# 
- add release villager function and animation
- disable faction bonus menu when game started
- add population refresh when sell chess

## **Remove:**
- remove

## **Modify:**
- fix dwarf king passive ability cannot trigger issue

## **Balance:**
- update faction level criteria for enemy generation

## **Plan:**

---


**V1.00.02:**
2025/10/11

---


## **Add:**
- add enemy faction predictor
- if current faction path level < current faction level, faction bonus bar frame becomes grey

## **Remove:**
- remove

## **Modify:**
- modify chess sell price from 3 to chess_level + 1
- complete every effect icon
- modify chess turn end check: if only on team chess remaning, round will finish
- modify path dictionary from faction_path_update to faction_path_upgrade
- change arrow sprite

## **Balance update:**
- human Kingman and PrinceMan will not generate phantom when attcking phantoms

## **Plan:**
- add villager passive effect:
-- VillagerMan	price = 1, release to tetrix game (Done, wait add animation)
-- VillagerWoman	price = 1, release to tetrix game (Done, wait add animation)
-- OldMan	gain 1 knowledge point when relased (Done, wait add animation)
-- OldWoman	+30% chance to get same chess when shop refresh (Done, wait add animation)
-- Peasant	+1 coin every 2 turn (Done, wait add animation)
-- Worker	
-- NobleMan	can get enemy real faction number (Done, wait add animation)
-- NobleWoman	refresh shop with higher level chess when released  (Done, wait add animation)
-- Nun	add a phantom to arena when friendly chess died
-- Thief	gain 1 coin from player before turn start and give back to player 150% when released
-- Gatherer	
-- GraveDigger	replaced by last turn highest hp died enemy chess when released
-- Hunter	enemy chess gain hunter mark when game start (Done)
-- Lumberjack	
-- Merchant	gain 3 free refresh count when released (Done, wait add animation)
-- Miner	30% gain 1 gem each turn (Done, wait add animation)
-- SuspiciousMerchant released turn refresh price +1, buy chess price -1 (Done, wait add animation)	
-- Anvil	
-- Blacksmith	 all ally chess with upgrade version will become upgraded chess for 1 round (Done, wait add animation)
-- Princess	+2 max population (Done, wait add animation)
-- Queen	change chess active sequence


---


# **V1.00.01:**
2025/10/10

---


## **Add:**
- add enemy faction bonus predictor from intelligent enemy generation result
- add shop free refresh count mechanism
- add shop upgrade price decrease by round mechanism
- add effective date for game, after the date game will be frozen
- add faction bonus bar highlight when chess raised(wait theme color)
- add effect animation when merged(wait choose icon)
- add villager checker for villager effect
- add gem count in data manager

## **Remove:**
- remove remain coin label shaking after shop refreshed

## **Modify:**
- after chess move faction bonus will refresh for human population benefit
- modify obstacle effect animation display function for correct position
- modify dward demolitionist boom target judgement function
- modify shop upgrade prize from level + 2 to level + 5, but will decreased by 1 each turn
- modify shop handler refresh level to a specific input
- modify chess sell price from 3 to chess_level + 1
- complete every effect icon

## **Balance update:**
- dwarf demolitionist boom level change from 1 to chess_level + 1 to add boom damage area
- human and elf sun strike spell will have 50% ratio does not cast each enemy chess

## **Plan:**
- change arrow sprite
- add villager passive effect:
-- VillagerMan
-- VillagerWoman
-- OldMan	gain 1 knowledge point when relased (Done, wait add animation)
-- OldWoman	+30% chance to get same chess when shop refresh (Done, wait add animation)
-- Peasant	+1 coin every 2 turn (Done, wait add animation)
-- Worker	
-- NobleMan
-- NobleWoman	refresh shop with higher level chess when released (Done, wait add animation)
-- Nun	add a phantom to arena when friendly chess died
-- Thief	gain 1 coin from player before turn start and give back to player 150% when released
-- Gatherer	
-- GraveDigger	replaced by last turn highest hp died enemy chess when released
-- Hunter	enemy chess gain hunter mark when game start
-- Lumberjack	
-- Merchant	gain 3 free refresh count when released (Done, wait add animation)
-- Miner	30% gain 1 gem each turn (Done, wait add animation)
-- SuspiciousMerchant 
-- Anvil	
-- Blacksmith	
-- Princess	+2 max population (Done, wait add animation)
-- Queen	
- enemy faction bonus
