// (DEBRIS_* defines live in _horizon/code/__DEFINES/particles.dm.)
// (Particle definitions /particles/debris, /particles/firing_smoke, and
// /particles/impact_smoke live in _horizon/code/modules/visual_changes/.)

/atom/proc/blood_particles(mob/living/carbon/H)
        var/debris = "drip"
        var/debris_velocity = rand(5,10)
        var/debris_amount = 10
        var/debris_scale = 0.7
        var/new_direction = dir2angle(H.dir)
        var/x_component = sin(new_direction) * debris_velocity
        var/y_component = cos(new_direction) * debris_velocity
        var/obj/effect/abstract/particle_holder/blood_visuals
        var/position_offset = rand(-1,1)

        blood_visuals = new(src, /particles/debris)
        blood_visuals.particles.icon_state = debris
        blood_visuals.particles.position = generator(GEN_CIRCLE, position_offset, position_offset)
        blood_visuals.particles.velocity = list(x_component, y_component)
        blood_visuals.color ="#770000"
        blood_visuals.layer = CHAT_LAYER
        blood_visuals.particles.count = debris_amount
        blood_visuals.particles.spawning = debris_amount
        blood_visuals.particles.scale = debris_scale
        addtimer(CALLBACK(src, PROC_REF(remove_blood_particles), blood_visuals), 0.7 SECONDS)

/atom/proc/remove_blood_particles(obj/effect/abstract/particle_holder/blood_visuals)
        if(blood_visuals)
                QDEL_NULL(blood_visuals)

/atom/proc/visual_effect(var/obj/projectile/P, var/debris = DEBRIS_SPARKS)
        var/debris_velocity = -15
        if(debris == "drip")
                debris_velocity = 15
        var/debris_amount = 8
        var/debris_scale = 0.7
        var/x_component = sin(P.Angle) * debris_velocity
        var/y_component = cos(P.Angle) * debris_velocity
        var/x_component_smoke = sin(P.Angle) * -15
        var/y_component_smoke = cos(P.Angle) * -15
        var/obj/effect/abstract/particle_holder/debris_visuals
        var/obj/effect/abstract/particle_holder/smoke_visuals
        var/position_offset = rand(-6,6)
        if(debris != "drip")
                smoke_visuals = new(src, /particles/impact_smoke)
                smoke_visuals.particles.position = list(position_offset, position_offset)
                smoke_visuals.particles.velocity = list(x_component_smoke, y_component_smoke)
                smoke_visuals.layer = ABOVE_OBJ_LAYER + 0.01

        debris_visuals = new(src, /particles/debris)
        if(debris == "drip")
                debris_visuals.color ="#770000"
        debris_visuals.particles.position = generator(GEN_CIRCLE, position_offset, position_offset)
        debris_visuals.particles.velocity = list(x_component, y_component)
        debris_visuals.layer = ABOVE_OBJ_LAYER + 0.02
        debris_visuals.particles.icon_state = debris
        debris_visuals.particles.count = debris_amount
        debris_visuals.particles.spawning = debris_amount
        debris_visuals.particles.scale = debris_scale
        addtimer(CALLBACK(src, PROC_REF(remove_ping), smoke_visuals, debris_visuals), 0.7 SECONDS)

/atom/proc/remove_ping(obj/effect/abstract/particle_holder/smoke_visuals, obj/effect/abstract/particle_holder/debris_visuals)
        QDEL_NULL(smoke_visuals)
        if(debris_visuals)
                QDEL_NULL(debris_visuals)

