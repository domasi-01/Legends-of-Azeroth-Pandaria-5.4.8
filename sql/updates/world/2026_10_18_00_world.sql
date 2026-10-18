-- RW-FIX-015
-- Quest 13628 - Got Wood?
-- Restore Brutusk vehicle transport from Mor'shan Rampart
-- to Warsong Labor Camp.

-- Static Brutusk handles the player's spell-click and summons
-- the actual vehicle version.
UPDATE `creature_template`
SET
    `AIName` = '',
    `ScriptName` = 'npc_brutusk_static'
WHERE `entry` = 33374;

-- Entry 33386 is the actual vehicle (VehicleId 360) used for the ride.
UPDATE `creature_template`
SET
    `AIName` = '',
    `ScriptName` = 'npc_brutusk_transport'
WHERE `entry` = 33386;

-- Remove the obsolete SmartAI kill-credit implementation.
-- Quest credit is awarded by spell 62890 after successful boarding.
DELETE FROM `smart_scripts`
WHERE `entryorguid` = 33374
  AND `source_type` = 0;

-- Rebuild the escort route for the temporary vehicle.
DELETE FROM `script_waypoint`
WHERE `entry` = 33386;

INSERT INTO `script_waypoint`
(`entry`, `pointid`, `location_x`, `location_y`, `location_z`, `waittime`, `point_comment`)
VALUES
(33386,  1, 1194.286499, -2256.571289, 91.672813, 0, 'Brutusk - start'),
(33386,  2, 1194.046021, -2261.096191, 91.729004, 0, 'Brutusk - road'),
(33386,  3, 1308.469971, -2222.044678, 91.675018, 0, 'Brutusk - road'),
(33386,  4, 1323.392944, -2258.060059, 91.496376, 0, 'Brutusk - road'),
(33386,  5, 1421.930420, -2254.265625, 89.923393, 0, 'Brutusk - road'),
(33386,  6, 1457.784546, -2315.010986, 90.113564, 0, 'Brutusk - road'),
(33386,  7, 1498.168457, -2378.141846, 93.969345, 0, 'Brutusk - road'),
(33386,  8, 1516.541870, -2395.393799, 95.034431, 0, 'Brutusk - road'),
(33386,  9, 1581.447388, -2448.803711, 97.991043, 0, 'Brutusk - road'),
(33386, 10, 1580.949951, -2505.699951, 98.132401, 0, 'Brutusk - Warsong Labor Camp');
