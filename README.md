# qb-blackmarket

A simple blackmarket script for QBCore Framework that allows players to purchase illegal items through an NPC dealer with a delivery system.

## Features

- Contact NPC dealer to browse and order items
- Shopping cart system to add multiple items
- Delivery system - NPC delivers items to random locations
- Configurable items, prices, and delivery locations

## Dependencies

- qb-core
- qb-menu
- qb-target
- qb-input
- qb-inventory

## Installation

1. Place the script in your `resources` folder
2. Add `ensure qb-blackmarket` to your `server.cfg`
3. Configure items and locations in `config/config.lua`

## Configuration

Edit `config/config.lua` to customize:
- NPC location and model
- Available items and prices
- Delivery locations
- Contact fee and wait time
