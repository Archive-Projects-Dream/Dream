// horizon-dev-sync[bot] port from Shiptest
// Ammo counter attachment + HUD component.
// Shows remaining ammo count as a HUD overlay when holding a ballistic gun
// with an ammo counter attached.
// Adapted from Shiptest's code/game/objects/items/attachments/ammo_counter.dm
// and code/modules/projectiles/guns/gunhud.dm.

// =============================================================================
// Screen object
// =============================================================================

#define ui_ammocounter "EAST-1:28,CENTER+1:25"

/atom/movable/screen/ammo_counter
        name = "ammo counter"
        icon = '_horizon/icons/ui/gun_hud.dmi'
        icon_state = "backing"
        screen_loc = ui_ammocounter
        invisibility = INVISIBILITY_ABSTRACT
        /// Color for the OTH backing, numbers and indicator
        var/backing_color = "#ff0000ff"
        /// OTH position X00
        var/oth_o
        /// OTH position 0X0
        var/oth_t
        /// OTH position 00X
        var/oth_h
        /// Custom indicator sprite (e.g. "bullet")
        var/indicator

/atom/movable/screen/ammo_counter/proc/turn_off()
        invisibility = INVISIBILITY_ABSTRACT
        maptext = null
        backing_color = "#ff0000ff"
        oth_o = ""
        oth_t = ""
        oth_h = ""
        indicator = ""
        update_appearance()

/atom/movable/screen/ammo_counter/proc/turn_on()
        invisibility = 0

/atom/movable/screen/ammo_counter/proc/set_hud(_backing_color, _oth_o, _oth_t, _oth_h, _indicator)
        backing_color = _backing_color
        oth_o = _oth_o
        oth_t = _oth_t
        oth_h = _oth_h
        indicator = _indicator
        update_appearance()

/atom/movable/screen/ammo_counter/update_overlays()
        . = ..()
        cut_overlays()
        if(oth_o)
                var/mutable_appearance/o_overlay = mutable_appearance(icon, oth_o)
                o_overlay.color = backing_color
                . += o_overlay
        if(oth_t)
                var/mutable_appearance/t_overlay = mutable_appearance(icon, oth_t)
                t_overlay.color = backing_color
                . += t_overlay
        if(oth_h)
                var/mutable_appearance/h_overlay = mutable_appearance(icon, oth_h)
                h_overlay.color = backing_color
                . += h_overlay
        if(indicator)
                var/mutable_appearance/indicator_overlay = mutable_appearance(icon, indicator)
                indicator_overlay.color = backing_color
                . += indicator_overlay

// =============================================================================
// HUD var on /datum/hud
// =============================================================================

/datum/hud
        var/atom/movable/screen/ammo_counter

// =============================================================================
// Component
// =============================================================================

/datum/component/ammo_hud
        var/atom/movable/screen/ammo_counter/hud
        var/indicator = "bullet"
        var/backing_color = "#ff0000ff"

/datum/component/ammo_hud/Initialize()
        . = ..()
        if(!istype(parent, /obj/item/gun))
                return COMPONENT_INCOMPATIBLE
        RegisterSignal(parent, COMSIG_ITEM_EQUIPPED, PROC_REF(wake_up))

/datum/component/ammo_hud/Destroy()
        turn_off()
        return ..()

/datum/component/ammo_hud/proc/wake_up(datum/source, mob/user, slot)
        SIGNAL_HANDLER
        if(ishuman(user))
                var/mob/living/carbon/human/H = user
                if(H.is_holding(parent))
                        if(H.hud_used)
                                hud = H.hud_used.ammo_counter
                                turn_on()
                else
                        turn_off()

/datum/component/ammo_hud/proc/turn_on()
        SIGNAL_HANDLER
        RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(turn_off))
        RegisterSignals(parent, list(COMSIG_UPDATE_AMMO_HUD, COMSIG_GUN_CHAMBER_PROCESSED), PROC_REF(update_hud))
        hud.turn_on()
        update_hud()

/datum/component/ammo_hud/proc/turn_off()
        SIGNAL_HANDLER
        UnregisterSignal(parent, list(COMSIG_ITEM_DROPPED, COMSIG_UPDATE_AMMO_HUD, COMSIG_GUN_CHAMBER_PROCESSED))
        if(hud)
                hud.turn_off()
                hud = null

/datum/component/ammo_hud/proc/update_hud()
        SIGNAL_HANDLER
        var/obj/item/gun/ballistic/pew = parent
        hud.maptext = null
        hud.icon_state = "backing"
        if(!pew.magazine)
                hud.set_hud(backing_color, "oe", "te", "he", "no_mag")
                return
        if(!pew.get_ammo())
                hud.set_hud(backing_color, "oe", "te", "he", "empty_flash")
                return

        var/rounds = num2text(pew.get_ammo())
        var/oth_o
        var/oth_t
        var/oth_h

        switch(length(rounds))
                if(1)
                        oth_o = "o[rounds[1]]"
                if(2)
                        oth_o = "o[rounds[2]]"
                        oth_t = "t[rounds[1]]"
                if(3)
                        oth_o = "o[rounds[3]]"
                        oth_t = "t[rounds[2]]"
                        oth_h = "h[rounds[1]]"
                else
                        oth_o = "o9"
                        oth_t = "t9"
                        oth_h = "h9"
        hud.set_hud(backing_color, oth_o, oth_t, oth_h, indicator)

// =============================================================================
// Attachment item
// =============================================================================

/obj/item/attachment/ammo_counter
        name = "ammunition counter"
        desc = "A computerized ammunition tracker for use on conventional firearms. Shows remaining ammo as a HUD overlay."
        icon = '_horizon/icons/obj/items/guns/attachments.dmi'
        icon_state = "ammo_counter"
        w_class = WEIGHT_CLASS_TINY

/// Attach to ballistic gun via item_interaction (click gun with attachment).
/obj/item/gun/ballistic/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
        . = ..()
        if(.)
                return

        // Ammo counter attachment
        if(istype(tool, /obj/item/attachment/ammo_counter))
                if(!user.is_holding(src))
                        balloon_alert(user, "hold the gun!")
                        return ITEM_INTERACT_BLOCKING
                var/datum/component/ammo_hud/existing = GetComponent(/datum/component/ammo_hud)
                if(existing)
                        balloon_alert(user, "already has a counter!")
                        return ITEM_INTERACT_BLOCKING
                if(!user.transferItemToLoc(tool, src))
                        balloon_alert(user, "can't attach!")
                        return ITEM_INTERACT_BLOCKING
                AddComponent(/datum/component/ammo_hud)
                var/datum/component/ammo_hud/our_counter = GetComponent(/datum/component/ammo_hud)
                our_counter.wake_up(source = src, user = user, slot = ITEM_SLOT_HANDS)
                balloon_alert(user, "ammo counter attached")
                playsound(src, 'sound/items/click.ogg', 25, TRUE)
                return ITEM_INTERACT_SUCCESS