/obj/item/gun
        //skill_melee = SKILL_IMPACT_WEAPON
        //skill_ranged = SKILL_PISTOL
        carry_weight = 2.5 KILOGRAMS
        pickup_sound = '_horizon/sound/weapons/guns/generic_draw.wav'
        dry_fire_sound = '_horizon/sound/weapons/guns/empty.wav'
        /// Message when we dry fire (applies both to dry firing and failing to fire for other reasons)
        var/dry_fire_message = span_danger("*click*")
        /// Whether to vary dry_fire_sound or not
        var/dry_fire_sound_vary = FALSE
        /// Sound for aiming at someone
        var/aim_stress_sound = '_horizon/sound/weapons/guns/aim_stress.wav'
        /// Volume for aiming sound
        var/aim_stress_sound_volume = 50
        /// Whether the aiming sound should vary on not
        var/aim_stress_sound_vary = FALSE
        /// Sound for stopping aiming at someone
        var/aim_spare_sound = '_horizon/sound/weapons/guns/aim_spare.wav'
        /// Volume for stopping aiming sound
        var/aim_spare_sound_volume = 50
        /// Whether the stopping aiming sound should vary on not
        var/aim_spare_sound_vary = FALSE
        /// Flags related to gun safety
        var/safety_flags = GUN_SAFETY_FLAGS_DEFAULT
        /// Sound when safety is toggled on
        var/safety_on_sound = '_horizon/sound/weapons/guns/safety1.ogg'
        /// Sound when safety is toggled off
        var/safety_off_sound = '_horizon/sound/weapons/guns/safety1.ogg'
        /// Volume of safety toggle sounds (both on and off)
        var/safety_sound_volume = 50
        /// Whether to vary safety toggle sounds or not
        var/safety_sound_vary = FALSE

        // ~ICON VARIABLES
        /// Mouse pointer icon when holding this gun while the safety is disabled
        var/mouse_pointer_icon = '_horizon/icons/effects/mouse_pointers/weapon_pointer.dmi'
        /// Does the gun have a unique icon_state when nothing is chambered?
        var/empty_icon_state = FALSE
        /// Does the gun have unique inhands when wielded?
        var/wielded_inhand_state = FALSE
        /// Does the inhand state get modifier when sawn?
        var/sawn_inhand_state = FALSE

        /// NO FULL AUTO IN BUILDINGS!
        var/full_auto = FALSE

        // Folding stock variables
        /// Allows the gun's stock to be folded and unfolded.
        var/foldable = FALSE
        /// Whether the stock is folded or not.
        var/folded = TRUE
        /// The sound it makes when you fold a stock
        var/fold_open_sound = '_horizon/sound/weapons/guns/stock_open.wav'
        /// The sound it makes when you unfold a stock.
        var/fold_close_sound = '_horizon/sound/weapons/guns/stock_close.wav'
        /// Every time you fiddle with the stock
        var/fiddle = '_horizon/sound/effects/fiddle.wav'

/obj/item/gun/New()
        . = ..()
        appearance_flags |= KEEP_TOGETHER

/obj/item/gun/Initialize(mapload)
        . = ..()
        if(foldable)
                new /datum/action/item_action/toggle_stock(src)
        if(full_auto)
                AddComponent(/datum/component/automatic_fire)
        // Heavy weapons require two hands - add the two_handed component so
        // players can wield them with Z (attack_self). The wield state is
        // then checked via COMSIG_TWOHANDED_WIELD_CHECK by horizon code.
        if(wielded_inhand_state)
                AddComponent(/datum/component/two_handed, \
                        wieldsound = '_horizon/sound/weapons/guns/stock_open.wav', \
                        unwieldsound = '_horizon/sound/weapons/guns/stock_close.wav')

/obj/item/gun/update_icon(updates)
        . = ..()
        if(wielded_inhand_state)
                if(SEND_SIGNAL(src, COMSIG_TWOHANDED_WIELD_CHECK))
                        inhand_icon_state = "[initial(inhand_icon_state)][(sawn_off && sawn_inhand_state) ? "_sawn" : ""]_wielded"
                else
                        inhand_icon_state = "[initial(inhand_icon_state)][(sawn_off && sawn_inhand_state) ? "_sawn" : ""]"
        else if(sawn_inhand_state)
                inhand_icon_state = "[initial(inhand_icon_state)][sawn_off ? "_sawn" : ""]"

/obj/item/gun/update_icon_state()
        . = ..()
        if(empty_icon_state && !chambered)
                icon_state = "[icon_state]_empty"

/obj/item/gun/update_overlays()
        . = ..()
        if(foldable)
                //generally, the stock should be below everything else, otherwise it will look very fucked
                var/image/folding_image = image(icon, src, "[base_icon_state]_[folded ? "folded" : "unfolded"]")
                folding_image.layer = layer - 1
                . += folding_image
        // Flashlight and bayonet overlays are now handled by upstream's
        // /datum/component/seclite_attachable and /datum/component/bayonet_attachable
        // respectively. We don't render them manually here.
        if(safety_flags & GUN_SAFETY_HAS_SAFETY)
                var/image/safety_overlay
                if((safety_flags & GUN_SAFETY_ENABLED) && (safety_flags & GUN_SAFETY_OVERLAY_ENABLED))
                        safety_overlay = image(icon, src, "[base_icon_state]_safe")
                else if(!(safety_flags & GUN_SAFETY_ENABLED) && (safety_flags & GUN_SAFETY_OVERLAY_DISABLED))
                        safety_overlay = image(icon, src, "[base_icon_state]_unsafe")
                if(safety_overlay)
                        . += safety_overlay

/obj/item/gun/examine(mob/user)
        . = ..()
        var/safety_examine = safety_examine(user)
        if(LAZYLEN(safety_examine))
                . += safety_examine

/obj/item/gun/add_weapon_description()
        AddElement(/datum/element/weapon_description, PROC_REF(add_notes_gun))

/obj/item/gun/get_carry_weight()
        . = ..()
        if(istype(pin))
                . += pin.get_carry_weight()

