# Realmwalkers - Legends of Azeroth Upstream Fix Log

This document tracks source-level changes made by the Realmwalkers project
against the Legends-of-Azeroth Pandaria 5.4.8 upstream source.

## Policy

- Deviate from upstream only when required to correct a confirmed defect.
- Keep each fix as small and isolated as possible.
- Do not mix unrelated cleanup or refactoring into a fix.
- Document evidence before making the source change.
- Test each change independently.
- Keep each fix in its own Git commit whenever practical.
- Preserve enough information for the issue and patch to be reported upstream.

---

# RW-FIX-001
## Playerbots random character creation divide-by-zero

### Status
Confirmed upstream defect - patched and runtime-validated.

### Component
Playerbots

### Files

- `modules/mod_playerbots/src/Factory/RandomPlayerbotFactory.cpp`
- `src/server/game/DataStores/DBCStores.h`

### Symptom

Worldserver crashes while Playerbots creates random characters.

Observed Linux kernel error:

`trap divide error`

Crash address resolves inside:

`RandomPlayerbotFactory::CreateRandomBot(...)`

Disassembly at the crash shows an integer division where the divisor is zero.

### Root Cause

The core defines two CharSections DBC stores:

- `sCharSectionsStore`
- `sChrSectionStore`

`CharSections.dbc` is loaded into:

`sCharSectionsStore`

However, Playerbots reads character appearance data from:

`sChrSectionStore`

The `sChrSectionStore` object is never populated.

As a result, Playerbots finds no appearance records and creates empty vectors for:

- skin colors
- faces
- hair
- facial hair

Random character creation subsequently executes modulo operations using the
size of these vectors. A zero-sized vector results in integer divide-by-zero.

### Evidence

`src/server/game/DataStores/DBCStores.cpp`

Defines:

`DBCStorage <CharSectionsEntry> sCharSectionsStore(CharSectionsEntryfmt);`

and separately:

`DBCStorage <CharSectionsEntry> sChrSectionStore(CharSectionsEntryfmt);`

The DBC loader loads only:

`LOAD_DBC(..., sCharSectionsStore, ..., "CharSections.dbc");`

Playerbots uses:

`for (uint32 index = 0; index < sChrSectionStore.GetNumRows(); ++index)`

and:

`const CharSectionsEntry* charSection = sChrSectionStore.LookupEntry(index);`

Repository search confirmed no loader exists for `sChrSectionStore`.

### DBC Validation

Freshly extracted MoP 5.4.8 build 18414 `CharSections.dbc` was verified:

- Magic: WDBC
- Records: 16610
- Fields: 10
- Record size: 40
- String block size: 598869
- Total file size exactly matches calculated DBC size

Playable race/gender combinations contain valid Skin, Face and Hair records.
The DBC itself is not missing the required appearance data.

### Applied Fix

Playerbots now uses the already-loaded canonical:

`sCharSectionsStore`

instead of the unused:

`sChrSectionStore`

Because `sCharSectionsStore` was not exported in `DBCStores.h`, the existing
canonical store was also added to that header.

The unused duplicate `sChrSectionStore` definition/declaration was deliberately
left untouched. Removing it would be unrelated cleanup and should be handled
separately if desired.

### Build Validation

Worldserver rebuilt successfully from the patched source.

Build result:

- Exit code: 0
- Binary:
  `/srv/realmwalkers-mop/build/src/server/worldserver/worldserver`
- SHA256:
  `6b06e022f74f20459a3f55f6b2814d6ff166622a53dec94d3d488e89e77e9fc3`

### Runtime Validation

The patched worldserver was run directly against the staged fresh MoP 5.4.8
build 18414 extracted data.

The original divide-by-zero was not reproduced.

Playerbots progressed successfully through random-character initialization and
reported:

- 200 random bot accounts
- 1692 characters available
- 63 farming cache zones loaded
- 1230 farming spots loaded
- 123 city zones loaded
- `AI Playerbots initialized`

