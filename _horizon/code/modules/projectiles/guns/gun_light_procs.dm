// horizon-dev-sync[bot] port
// Procs missing from upstream /tg/station codebase but called by horizon's
// _gun.dm when attaching a seclite flashlight to a gun. Upstream moved
// flashlight handling to /datum/component/seclite_attachable, but horizon
// keeps the legacy /obj/item/gun direct-var API and needs these procs to
// manage the gun_light var and refresh the action button + appearance.

/// Stores the attached seclite on the gun and grants the toggle action.
/obj/item/gun/proc/set_gun_light(obj/item/flashlight/seclite/new_light)
        gun_light = new_light
        if(gun_light)
                gun_light.set_light_flags(LIGHT_ATTACHED)
                if(!alight)
                        alight = new(src)
                alight.target = gun_light

/// Refreshes the gunlight action button state + the gun's icon overlays.
/obj/item/gun/proc/update_gunlight()
        if(alight)
                alight.build_all_button_icons()
        update_appearance()
