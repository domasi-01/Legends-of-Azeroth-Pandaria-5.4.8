# Realmwalkers - Local Feature Log

This document tracks intentional Realmwalkers-specific source behavior that
differs from Legends-of-Azeroth upstream policy.

These changes are not classified as upstream defect fixes.

## Policy

- Keep Realmwalkers-specific behavior separate from upstream bug fixes.
- Keep each feature small and isolated.
- Document why the behavior is intentionally different.
- Test each feature independently where practical.
- Keep each feature in its own Git commit whenever practical.

---

# RW-FEATURE-001
## Prevent Playerbots from earning achievements

### Status
Realmwalkers policy feature - Playerbot side runtime-validated.

### Component
Achievements / Playerbots

### File

`src/server/game/Achievements/AchievementMgr.cpp`

### Realmwalkers Policy

Only human players should earn achievements on Realmwalkers.

Playerbots must not:

- accumulate achievement criteria progress
- complete achievements
- receive achievement rewards through achievement completion

Playerbot identity is determined through:

`WorldSession::IsBot()`

Account naming conventions such as `RNDBOT` are not used as the runtime
identity mechanism.

### Implementation

Bot-session guards were added to three achievement paths:

1. `AchievementMgr::UpdateAchievementCriteria(...)`
2. `AchievementMgr::SetCriteriaProgress(...)`
3. `AchievementMgr::CompletedAchievement(...)`

Each path returns without modifying achievement state when the reference player
has a session for which:

`GetSession()->IsBot()`

returns true.

### Dependency

Runtime validation of this feature exposed upstream defect RW-FIX-004.

Prior to RW-FIX-004, Playerbot WorldSession constructor calls accidentally left
the `isBot` constructor argument at its default value of false.

After RW-FIX-004 corrected Playerbot session identity, these achievement guards
began operating as intended.

### Test Baseline

Before final Playerbot runtime validation:

- stale TEST account and characters were removed
- orphan character data was removed
- all RNDBOT character achievement rows were cleared
- all RNDBOT account achievement rows were cleared
- DOMASI was the only non-RNDBOT account
- DOMASI account achievement completions were 0
- DOMASI account achievement progress rows were 0

### Build Validation

Worldserver rebuilt successfully.

Binary:

`/srv/realmwalkers-mop/build/src/server/worldserver/worldserver`

SHA256:

`0bb6e1faadf643567670c4df5248c60b6a2f1bc43d53fedb0508a70a72a73644`

### Runtime Validation

The rebuilt worldserver initialized successfully with:

- 200 random bot accounts
- 2200 available Playerbot characters
- exactly 50 RNDBOT characters online

Immediately after startup:

- bot character completed rows: 0
- bot character progress rows: 0
- bot account completed rows: 0
- bot account progress rows: 0

After an additional five-minute runtime test:

- 50 RNDBOT characters remained online
- bot character completed rows remained 0
- bot character progress rows remained 0
- bot account completed rows remained 0
- bot account progress rows remained 0
- worldserver remained active
- no relevant kernel errors occurred

### Human Validation

Human achievement behavior was explicitly validated in-game using Artemis,
GUID 2206, on the DOMASI account (account 204).

The test began with:

- character completed achievements: 0
- character achievement progress rows: 0
- account completed achievements: 0
- account achievement progress rows: 0

Artemis was advanced from level 1 to level 10 through the normal level-change
achievement path.

The client reported:

`[Artemis] has earned the achievement [Level 10]!`

Database verification after the level change showed:

- Artemis level: 10
- character completed achievements: 1
- completed achievement ID: 6
- character achievement progress rows: 27
- DOMASI account completed achievements: 1
- DOMASI account achievement progress rows: 2

During the same test, Playerbots remained active and all Playerbot achievement
counts remained zero:

- bot character completed rows: 0
- bot character progress rows: 0
- bot account completed rows: 0
- bot account progress rows: 0

This confirms that normal human achievement processing remains functional while
Playerbot achievement processing is blocked.

### Validation Result

RW-FEATURE-001 is fully runtime-validated.

Human players continue to receive normal achievement progress and completions,
while Playerbots do not generate character or account achievement data.

---
