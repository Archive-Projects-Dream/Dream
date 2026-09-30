/*
 * Primary hardpoints (main guns), ported from cmss13
 * code/modules/vehicles/hardpoints/primary/*.dm
 *
 * Projectile stats live in projectiles.dm; the cmss13 IFF bullet trait
 * system is not ported, so guns simply fire at whatever is clicked.
 */

/obj/item/hardpoint/primary
	name = "primary hardpoint"
	desc = "Main big gun."

	slot = HDPT_PRIMARY

	damage_multiplier = 0.15

	activatable = TRUE

// AC3-E Autocannon: fast explosive flak
/obj/item/hardpoint/primary/autocannon
	name = "\improper AC3-E Autocannon"
	desc = "A primary autocannon for tanks that shoots explosive flak rounds."

	icon_state = "ace_autocannon"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "ace_autocannon"
	activation_sounds = list('_horizon/sounds/vehicles/weapons/autocannon_fire.ogg')

	max_integrity = 500
	firing_arc = 60

	projectile_type = /obj/projectile/bullet/vehicle/flak

	ammo = new /obj/item/ammo_magazine/hardpoint/ace_autocannon
	max_clips = 2

	px_offsets = list(
		"1" = list(0, 22),
		"2" = list(0, -32),
		"4" = list(32, 0),
		"8" = list(-32, 0)
	)

	scatter = 1
	gun_firemode = HARDPOINT_FIREMODE_AUTOMATIC
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_AUTOMATIC,
	)
	fire_delay = 0.7 SECONDS

// LTB Cannon: slow, devastating
/obj/item/hardpoint/primary/cannon
	name = "\improper LTB Cannon"
	desc = "A primary cannon for tanks that shoots explosive rounds."

	icon_state = "ltb_cannon"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "ltb_cannon"
	activation_sounds = list('_horizon/sounds/vehicles/weapons/cannon_fire1.ogg', '_horizon/sounds/vehicles/weapons/cannon_fire2.ogg')

	max_integrity = 500
	firing_arc = 60

	projectile_type = /obj/projectile/bullet/vehicle/ltb_shell

	ammo = new /obj/item/ammo_magazine/hardpoint/ltb_cannon
	max_clips = 3

	px_offsets = list(
		"1" = list(0, 21),
		"2" = list(0, -32),
		"4" = list(32, 0),
		"8" = list(-32, 0)
	)

	muzzle_flash_pos = list(
		"1" = list(0, 59),
		"2" = list(0, -74),
		"4" = list(89, -4),
		"8" = list(-89, -4)
	)

	scatter = 2
	fire_delay = 20.0 SECONDS

// LTAA-AP Minigun: spools up as it fires
/obj/item/hardpoint/primary/minigun
	name = "\improper LTAA-AP Minigun"
	desc = "A primary LTAA Minigun utilizing AP ammo for tanks. Its six barrels are heavy and take a bit to fully spin up."

	icon_state = "ltaaap_minigun"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "ltaaap_minigun"

	max_integrity = 350
	firing_arc = 90

	projectile_type = /obj/projectile/bullet/vehicle/minigun

	ammo = new /obj/item/ammo_magazine/hardpoint/ltaaap_minigun
	max_clips = 1

	px_offsets = list(
		"1" = list(0, 21),
		"2" = list(0, -32),
		"4" = list(32, 0),
		"8" = list(-32, 0)
	)

	muzzle_flash_pos = list(
		"1" = list(0, 57),
		"2" = list(0, -67),
		"4" = list(77, 0),
		"8" = list(-77, 0)
	)

	scatter = 18 //base scatter, modified by stage_delay_mult
	gun_firemode = HARDPOINT_FIREMODE_AUTOMATIC
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_AUTOMATIC,
	)
	fire_delay = 0.7 SECONDS //base fire rate, modified by stage_delay_mult

	activation_sounds = list('_horizon/sounds/vehicles/weapons/minigun_loop.ogg')
	/// Active firing time to reach max spin_stage.
	var/spinup_time = 10 SECONDS
	/// Grace period before losing spin_stage.
	var/spindown_grace_time = 2 SECONDS
	COOLDOWN_DECLARE(spindown_grace_cooldown)
	/// Cooldown time to reach min spin_stage.
	var/spindown_time = 3 SECONDS
	/// Index of stage_rate.
	var/spin_stage = 1
	/// Shots fired per fire_delay at a particular spin_stage.
	var/list/stage_rate = list(1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 5)
	/// Fire delay multiplier for current spin_stage.
	var/stage_delay_mult = 1
	/// When it was last fired, related to world.time.
	var/last_fired = 0

/obj/item/hardpoint/primary/minigun/set_fire_cooldown()
	calculate_stage_delay_mult() //needs to check grace_cooldown before refreshed
	last_fired = world.time
	COOLDOWN_START(src, spindown_grace_cooldown, spindown_grace_time)
	COOLDOWN_START(src, fire_cooldown, fire_delay * stage_delay_mult)