This confirms that random Playerbot character creation progressed past the
previous `rand() % 0` crash and that the corrected CharSections store is being
used successfully.

The test worldserver later encountered a separate null-pointer crash in:

`GameEventMgr::RunSmartAIScripts(uint16, bool)`

That crash occurred only after Playerbots had fully initialized and is being
tracked independently as RW-FIX-002. It is not considered a failure of
RW-FIX-001.

### Validation Result

RW-FIX-001 is considered runtime-validated.

The production source diff for this fix contains only:

1. Export of the already-existing loaded `sCharSectionsStore`.
2. Two Playerbots references changed from `sChrSectionStore` to
   `sCharSectionsStore`.

No unrelated cleanup or refactoring is included.

### Upstream Reporting

Prepare issue/PR for Legends-of-Azeroth after successful Realmwalkers testing.

---

# RW-FIX-002
## Game event GameObject AI null-pointer dereference

### Status
Confirmed upstream defect - patched and runtime-validated.

### Component
Game Events / GameObject AI

### File
`src/server/game/Events/GameEventMgr.cpp`

### Symptom

Worldserver crashes during startup after Playerbots initialization.

The crash resolves inside:

`GameEventMgr::RunSmartAIScripts(uint16, bool)`

Disassembly at the crash shows a pointer loaded from the GameObject AI member and
then dereferenced while null.

### Root Cause

`GameEventAIHookWorker` visits active GameObjects and invokes:

`p.second->AI()->OnGameEvent(_activate, _eventId);`

without checking whether `GameObject::AI()` returned a valid pointer.

However, `GameObject::AI()` simply returns `m_AI`, and GameObject AI
initialization explicitly permits this value to remain null.

`GameObject::AIM_Initialize()` assigns:

`m_AI = FactorySelector::SelectGameObjectAI(this);`

and then immediately checks:

`if (!m_AI) return false;`

Therefore a GameObject that is in the world may legitimately have no AI
instance.

### Evidence

The creature branch of the same worker protects its AI call with
`IsAIEnabled`.

The GameObject branch currently checks only:

`p.second->IsInWorld()`

before dereferencing its AI pointer.

The crash assembly is consistent with a null `GameObjectAI*` dereference.

The core also contains multiple examples where callers explicitly test
GameObject `AI()` before use.

### Applied Fix

Guard the GameObject AI pointer before invoking `OnGameEvent()`.

No GameObject construction behavior, event logic, database content, or AI
selection logic is changed.

### Build Validation

Worldserver rebuilt successfully from the patched source.

Build result:

- Exit code: 0
- Binary:
  `/srv/realmwalkers-mop/build/src/server/worldserver/worldserver`
- SHA256:
  `68e3a5982f3226ca3f5e3b7a712c0a72e1118b2d8e155d47ca1ff641fb876047`

### Runtime Validation

The patched worldserver was started as the `realmwalkers` service account using:

`/etc/realmwalkers-mop/worldserver-test.conf`

and the staged fresh MoP 5.4.8 build 18414 extracted data.

The previous crash in:

`GameEventMgr::RunSmartAIScripts(uint16, bool)`

was not reproduced.

Playerbots initialized successfully and reported:

- 200 random bot accounts
- 1996 characters available
- 63 farming cache zones
- 1230 farming spots
- 123 city zones
- `AI Playerbots initialized`

Startup continued beyond the previous crash through SmartAI, calendar,
archaeology, battle pet, Battle Pay, and challenge-mode initialization.

After the startup test window:

- worldserver remained running
- TCP port 8085 was listening on `0.0.0.0`
- no GameEventMgr crash was detected
- no kernel crash event was reported for the test

### Validation Result

RW-FIX-002 is considered runtime-validated.

The source change is limited to guarding the potentially null `GameObjectAI*`
before invoking `OnGameEvent()`.

