// horizon-dev-sync[bot] port
// Variables missing from upstream /tg/station codebase but referenced by
// horizon's _gun.dm. Upstream /tg/station moved flashlight attachable
// handling to a /datum/component/seclite_attachable, but horizon's _gun.dm
// directly references gun_light, can_flashlight, can_bayonet, bayonet, etc.
// These vars provide the backing fields for that legacy API.
//
// NOTE: vars already defined in _gun.dm (dry_fire_message, safety_flags,
// foldable, full_auto, etc.) are NOT duplicated here.

/obj/item/gun
        // ~FLASHLIGHT ATTACHMENT
        /// Whether this gun can accept a seclite flashlight
        var/can_flashlight = FALSE
        /// The attached flashlight, if any
        var/obj/item/flashlight/seclite/gun_light
        /// Icon state prefix for flashlight overlay
        var/gunlight_state = "flight"
        /// Pixel x offset for the flashlight overlay
        var/flight_x_offset = 0
        /// Pixel y offset for the flashlight overlay
        var/flight_y_offset = 0
        /// Action button granted to the user for toggling the gun light
        var/datum/action/item_action/toggle_gunlight/alight

        // ~BAYONET ATTACHMENT
        /// Whether this gun can accept a bayonet
        var/can_bayonet = FALSE
        /// The attached bayonet, if any
        var/obj/item/knife/bayonet
        /// Pixel x offset for the bayonet overlay
        var/knife_x_offset = 0
        /// Pixel y offset for the bayonet overlay
        var/knife_y_offset = 0

        /// Reference to the autofire component, if any. Used by safety toggle
        /// code to refresh mouse pointer / update action buttons.
        /// Set automatically by AddComponent(/datum/component/automatic_fire).
        var/datum/component/automatic_fire/autofire_component

// Legacy: fire selector position. 1 = semi, 2 = burst, 3 = full auto.
// Upstream removed `select` in favour of burst_fire_selection toggle.
// Horizon's _automatic.dm and rifle.dm read/write `select` directly.
/obj/item/gun/ballistic/automatic
        var/select = 1

// Legacy: recoil buildup when wielded. Read by horizon's rifle.dm.
/obj/item/gun/ballistic
        var/wielded_recoil_buildup = 0

