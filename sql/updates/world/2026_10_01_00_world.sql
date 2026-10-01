-- Realmwalkers: Restore classic Horde Zeppelin tracker gossip.
--
-- Menu 8766 is the Grom'gol <-> Undercity Zeppelin status menu.
-- The Undercity arrival text exists in npc_text but is missing from
-- gossip_menu.
INSERT INTO gossip_menu (MenuID, TextID, VerifiedBuild)
SELECT 8766, 11179, 0
WHERE NOT EXISTS
(
    SELECT 1
    FROM gossip_menu
    WHERE MenuID = 8766
      AND TextID = 11179
);

-- Zapetta's "Where is the zeppelin now?" option has no destination menu
-- in the original data. Route it to the Grom'gol <-> Undercity tracker.
UPDATE gossip_menu_option
SET ActionMenuID = 8766
WHERE MenuID = 1971
  AND OptionID = 0
  AND ActionMenuID = 0;
