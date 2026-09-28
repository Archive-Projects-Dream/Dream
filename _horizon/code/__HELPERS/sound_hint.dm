// horizon-dev-sync[bot] port
// sound_hint() was originally part of the modular_septic sound_hints module,
// which broadcast a small "noise" overlay to nearby players so they could
// "hear" where a sound came from even with the game muted. The full module
// is not yet ported. This stub keeps horizon mechanics compiling until the
// proper module lands.
//
// Calling code does not need to be modified - it just no-ops.

/atom/proc/sound_hint(duration = 5, use_icon = null, use_states = null)
	return