/obj/item/hardpoint/primary/minigun/proc/calculate_stage_delay_mult()
	var/stage_rate_len = length(stage_rate)
	var/delta_time = world.time - last_fired

	var/old_spin_stage = spin_stage
	if(auto_firing || burst_firing) //spinup if continuing fire
		var/delta_stage = delta_time * (stage_rate_len - 1)
		spin_stage += delta_stage / spinup_time
	else if(COOLDOWN_FINISHED(src, spindown_grace_cooldown)) //spindown if initiating fire after grace
		var/delta_stage = (delta_time - spindown_grace_time) * (stage_rate_len - 1)
		spin_stage -= delta_stage / spindown_time
	else
		return
	spin_stage = clamp(spin_stage, 1, stage_rate_len)

	var/old_stage_rate = stage_rate[floor(old_spin_stage)]
	var/new_stage_rate = stage_rate[floor(spin_stage)]

	if(old_stage_rate != new_stage_rate)
		scatter = initial(scatter) * (1/new_stage_rate)
		stage_delay_mult = 1 / new_stage_rate

// DRG-N Offensive Flamer Unit
/obj/item/hardpoint/primary/flamer
	name = "\improper DRG-N Offensive Flamer Unit"
	desc = "A primary weapon for the tank that spews out high-combustion napalm in a wide radius. The fuel burns intensely and quickly, which allows for it to be used offensively by armoured vehicles."

	icon_state = "drgn_flamer"
	disp_icon = '_horizon/icons/vehicles/obj/tank.dmi'
	disp_icon_state = "drgn_flamer"
	activation_sounds = list('_horizon/sounds/vehicles/weapons/flamethrower.ogg')

	max_integrity = 400
	firing_arc = 90

	projectile_type = /obj/projectile/bullet/vehicle/flame

	ammo = new /obj/item/ammo_magazine/hardpoint/primary_flamer
	max_clips = 1

	px_offsets = list(
		"1" = list(0, 21),
		"2" = list(0, -32),
		"4" = list(32, 1),
		"8" = list(-32, 1)
	)

	use_muzzle_flash = FALSE

	scatter = 5
	fire_delay = 2.0 SECONDS

/obj/item/hardpoint/primary/flamer/try_fire(atom/target_atom, mob/living/user, params)
	if(get_turf(target_atom) in owner.locs)
		to_chat(user, span_warning("The target is too close."))
		return NONE

	return ..()

// APC PARS-159 Boyars Dualcannon
/obj/item/hardpoint/primary/dualcannon
	name = "\improper PARS-159 Boyars Dualcannon"
	desc = "A primary two-barrel cannon for the APC that shoots 20mm rounds."
	icon = '_horizon/icons/vehicles/obj/hardpoints/apc.dmi'

	icon_state = "dual_cannon"
	disp_icon = '_horizon/icons/vehicles/obj/apc.dmi'
	disp_icon_state = "dualcannon"
	activation_sounds = list('_horizon/sounds/vehicles/weapons/dual_autocannon_fire.ogg')

	damage_multiplier = 0.2

	max_integrity = 500
	firing_arc = 60

	origins = list(0, 1)

	projectile_type = /obj/projectile/bullet/vehicle/dualcannon

	ammo = new /obj/item/ammo_magazine/hardpoint/boyars_dualcannon
	max_clips = 2

	use_muzzle_flash = TRUE
	angle_muzzleflash = FALSE
	muzzleflash_icon_state = "muzzle_flash_double"

	muzzle_flash_pos = list(
		"1" = list(11, -29),
		"2" = list(-11, 10),
		"4" = list(-14, 9),
		"8" = list(14, 9)
	)

	scatter = 1
	gun_firemode = HARDPOINT_FIREMODE_AUTOMATIC
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_AUTOMATIC,
	)
	fire_delay = 0.3 SECONDS

/obj/item/hardpoint/primary/dualcannon/pmc
	icon_state = "dual_cannon_wy"
	disp_icon_state = "dual_cannon_wy"

// ARC RE700 Rotary Cannon: automated sentry turret
/obj/item/hardpoint/primary/arc_sentry
	name = "\improper RE700 Rotary Cannon"
	desc = "A primary two-barrel cannon for the ARC that shoots 12.7mm rounds."
	icon = '_horizon/icons/vehicles/obj/hardpoints/arc.dmi'

	icon_state = "autocannon"
	disp_icon = '_horizon/icons/vehicles/obj/arc.dmi'
	disp_icon_state = "autocannon"
	activation_sounds = list('sound/items/weapons/gun/hmg/hmg.ogg')

	damage_multiplier = 0.1
	max_integrity = 125

	origins = list(0, 0)

	projectile_type = /obj/projectile/bullet/vehicle/sentry

	ammo = new /obj/item/ammo_magazine/hardpoint/arc_sentry
	max_clips = 2

	use_muzzle_flash = TRUE
	angle_muzzleflash = FALSE
	muzzleflash_icon_state = "muzzle_flash_double"

	muzzle_flash_pos = list(
		"1" = list(1, 4),
		"2" = list(1, -29),
		"4" = list(16, 3),
		"8" = list(-16, 3)
	)
	gun_firemode = HARDPOINT_FIREMODE_BURSTFIRE
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_BURSTFIRE,
	)
	burst_delay = 2
	burst_amount = 3

	/// Potential targets the turret can shoot at
	var/list/targets = list()
	/// The currently focused sentry target
	var/atom/movable/sentry_target = null
	/// The range that this turret can shoot at the furthest
	var/turret_range = 5
	/// Which faction this sentry ignores when picking targets (set from the vehicle's driver)
	var/faction_to_protect = null

