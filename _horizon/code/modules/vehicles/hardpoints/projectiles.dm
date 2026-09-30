/*
 * Projectiles fired by multitile vehicle hardpoints, ported from cmss13
 * ammo datums (code/datums/ammo/bullet/tank.dm and friends).
 *
 * cmss13 ammo datums don't exist in Horizon-Dream, so each ammo type is
 * reimplemented as a TG projectile subtype with equivalent stats:
 * - flak: 60 dmg, small frag burst on impact
 * - LTB cannon: heavy explosive shell
 * - minigun: 40 dmg, high armor penetration
 * - flamer: incendiary stream
 * - TOW: big rocket
 * - grenade launcher: 40mm-style grenades
 * - flares / smoke: utility payloads
 */

// Autocannon flak - explodes into a small burst on impact
/obj/projectile/bullet/vehicle/flak
	name = "flak round"
	icon_state = "autocannon"
	damage = 60
	damage_type = BRUTE
	armor_flag = BULLET
	speed = 0.6
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 32
/obj/projectile/bullet/vehicle/flak/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	explosion(hit_target, devastation_range = -1, light_impact_range = 1, flame_range = 0, flash_range = 1, adminlog = FALSE, explosion_cause = src)
	return BULLET_ACT_HIT
// Tank cannon shell - the big boom
/obj/projectile/bullet/vehicle/ltb_shell
	name = "86mm shell"
	icon_state = "shell"
	damage = 120
	damage_type = BRUTE
	armor_flag = BULLET
	speed = 0.5
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 45
/obj/projectile/bullet/vehicle/ltb_shell/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	explosion(hit_target, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4, flame_range = 2, flash_range = 3, explosion_cause = src)
	return BULLET_ACT_HIT
// Minigun bullets - fast, armor-piercing
/obj/projectile/bullet/vehicle/minigun
	name = "AP bullet"
	icon_state = "bullet_large"
	damage = 40
	damage_type = BRUTE
	armor_flag = BULLET
	armour_penetration = 40
	speed = 0.4
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 30
// APC dual cannon rounds
/obj/projectile/bullet/vehicle/dualcannon
	name = "20mm round"
	icon_state = "autocannon"
	damage = 50
	damage_type = BRUTE
	armor_flag = BULLET
	armour_penetration = 15
	speed = 0.5
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 12
/obj/projectile/bullet/vehicle/dualcannon/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	for(var/mob/living/carbon/nearby_carbon in get_turf(hit_target))
		if(nearby_carbon.stat == STABLE)
			shake_camera(nearby_carbon, 1 SECONDS, 1)
	return BULLET_ACT_HIT
// ARC sentry rounds
/obj/projectile/bullet/vehicle/sentry
	name = "12.7mm round"
	icon_state = "bullet_large"
	damage = 35
	damage_type = BRUTE
	armor_flag = BULLET
	armour_penetration = 30
	speed = 0.4
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 25
// M56 cupola rounds
/obj/projectile/bullet/vehicle/cupola
	name = "10x28mm round"
	icon_state = "bullet"
	damage = 45
	damage_type = BRUTE
	armor_flag = BULLET
	armour_penetration = 20
	speed = 0.4
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 30
// Firing port weapon rounds
/obj/projectile/bullet/vehicle/fpw
	name = "10x28mm round"
	icon_state = "bullet"
	damage = 40
	damage_type = BRUTE
	armor_flag = BULLET
	armour_penetration = 10
	speed = 0.4
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 25
// Flamer stream - the primary offensive flamethrower
/obj/projectile/bullet/vehicle/flame
	name = "napalm"
	icon_state = "infernoshot"
	damage = 25
	damage_type = BURN
	armor_flag = FIRE
	speed = 0.8
	range = 9
	pass_flags = PASSTABLE | PASSMOB
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	impact_effect_type = null
	suppressed = SUPPRESSED_VERY
/obj/projectile/bullet/vehicle/flame/Initialize(mapload)
	. = ..()
	set_light_color(COLOR_SOFT_RED)
	set_light_range(2)
	set_light_on(TRUE)
/obj/projectile/bullet/vehicle/flame/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	var/turf/hit_turf = get_turf(hit_target)
	if(isopenturf(hit_turf))
		new /obj/effect/hotspot(hit_turf)
		hit_turf.hotspot_expose(700, 50, 1)
	for(var/turf/nearby_turf in RANGE_TURFS(1, hit_turf))
		if(isopenturf(nearby_turf) && prob(50))
			new /obj/effect/hotspot(nearby_turf)
			nearby_turf.hotspot_expose(700, 50, 1)
	return BULLET_ACT_HIT
// TOW rocket
/obj/projectile/bullet/vehicle/tow_missile
	name = "TOW missile"
	icon_state = "missile"
	damage = 100
	damage_type = BRUTE
	armor_flag = BOMB
	speed = 0.8
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	ricochets_max = 0
	impact_effect_type = /obj/effect/temp_visual/impact_effect
	range = 40
/obj/projectile/bullet/vehicle/tow_missile/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	explosion(hit_target, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 4, flame_range = 2, flash_range = 3, explosion_cause = src)
	return BULLET_ACT_HIT
// Grenade launcher rounds
/obj/projectile/bullet/vehicle/grenade
	name = "launched grenade"
	icon_state = "bolter"
	damage = 30
	damage_type = BRUTE
	armor_flag = BOMB
	speed = 0.8
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	ricochets_max = 0
	impact_effect_type = null
	range = 20
/obj/projectile/bullet/vehicle/grenade/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	explosion(hit_target, devastation_range = -1, heavy_impact_range = 1, light_impact_range = 2, flame_range = 0, flash_range = 2, explosion_cause = src)
	return BULLET_ACT_HIT
// Flare
/obj/projectile/bullet/vehicle/flare
	name = "flare"
	icon_state = "flare"
	damage = 10
	damage_type = BURN
	armor_flag = FIRE
	speed = 0.8
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	impact_effect_type = null
	range = 30
/obj/projectile/bullet/vehicle/flare/Initialize(mapload)
	. = ..()
	set_light_color(COLOR_SOFT_RED)
	set_light_range(6)
	set_light_on(TRUE)
/obj/projectile/bullet/vehicle/flare/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	var/turf/hit_turf = get_turf(hit_target)
	if(hit_turf)
		new /obj/item/flashlight/flare(get_turf(src))
	return BULLET_ACT_HIT
// Smoke shells - deploys a smoke cloud
/obj/projectile/bullet/vehicle/smoke
	name = "smoke shell"
	icon_state = "shell"
	damage = 5
	damage_type = BRUTE
	armor_flag = BULLET
	speed = 0.7
	sharpness = NONE
	embed_type = null
	shrapnel_type = null
	impact_effect_type = null
	range = 20
/obj/projectile/bullet/vehicle/smoke/on_hit(atom/hit_target, blocked = 0, pierce_hit)
	. = ..()
	do_smoke(4, src, get_turf(src), smoke_type = /datum/effect_system/fluid_spread/smoke/bad)
	qdel(src)
	return BULLET_ACT_HIT