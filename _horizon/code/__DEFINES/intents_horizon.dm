// horizon-dev-sync[bot] port
// Helper macro missing from upstream /tg/station codebase but used widely
// by horizon mechanics to gate "is this click a harm click?" behaviour.
//
// Upstream /tg/station removed the legacy intent system and now uses
// /mob/living/var/combat_mode directly. This shim keeps the legacy
// IS_HARM_INTENT(mob, modifiers) call sites in _gun.dm / _ballistic.dm
// working without rewriting them.

/// Returns TRUE if `mob` is on harm intent (or, for non-humans, if combat_mode
/// is on and the player didn't right-click). Right-click is reserved for
/// secondary attacks, so we treat it as "non-harm" for melee flog checks.
#define IS_HARM_INTENT(mob, modifiers) (isobserver(mob) ? FALSE : (mob.combat_mode && !LAZYACCESS(modifiers, RIGHT_CLICK)))
