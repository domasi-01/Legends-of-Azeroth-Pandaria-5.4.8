-- RW-FIX-012
-- Wandering Isle sparring trainees:
--   * Remain passive while idle so nearby trainees do not join a spar.
--   * Switch to defensive when individually engaged.
--   * Yield at 10% health instead of requiring 0-1%.
--
-- Affected creatures:
--   54586 - Huojin Trainee
--   54587 - Tushui Trainee
--   65470 - Huojin Trainee
--   65471 - Tushui Trainee


-- ============================================================
-- Huojin Trainees: 54586 / 65470
-- ============================================================

UPDATE `smart_scripts`
SET
    `action_param1` = 0,
    `comment` = 'Huojin Trainee - Linked To Id 0 - Set React State Passive'
WHERE `source_type` = 0
  AND `entryorguid` IN (54586, 65470)
  AND `id` = 1
  AND `event_type` = 61
  AND `action_type` = 8;

UPDATE `smart_scripts`
SET `link` = 11
WHERE `source_type` = 0
  AND `entryorguid` IN (54586, 65470)
  AND `id` = 4
  AND `event_type` = 4
  AND `action_type` = 22;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` IN (54586, 65470)
  AND `id` = 11;

INSERT INTO `smart_scripts`
(
    `entryorguid`, `source_type`, `id`, `link`,
    `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`,
    `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_x`, `target_y`, `target_z`, `target_o`,
    `comment`
)
VALUES
(54586, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0,
 8, 1, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Huojin Trainee - Linked To On Aggro - Set React State Defensive'),

(65470, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0,
 8, 1, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Huojin Trainee - Linked To On Aggro - Set React State Defensive');

UPDATE `smart_scripts`
SET
    `event_param1` = 0,
    `event_param2` = 10,
    `comment` = 'Huojin Trainee - Between 0-10% Health - Combat Stop'
WHERE `source_type` = 0
  AND `entryorguid` IN (54586, 65470)
  AND `id` = 5
  AND `event_type` = 2
  AND `action_type` = 203;


-- ============================================================
-- Tushui Trainees: 54587 / 65471
-- ============================================================

UPDATE `smart_scripts`
SET
    `action_param1` = 0,
    `comment` = 'Tushui Trainee - Linked To Id 0 - Set React State Passive'
WHERE `source_type` = 0
  AND `entryorguid` IN (54587, 65471)
  AND `id` = 1
  AND `event_type` = 61
  AND `action_type` = 8;

UPDATE `smart_scripts`
SET `link` = 13
WHERE `source_type` = 0
  AND `entryorguid` IN (54587, 65471)
  AND `id` = 6
  AND `event_type` = 4
  AND `action_type` = 22;

DELETE FROM `smart_scripts`
WHERE `source_type` = 0
  AND `entryorguid` IN (54587, 65471)
  AND `id` = 13;

INSERT INTO `smart_scripts`
(
    `entryorguid`, `source_type`, `id`, `link`,
    `event_type`, `event_phase_mask`, `event_chance`, `event_flags`,
    `event_param1`, `event_param2`, `event_param3`, `event_param4`,
    `action_type`, `action_param1`, `action_param2`, `action_param3`,
    `action_param4`, `action_param5`, `action_param6`,
    `target_type`, `target_param1`, `target_param2`, `target_param3`,
    `target_x`, `target_y`, `target_z`, `target_o`,
    `comment`
)
VALUES
(54587, 0, 13, 0, 61, 0, 100, 0, 0, 0, 0, 0,
 8, 1, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Tushui Trainee - Linked To On Aggro - Set React State Defensive'),

(65471, 0, 13, 0, 61, 0, 100, 0, 0, 0, 0, 0,
 8, 1, 0, 0, 0, 0, 0,
 1, 0, 0, 0, 0, 0, 0, 0,
 'Tushui Trainee - Linked To On Aggro - Set React State Defensive');

UPDATE `smart_scripts`
SET
    `event_param1` = 0,
    `event_param2` = 10,
    `comment` = 'Tushui Trainee - Between 0-10% Health - Combat Stop'
WHERE `source_type` = 0
  AND `entryorguid` IN (54587, 65471)
  AND `id` = 7
  AND `event_type` = 2
  AND `action_type` = 203;
