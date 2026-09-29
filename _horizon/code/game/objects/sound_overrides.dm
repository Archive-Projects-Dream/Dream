// horizon-dev-sync[bot] port
// Overrides for sound procs to support list-type sound vars.
// Upstream's playsound() CRASHes if passed a list. Horizon gun subtypes
// use 'fire_sound = list(...)' etc. for random sound selection.
// These overrides call pick() on the sound var if it's a list before
// passing it to playsound().

/// Override: if fire_sound / suppressed_sound is a list, pick() one.
/obj/item/gun/fire_sounds()
	if(suppressed)
		var/sound_to_play = islist(suppressed_sound) ? pick(suppressed_sound) : suppressed_sound
		playsound(src, sound_to_play, suppressed_volume, vary_fire_sound, ignore_walls = FALSE, extrarange = SILENCED_SOUND_EXTRARANGE, falloff_distance = 0)
	else
		var/sound_to_play = islist(fire_sound) ? pick(fire_sound) : fire_sound
		playsound(src, sound_to_play, fire_sound_volume, vary_fire_sound)

/// Override: if sound_to_play is a list, pick() one before playsound().
/obj/item/sound_chain(sound_to_play, volume = HALFWAY_SOUND_VOLUME, target = src)
	if(sound_to_play)
		if(islist(sound_to_play))
			sound_to_play = pick(sound_to_play)
		playsound(target, sound_to_play, volume, sound_vary, ignore_walls = FALSE)
		return TRUE
	return FALSE
