// horizon-dev-sync[bot] port
// Diceroll defines and attribute helpers ported from legacy
// modular_septic/code/__DEFINES/diceroll.dm and attributes.dm. Used by
// horizon projectile/gun firing logic for hit-zone rolls and crits.
//
// The full attribute/diceroll system is not yet ported - these are minimal
// shims so the code compiles and behaves sensibly.

// ~ Dice contexts
#define DICE_CONTEXT_PHYSICAL 1
#define DICE_CONTEXT_MENTAL 2
#define DICE_CONTEXT_SOCIAL 3

// ~ Dice roll outcomes
#define DICE_FAILURE 0
#define DICE_NEUTRAL 1
#define DICE_SUCCESS 2
#define DICE_CRIT_SUCCESS 3
#define DICE_CRIT_FAILURE 4

// ~ Stats (legacy names preserved)
#define STAT_STRENGTH "strength"
#define STAT_INTELLIGENCE "intelligence"
#define STAT_DEXTERITY "dexterity"
#define STAT_ENDURANCE "endurance"
#define STAT_CONSTITUTION "constitution"
#define STAT_AGILITY "agility"
#define STAT_PERCEPTION "perception"
#define STAT_RESOLVE "resolve"
#define STAT_LUCK "luck"

// ~ Stub for the legacy attribute fetcher macro. Always returns 0 until the
// full attributes component is ported - this matches the previous
// "no skills, no attributes" fallback used by upstream /tg/station.
#define GET_MOB_ATTRIBUTE_VALUE(mob, stat) (0)

// ~ Stub for the legacy skill fetcher macro. Always returns 0.
#define GET_MOB_SKILL_VALUE(mob, skill) (0)
