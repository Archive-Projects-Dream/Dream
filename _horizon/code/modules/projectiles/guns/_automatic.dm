/obj/item/gun/ballistic/automatic
	var/select = 3
	/// The sound effect for switching your gun back to semi-automatic
	var/fireselector_semi = '_horizon/sound/weapons/guns/rifle/msafety.wav'
	var/fireselector_semi_vary = FALSE
	var/fireselector_semi_volume = 90
	/// The sound effect for switching your gun to burst fire
	var/fireselector_burst = '_horizon/sound/weapons/guns/rifle/msafety.wav'
	var/fireselector_burst_vary = FALSE
	var/fireselector_burst_volume = 90
	/// The sound effect for switching your gun to full auto fire
	var/fireselector_auto = '_horizon/sound/weapons/guns/rifle/msafety.wav'
	var/fireselector_auto_vary = FALSE
	var/fireselector_auto_volume = 90
	/// Size of the burst when burst firing
	var/burst_size_toggled
	var/fire_delay_toggled
	/// Size of the burst when auto firing
	var/burst_size_auto
	var/fire_delay_auto

/obj/item/gun/ballistic/automatic/Initialize(mapload)
	. = ..()
	if(isnull(burst_size_toggled))
		burst_size_toggled = initial(burst_size)
	if(isnull(fire_delay_toggled))
		fire_delay_toggled = initial(fire_delay)
	if(isnull(burst_size_auto))
		burst_size_auto = initial(burst_size)
	if(isnull(fire_delay_auto))
		fire_delay_auto = initial(fire_delay)

/obj/item/gun/ballistic/automatic/initialize_full_auto()
	if(!full_auto)
		return FALSE
	AddComponent(/datum/component/automatic_fire, fire_delay_auto)

/obj/item/gun/ballistic/automatic/burst_select()
	var/mob/living/carbon/human/user = usr
	var/datum/component/automatic_fire/full_auto = GetComponent(/datum/component/automatic_fire)

	// Nothing to select between: no full auto component and no separate burst
	// mode. (How did this happen?)
	if(!full_auto && burst_size_toggled == initial(burst_size))
		return

	// Cycle the selector: 1 = semi, 2 = burst, 3 = full auto.
	switch(select)
		if(1) // semi -> burst, or straight to auto if there is no burst mode
			select = (burst_size_toggled != initial(burst_size)) ? 2 : 3
		if(2) // burst -> auto
			select = 3
		else // auto (or invalid) -> semi
			select = 1

	switch(select)
		if(1)
			burst_size = 1
			if(full_auto)
				full_auto.autofire_off()
				full_auto.autofire_stat = AUTOFIRE_STAT_OFF
			to_chat(user, span_notice("I switch [src] to semi-automatic."))
			playsound(user, fireselector_semi, fireselector_semi_volume, fireselector_semi_vary)
		if(2)
			burst_size = burst_size_toggled
			fire_delay = fire_delay_toggled
			if(full_auto)
				full_auto.autofire_stat = AUTOFIRE_STAT_IDLE
				full_auto.autofire_on(user.client)
			to_chat(user, span_notice("I switch [src] to [burst_size]-round burst."))
			playsound(user, fireselector_burst, fireselector_burst_volume, fireselector_burst_vary)
		if(3)
			burst_size = burst_size_auto
			if(full_auto)
				full_auto.autofire_stat = AUTOFIRE_STAT_IDLE
				full_auto.autofire_on(user.client)
			to_chat(user, span_notice("I switch [src] to automatic."))
			playsound(user, fireselector_auto, fireselector_auto_volume, fireselector_auto_vary)

	update_appearance()
	if(ismob(loc))
		var/mob/holder = loc
		holder.update_action_buttons()