/obj/item/gun/equipped(mob/living/user, slot)
        . = ..()
        if(slot == ITEM_SLOT_HANDS)
                user.update_mouse_pointer()

/obj/item/gun/dropped(mob/user)
        . = ..()
        user.update_mouse_pointer()

/obj/item/gun/mouse_drop_dragged(atom/over, mob/user, src_location, over_location, params)
        . = ..()
        if(!foldable)
                return
        if(!isliving(usr) || !user.Adjacent(src) || HAS_TRAIT(user, TRAIT_INCAPACITATED))
                return
        if(isopenturf(over))
                toggle_stock(user)

/obj/item/gun/attackby(obj/item/I, mob/living/user, params)
        // Flashlight (seclite) and bayonet attachments are now handled by
        // upstream's /datum/component/seclite_attachable and
        // /datum/component/bayonet_attachable respectively. They register
        // their own COMSIG_ATOM_ATTACKBY handlers, so we just fall through
        // to ..() here.
        return ..()

/obj/item/gun/attack_self_secondary(mob/user, modifiers)
        . = ..()
        if(safety_flags & GUN_SAFETY_HAS_SAFETY)
                toggle_safety(user)

// Gunpoint (holding someone up at gunpoint) is now handled by upstream's
// /obj/item/gun/interact_with_atom_secondary() which checks can_hold_up
// and adds /datum/component/gunpoint. No need for a horizon override.

/obj/item/gun/afterattack(atom/target, mob/living/user, flag, params)
        attack_fatigue_cost = 0
        return ..()

/obj/item/gun/fire_gun(atom/target, mob/living/user, flag, params)
        if(QDELETED(target))
                return
        if(firing_burst)
                return
        //It's adjacent, is the user, or is on the user's person
        if(flag)
                //Can't shoot stuff inside us.
                if(target in user.contents)
                        return
                var/list/modifiers = params2list(params)
                //Gun does not fire when flogging
                if((safety_flags & GUN_SAFETY_NO_FLOGGING) && IS_HARM_INTENT(user, modifiers))
                        return
                if(iscarbon(target) && !IS_HARM_INTENT(user, modifiers))
                        var/mob/living/carbon/carbon_target = target
                        for(var/datum/wound/wound as anything in carbon_target.all_wounds)
                                if(wound.try_treating(src, user))
                                        return

        //Check if the user can use the gun, if the user isn't alive (turrets) assume it can.
        if(istype(user))
                if(!can_trigger_gun(user))
                        shoot_with_empty_chamber(user)
                        return

        //Just because you can pull the trigger doesn't mean it can shoot.
        before_can_shoot_checks(user, FALSE)
        if(!can_shoot())
                shoot_with_empty_chamber(user)
                return

        if(check_botched(user, target))
                return

        //DUAL (or more!) WIELDING
        var/bonus_spread = 0
        var/loop_counter = 0
        var/list/modifiers = params2list(params)
        if(ishuman(user) && IS_HARM_INTENT(user, modifiers))
                var/mob/living/carbon/human/human_user = user
                for(var/obj/item/gun/other_gun in human_user.held_items)
                        if((other_gun == src) || (other_gun.weapon_weight >= WEAPON_MEDIUM))
                                continue
                        else if(other_gun.can_trigger_gun(user))
                                bonus_spread += dual_wield_spread
                                loop_counter++
                                addtimer(CALLBACK(other_gun, TYPE_PROC_REF(/obj/item/gun, process_fire), target, user, TRUE, params, null, bonus_spread), loop_counter)

        return process_fire(target, user, TRUE, params, null, bonus_spread)

/obj/item/gun/can_trigger_gun(mob/living/user)
        if(!handle_pins(user))
                return FALSE
        // Safety checks: if safety is ENABLED (ON), the gun cannot fire.
        if(safety_flags & GUN_SAFETY_ENABLED)
                return FALSE
        return TRUE

/obj/item/gun/check_botched(mob/living/user, params)
        if(clumsy_check)
                if(istype(user))
                        if(HAS_TRAIT(user, TRAIT_CLUMSY) && prob(40))
                                to_chat(user, span_userdanger("I shoot myself in the foot with [src]!"))
                                var/shot_foot = pick(BODY_ZONE_PRECISE_R_FOOT, BODY_ZONE_PRECISE_L_FOOT)
                                process_fire(user, user, FALSE, params, shot_foot)
                                SEND_SIGNAL(user, COMSIG_MOB_CLUMSY_SHOOT_FOOT)
                                user.dropItemToGround(src, TRUE)
                                return TRUE