/obj/item/hardpoint/primary/arc_sentry/on_install(obj/vehicle/multitile/vehicle)
	. = ..()
	RegisterSignal(owner, COMSIG_ARC_ANTENNA_TOGGLED, PROC_REF(toggle_processing))
	toggle_processing() // We can't know that the antenna is in the same position as when the gun was removed

/obj/item/hardpoint/primary/arc_sentry/on_uninstall(obj/vehicle/multitile/vehicle)
	. = ..()
	UnregisterSignal(owner, COMSIG_ARC_ANTENNA_TOGGLED)
	STOP_PROCESSING(SSfastprocess, src)

/obj/item/hardpoint/primary/arc_sentry/Destroy()
	STOP_PROCESSING(SSfastprocess, src)
	sentry_target = null
	return ..()

/obj/item/hardpoint/primary/arc_sentry/proc/toggle_processing()
	SIGNAL_HANDLER
	if(!owner)
		return

	var/obj/vehicle/multitile/arc/arc_vehicle = owner
	if(!istype(arc_vehicle))
		return

	if(arc_vehicle.antenna_deployed)
		START_PROCESSING(SSfastprocess, src)

	else
		STOP_PROCESSING(SSfastprocess, src)

/// Automatically picks and fires at nearby targets while the antenna is deployed
/obj/item/hardpoint/primary/arc_sentry/process(seconds_per_tick)
	for(var/mob/living/nearby_mob in range(turret_range, owner))
		targets |= nearby_mob

	if(!length(targets))
		return FALSE

	if(!sentry_target)
		sentry_target = pick(targets)

	get_target(sentry_target)
	return TRUE

/obj/item/hardpoint/primary/arc_sentry/start_fire(datum/source, atom/object, turf/location, control, params)
	if(QDELETED(object))
		return
	if(!COOLDOWN_FINISHED(src, fire_cooldown))
		return

	set_target(object)

/obj/item/hardpoint/primary/arc_sentry/proc/get_target(atom/movable/new_target)
	if(QDELETED(new_target))
		sentry_target = null
		return

	if(!targets.Find(new_target))
		targets.Add(new_target)

	if(!length(targets))
		return

	var/list/conscious_targets = list()
	var/list/unconscious_targets = list()

	for(var/mob/living/living_mob as anything in targets) // orange allows sentry to fire through gas and darkness
		if(living_mob.stat == DEAD)
			purge_target(living_mob)
			continue

		// Skip mobs that are seated inside the vehicle itself
		if(living_mob.buckled && istype(living_mob.buckled, /obj/structure/chair/comfy/vehicle))
			purge_target(living_mob)
			continue

		// Skip the faction the sentry is set to protect
		if(faction_to_protect && (faction_to_protect in living_mob.faction))
			purge_target(living_mob)
			continue

		if(living_mob.invisibility)
			purge_target(living_mob)
			continue

		var/list/turf/path = get_line(get_turf(src), living_mob)
		if(!length(path) || get_dist(get_turf(src), living_mob) > turret_range)
			purge_target(living_mob)
			continue

		var/blocked = FALSE
		for(var/turf/tile as anything in path)
			if(tile.density || tile.opacity)
				blocked = TRUE
				break

			for(var/obj/structure/struct in tile)
				if(struct.opacity)
					blocked = TRUE
					break

			for(var/obj/vehicle/multitile/vehicle in tile)
				if(vehicle == owner) // Some of the tiles will inevitably be the ARC itself
					continue
				blocked = TRUE
				break

		if(blocked)
			purge_target(living_mob)
			continue

		if(living_mob.stat > STABLE && living_mob.stat < DEAD)
			unconscious_targets += living_mob
		else
			conscious_targets += living_mob

	if((sentry_target in conscious_targets) || (sentry_target in unconscious_targets))
		sentry_target = sentry_target

	else if(length(conscious_targets))
		sentry_target = pick(conscious_targets)

	else if(length(unconscious_targets))
		sentry_target = pick(unconscious_targets)

	if(!sentry_target) //No targets, don't bother firing
		return

	if(COOLDOWN_FINISHED(src, fire_cooldown))
		set_fire_cooldown()
		try_fire(sentry_target, null)

/obj/item/hardpoint/primary/arc_sentry/proc/purge_target(mob/purged_target)
	if(purged_target == sentry_target)
		sentry_target = null
	targets.Remove(purged_target)

/obj/item/hardpoint/primary/arc_sentry/can_be_removed(mob/remover)
	var/obj/vehicle/multitile/arc/arc_owner = owner
	if(!istype(arc_owner))
		return TRUE

	if(arc_owner.antenna_deployed)
		to_chat(remover, span_warning("[src] cannot be removed from [owner] while its antenna is deployed."))
		return FALSE

	return ..()
