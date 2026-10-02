-- RW-FIX-013
-- Add a per-creature physical damage modifier for creatures that need
-- individual tuning outside of instance difficulty modifiers.

ALTER TABLE `creature_template`
    ADD COLUMN `DamageModifier` FLOAT NOT NULL DEFAULT 1 AFTER `Armor_mod`;

-- Jaomin Ro (54611) on the Wandering Isle is substantially overtuned
-- for the level 3 sparring encounter.
UPDATE `creature_template`
SET `DamageModifier` = 0.30
WHERE `entry` = 54611;

-- Remove the earlier test modifier. Jaomin is on a regular world map,
-- so DUNGEON_NORMAL is not selected for this encounter.
DELETE FROM `creature_template_difficulty`
WHERE `id` = 54611
  AND `difficulty` = 'DUNGEON_NORMAL';