No GameObject construction behavior, event logic, database content, or AI
selection behavior was changed.

### Upstream Reporting

Prepare issue/PR for Legends-of-Azeroth after successful Realmwalkers testing.

---

# RW-FIX-004
## Playerbots fail to identify WorldSession as a bot session

### Status
Confirmed upstream defect - patched and runtime-validated.

### Component
Playerbots / WorldSession

### Files

- `modules/mod_playerbots/src/Factory/RandomPlayerbotFactory.cpp`
- `modules/mod_playerbots/src/Manager/PlayerbotMgr.cpp`

### Symptom

Playerbots successfully logged into the world, but calls to:

`WorldSession::IsBot()`

returned false for Playerbot sessions.

This caused code that depends on explicit bot-session identity to treat
Playerbots as normal player sessions.

The problem became visible while implementing Realmwalkers feature
RW-FEATURE-001. Despite achievement guards checking `IsBot()`, active
Playerbots continued to create character and account achievement data.

### Root Cause

The `WorldSession` constructor ends with:

`uint32 recruiter, uint32 flags, bool isARecruiter, bool hasBoost, bool isBot = false`

The Playerbots constructor calls supplied only four arguments after the locale:

`0, false, false, true`

These were therefore interpreted as:

- recruiter = 0
- flags = 0
- isARecruiter = false
- hasBoost = true
- isBot = omitted and therefore false

As a result, Playerbot sessions were unintentionally created with:

- `hasBoost = true`
- `isBot = false`

### Evidence

The constructor initializes:

`_isBot{isBot}`

and `WorldSession::IsBot()` returns that value.

Both affected Playerbot call sites omitted the explicit fifth argument needed
to set `isBot`.

Before the fix, active Playerbots generated achievement data even though
Realmwalkers achievement guards explicitly rejected sessions for which
`IsBot()` returned true.

### Applied Fix

Add one explicit `false` argument before the final `true` at both Playerbot
WorldSession construction sites.

The corrected argument sequence is:

`0, false, false, false, true`

This maps to:

- recruiter = 0
- flags = 0
- isARecruiter = false
- hasBoost = false
- isBot = true

No unrelated Playerbot behavior or WorldSession logic is changed.

### Build Validation

Worldserver rebuilt successfully from the patched source together with the
separately tracked Realmwalkers achievement feature.

Build result:

- Exit code: 0
- Binary:
  `/srv/realmwalkers-mop/build/src/server/worldserver/worldserver`
- SHA256:
  `0bb6e1faadf643567670c4df5248c60b6a2f1bc43d53fedb0508a70a72a73644`

### Runtime Validation

The rebuilt worldserver was started through:

`realmwalkers-world.service`

The running executable was independently verified through `/proc/<pid>/exe`
and matched the expected SHA256:

`0bb6e1faadf643567670c4df5248c60b6a2f1bc43d53fedb0508a70a72a73644`

Playerbots initialized successfully with:

- 200 random bot accounts
- 2200 characters available
- exactly 50 RNDBOT characters online

Before startup, all RNDBOT character and account achievement rows were cleared.

Immediately after startup:

- bot character achievements: 0
- bot character achievement progress: 0
- bot account achievements: 0
- bot account achievement progress: 0

After an additional five-minute runtime test:

- 50 RNDBOT characters remained online
- bot character achievements remained 0
- bot character achievement progress remained 0
- bot account achievements remained 0
- bot account achievement progress remained 0
- no relevant kernel crash, trap, OOM, or segfault event occurred

This demonstrates that Playerbot sessions now correctly satisfy `IsBot()` and
that bot-dependent logic can reliably distinguish them from human sessions.

### Validation Result

RW-FIX-004 is considered runtime-validated.

### Upstream Reporting

This is suitable for a focused Legends-of-Azeroth issue/PR because the defect
is contained entirely within the Playerbots WorldSession constructor calls.

