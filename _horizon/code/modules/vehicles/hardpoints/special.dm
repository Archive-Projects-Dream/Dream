/*
 * Special hardpoints (firing port weapons), ported from cmss13
 * code/modules/vehicles/hardpoints/special/.dm
 */

/obj/item/hardpoint/special
	name = "special hardpoint"
	desc = "Special pre-installed hardpoints with unique behaviour."

	slot = HDPT_SPECIAL

	damage_multiplier = 0.1

	activatable = TRUE

// Cupola guns that are fired from the sides of APC by support gunners
/obj/item/hardpoint/special/firing_port_weapon
	name = "\improper M56 FPW"
	desc = "A modified heavy machine gun installed on the sides of the M577 Armored Personnel Carrier as a Firing Port Weapon. Used by support gunners to cover friendly infantry at APC sides."

	icon = '_horizon/icons/vehicles/obj/hardpoints/apc.dmi'
	icon_state = "m56_FPW"
	disp_icon = '_horizon/icons/vehicles/obj/apc.dmi'
	disp_icon_state = ""
	activation_sounds = list('sound/items/weapons/gun/smartgun/smartgun_shoot_1.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_2.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_3.ogg', 'sound/items/weapons/gun/smartgun/smartgun_shoot_1.ogg')

	max_integrity = 100
	firing_arc = 120
	//FPWs reload automatically
	var/reloading = FALSE
	var/reload_time = 10 SECONDS
	var/reload_time_started = 0

	use_muzzle_flash = TRUE

	allowed_seat = VEHICLE_SUPPORT_GUNNER_ONE

	projectile_type = /obj/projectile/bullet/vehicle/fpw

	ammo = new /obj/item/ammo_magazine/hardpoint/firing_port_weapon
	max_clips = 1

	underlayer_north_muzzleflash = TRUE

	scatter = 3
	gun_firemode = HARDPOINT_FIREMODE_AUTOMATIC
	gun_firemode_list = list(
		HARDPOINT_FIREMODE_AUTOMATIC,
	)
	fire_delay = 0.3 SECONDS

//for the tgui
/obj/item/hardpoint/special/firing_port_weapon/get_tgui_info()
	var/list/data = list()

	data["name"] = name
	data["uses_ammo"] = TRUE
	data["current_rounds"] = ammo.current_rounds
	data["max_rounds"] = ammo.max_rounds
	data["fpw"] = TRUE

	return data

/obj/item/hardpoint/special/firing_port_weapon/reload(mob/user)
	if(!ammo)
		ammo = new /obj/item/ammo_magazine/hardpoint/firing_port_weapon
	else
		ammo.current_rounds = ammo.max_rounds
	reloading = FALSE

	playsound(owner, 'sound/items/weapons/gun/general/ballistic_click.ogg', 50, TRUE)

	if(user && owner.get_mob_seat(user))
		to_chat(user, span_warning("\The [name]'s automated reload is finished. Ammo: <b>[ammo ? ammo.current_rounds : 0]/[ammo ? ammo.max_rounds : 0]</b>"))

/obj/item/hardpoint/special/firing_port_weapon/proc/start_auto_reload(mob/user)
	if(reloading)
		to_chat(user, span_warning("\The [name] is already being reloaded. Wait [((reload_time_started + reload_time - world.time) / 10)] seconds."))
		return
	if(user)
		to_chat(user, span_warning("\The [name] is out of ammunition! Wait [reload_time / 10] seconds for automatic reload to finish."))
	reloading = TRUE
	reload_time_started = world.time
	addtimer(CALLBACK(src, PROC_REF(reload), user), reload_time)

//try adding magazine to hardpoint's backup clips. Called via weapons loader
/obj/item/hardpoint/special/firing_port_weapon/try_add_clip(obj/item/ammo_magazine/new_magazine, mob/user)
	to_chat(user, span_notice("\The [name] reloads automatically."))
	return FALSE

/obj/item/hardpoint/special/firing_port_weapon/try_fire(atom/target_atom, mob/living/user, params)
	if(!owner)
		return NONE

	//FPW stop working at 50% hull
	if(owner.atom_integrity < owner.max_integrity * 0.5)
		to_chat(user, span_warning("<b>\The [owner]'s hull is too damaged!</b>"))
		return NONE

	if(user.get_active_held_item())
		to_chat(user, span_warning("You need a free hand to use \the [name]."))
		return NONE

	if(reloading)
		to_chat(user, span_notice("\The [name] is reloading. Wait [((reload_time_started + reload_time - world.time) / 10)] seconds."))
		return NONE

	if(ammo && ammo.current_rounds <= 0)
		if(reloading)
			to_chat(user, span_warning("<b>\The [name] is out of ammo! You have to wait [(reload_time_started + reload_time - world.time) / 10] seconds before it reloads!"))
		else
			start_auto_reload(user)
		return NONE

	if(!in_firing_arc(target_atom))
		to_chat(user, span_warning("<b>The target is not within your firing arc!</b>"))
		return NONE

	return handle_fire(target_atom, user, params)
