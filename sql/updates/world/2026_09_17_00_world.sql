-- Quest 8490 - Powering our Defenses
-- Creature 16364 is summoned by the quest event and must not exist as a
-- permanent world spawn.

DELETE FROM `creature_addon` WHERE `guid` = 358705;
DELETE FROM `creature` WHERE `guid` = 358705;