---

# RW-FEATURE-001
## Exclude Playerbots from achievement tracking

### Status

Realmwalkers-specific feature - implemented and runtime-validated.

### Component

Achievements / Playerbots

### File

`src/server/game/Achievements/AchievementMgr.cpp`

### Purpose

Realmwalkers uses Playerbots to populate and simulate activity in the game world.

These automated characters must not participate in achievement tracking because
their activity could contaminate player-facing achievement statistics, portal
statistics, rankings, leaderboards, or other systems intended to represent
human player activity.

### Implementation

Achievement processing now rejects players whose WorldSession is explicitly
identified as a bot through:

`WorldSession::IsBot()`

Three guards are applied in `AchievementMgr.cpp`:

1. `AchievementMgr::UpdateAchievementCriteria(...)`
   - Source line at validation: approximately 1485
   - Prevents bot activity from entering normal achievement criteria processing.

2. `AchievementMgr::SetCriteriaProgress(...)`
   - Source line at validation: approximately 2202
   - Prevents bot sessions from creating or modifying criteria progress.

3. `AchievementMgr::CompletedAchievement(...)`
   - Source line at validation: approximately 2382
   - Prevents bot sessions from completing achievements.

Each guard returns only when the supplied player has a WorldSession for which:

`IsBot() == true`

Human player sessions continue through the existing achievement logic unchanged.

### Dependency

This feature depends on Playerbot sessions being correctly identified by
`WorldSession::IsBot()`.

During development, testing of this feature exposed the upstream Playerbots
WorldSession constructor defect documented separately as:

`RW-FIX-004`

RW-FIX-004 corrected both affected Playerbot WorldSession construction sites so
Playerbots now explicitly use:

`isBot = true`

### Runtime Validation

Validation was performed against the fresh Realmwalkers MoP 5.4.8 environment.

Playerbot population during testing:

- 200 RNDBOT accounts
- 2200 RNDBOT characters
- 50 bot characters online
- 5 bot accounts represented by the online characters

The achievement database was classified by account ownership using the
`RNDBOT[0-9]+` account naming scheme.

With active Playerbots running:

- bot character completed achievements: 0
- bot character achievement progress rows: 0
- bot account completed achievements: 0
- bot account achievement progress rows: 0

These values remained zero while Playerbots continued operating.

### Human Player Regression Test

Human achievement processing was tested using:

- Account: DOMASI
- Character: Artemis
- Character GUID: 2207
- Account ID: 204

Before the human activity test:

- human character achievement progress rows: 39
- human account achievement progress rows: 2

After normal player activity, multiple Artemis achievement criteria counters
advanced and additional criteria progress was recorded.

Examples observed during validation included increases in criteria:

- 3631
- 4092
- 4224
- 4944
- 4946
- 4948
- 5212
- 5218
- 5230
- 5313
- 5314
- 5315
- 5316
- 5317
- 5372
- 5373
- 5529
- 5531
- 16825
- 20735

Account-level achievement criteria for account 204 also continued to update.

During the same test, all four Playerbot achievement categories remained zero.

### Validation Result

RW-FEATURE-001 is considered runtime-validated.

The implementation successfully:

- prevents Playerbots from creating character achievement progress
- prevents Playerbots from completing character achievements
- prevents Playerbots from creating account achievement progress
- prevents Playerbots from completing account achievements
- preserves normal achievement processing for human players

No regression to human achievement progress was observed.

### Upstream Reporting

RW-FEATURE-001 represents a Realmwalkers policy decision rather than a confirmed
general Legends-of-Azeroth defect.

The achievement-suppression guards should therefore remain a Realmwalkers-local
feature unless the upstream maintainers specifically want configurable
Playerbot achievement suppression.

The separate WorldSession bot-identification defect discovered while testing
this feature is tracked as RW-FIX-004 and is appropriate for upstream reporting.

---
