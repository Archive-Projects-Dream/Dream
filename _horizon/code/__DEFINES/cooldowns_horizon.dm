// horizon-dev-sync[bot] port
// Cooldown macros missing from upstream /tg/station codebase.
// Upstream renamed TIMER_COOLDOWN_CHECK() to TIMER_COOLDOWN_RUNNING().
// This alias keeps horizon's _ammo_box.dm load cooldown code working.

/// Legacy alias - upstream renamed this to TIMER_COOLDOWN_RUNNING()
#define TIMER_COOLDOWN_CHECK(cd_source, cd_index) TIMER_COOLDOWN_RUNNING(cd_source, cd_index)