/obj/item/gun/on_autofire_start(mob/living/shooter)
        if(semicd || shooter.stat)
                return NONE
        if(istype(src, /obj/item/gun/ballistic/automatic))
                var/obj/item/gun/ballistic/automatic/automatic_source = src
                //Not on full auto select
                if(automatic_source.select != 3)
                        return NONE
        //Check if the user can use the gun, if the user isn't alive (turrets) assume it can
        if(istype(shooter))
                if(!can_trigger_gun(shooter))
                        shoot_with_empty_chamber(shooter)
                        return NONE
        //Just because you can pull the trigger doesn't mean it can shoot
        before_can_shoot_checks(shooter, TRUE)
        if(!can_shoot())
                shoot_with_empty_chamber(shooter)
                return NONE
        return TRUE

/obj/item/gun/do_autofire(datum/source, atom/target, mob/living/shooter, params)
        if(semicd || shooter.stat)
                return NONE
        if(istype(src, /obj/item/gun/ballistic/automatic))
                var/obj/item/gun/ballistic/automatic/automatic_source = src
                //Not on full auto select
                if(automatic_source.select != 3)
                        return NONE
        //Check if the user can use the gun, if the user isn't alive (turrets) assume it can
        if(istype(shooter))
                if(!can_trigger_gun(shooter))
                        shoot_with_empty_chamber(shooter)
                        return NONE
        //Just because you can pull the trigger doesn't mean it can shoot
        before_can_shoot_checks(shooter, FALSE)
        if(!can_shoot())
                shoot_with_empty_chamber(shooter)
                return NONE
        INVOKE_ASYNC(src, PROC_REF(do_autofire_shot), source, target, shooter, params)
        return COMPONENT_AUTOFIRE_SHOT_SUCCESS //All is well, we can continue shooting

/obj/item/gun/shoot_with_empty_chamber(mob/living/user as mob|obj)
        if(ismob(user) && dry_fire_message)
                to_chat(user, dry_fire_message)
        if(dry_fire_sound)
                playsound(src, dry_fire_sound, dry_fire_sound_volume, dry_fire_sound_vary)
        sound_hint()

/obj/item/gun/proc/initialize_full_auto()
        if(!full_auto)
                return FALSE
        AddComponent(/datum/component/automatic_fire)

/obj/item/gun/proc/add_notes_gun(mob/user)
        . = list()
        switch(weapon_weight)
                if(WEAPON_HEAVY)
                        . += span_notice("<b>Weapon Weight:</b> Heavy")
                if(WEAPON_MEDIUM)
                        . += span_notice("<b>Weapon Weight:</b> Medium")
                if(WEAPON_LIGHT)
                        . += span_notice("<b>Weapon Weight:</b> Light")
                else
                        . += span_notice("<b>Weapon Weight:</b> Invalid")

/obj/item/gun/proc/before_can_shoot_checks(mob/living/user, autofire_start = FALSE)
        return TRUE

/obj/item/gun/proc/safety_examine(mob/user)
        . = list()
        if(safety_flags & GUN_SAFETY_HAS_SAFETY)
                var/safety_text = span_red("OFF")
                if(safety_flags & GUN_SAFETY_ENABLED)
                        safety_text = span_green("ON")
                . += "[p_their(TRUE)] safety is [safety_text]."

/obj/item/gun/proc/toggle_safety(mob/user)
        if(!(safety_flags & GUN_SAFETY_HAS_SAFETY))
                return
        if(safety_flags & GUN_SAFETY_ENABLED)
                safety_flags &= ~GUN_SAFETY_ENABLED
                if(safety_off_sound)
                        playsound(src, safety_off_sound, safety_sound_volume, safety_sound_vary)
        else
                safety_flags |= GUN_SAFETY_ENABLED
                if(safety_on_sound)
                        playsound(src, safety_on_sound, safety_sound_volume, safety_sound_vary)
        if(user)
                to_chat(user, span_notice("I [safety_flags & GUN_SAFETY_ENABLED ? "enable" : "disable"] [src]'s safety."))
        sound_hint()
        update_appearance()
        user.update_mouse_pointer()

/obj/item/gun/ui_action_click(mob/user, actiontype) /// Allows users to spew facts
        if(istype(actiontype, /datum/action/item_action/toggle_stock))
                toggle_stock(user)
        else
                return ..()

/obj/item/gun/proc/toggle_stock(mob/user)
        if(!foldable)
                return
        playsound(src, fiddle, 68, FALSE)
        if(!do_after(user, 0.5 SECONDS, src))
                return
        if(!folded)
                w_class--
                folded = TRUE
                playsound(src, fold_close_sound, 80, FALSE)
                to_chat(user, span_notice("I fold [src]'s stock."))
                //tetris_width -= 32
        else
                w_class++
                folded = FALSE
                playsound(src, fold_open_sound, 80, FALSE)
                to_chat(user, span_notice("I unfold [src]'s stock."))
                //tetris_width += 32
        update_appearance()

/datum/action/item_action/toggle_stock
        name = "Toggle Stock"
        button_icon = '_horizon/icons/hud/actions.dmi'
        button_icon_state = "stock"
