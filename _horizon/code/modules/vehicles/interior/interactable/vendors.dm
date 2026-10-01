/*
 * Interior vendors, ported from cmss13
 * code/modules/vehicles/interior/interactable/vendors.dm
 *
 * cmss13's cm_vending machines don't exist in Horizon-Dream, so these are
 * reimplemented on the TG vending machinery: a wall-mounted NanoMed-style
 * medical vendor and a vehicle supply rack that also stocks hardpoint
 * ammunition magazines. Everything is free - the crew paid for it already.
 */

/// Wall-mounted medical supply vendor for vehicle interiors
/obj/machinery/vending/wallmed/vehicle
	name = "Vehicle NanoMed"
	desc = "A wall-mounted vendor containing medical supplies vital to survival."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "nanomed"
	icon_deny = null
	panel_type = null
	light_mask = null
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	all_products_free = TRUE
	tiltable = FALSE

/obj/machinery/vending/wallmed/vehicle/wy
	icon = '_horizon/icons/vehicles/obj/interiors/general_wy.dmi'

/// Compact medical resupply station used in the MED APC
/obj/machinery/vending/medical/vehicle
	name = "\improper Med Resupply Station"
	desc = "A more compact vehicle version of the medical pharmaceutical dispenser. Designed to be a field resupply station for medical personnel."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "med"
	icon_deny = null
	panel_type = null
	light_mask = null
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	all_products_free = TRUE
	tiltable = FALSE
	products = list(
		/obj/item/reagent_containers/syringe = 5,
		/obj/item/healthanalyzer = 2,
		/obj/item/reagent_containers/applicator/patch/synthflesh = 8,
		/obj/item/reagent_containers/applicator/pill/salbutamol = 5,
		/obj/item/reagent_containers/applicator/pill/mannitol = 5,
		/obj/item/reagent_containers/hypospray/medipen = 4,
		/obj/item/stack/medical/bruise_pack = 6,
		/obj/item/stack/medical/wrap/gauze = 5,
		/obj/item/reagent_containers/blood/o_minus = 2,
		/obj/item/bodybag = 4,
	)

/// W-Y skinned med resupply station; the W-Y sheet has no "med" state, so the
/// standard body is used with corporate branding in the name only.
/obj/machinery/vending/medical/vehicle/wy
	name = "\improper Wey-Med Resupply Station"

/// Vehicle supply rack carrying ammo and hardpoint magazines
/obj/machinery/vending/supply/vehicle
	name = "\improper Automated Supply Rack"
	desc = "An automated supply rack hooked up to a vehicle storage of various firearms, explosives and ammunition types. Used for storing and transporting supplies between forward operating bases and the frontline."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "supply"
	icon_deny = null
	panel_type = null
	light_mask = null
	anchored = TRUE
	density = FALSE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	all_products_free = TRUE
	tiltable = FALSE
	products = list(
		// Vehicle hardpoint ammunition
		/obj/item/ammo_magazine/hardpoint/ace_autocannon = 2,
		/obj/item/ammo_magazine/hardpoint/ltb_cannon = 2,
		/obj/item/ammo_magazine/hardpoint/ltaaap_minigun = 1,
		/obj/item/ammo_magazine/hardpoint/primary_flamer = 2,
		/obj/item/ammo_magazine/hardpoint/secondary_flamer = 2,
		/obj/item/ammo_magazine/hardpoint/boyars_dualcannon = 2,
		/obj/item/ammo_magazine/hardpoint/arc_sentry = 2,
		/obj/item/ammo_magazine/hardpoint/m56_cupola = 1,
		/obj/item/ammo_magazine/hardpoint/tank_glauncher = 3,
		/obj/item/ammo_magazine/hardpoint/towlauncher = 1,
		/obj/item/ammo_magazine/hardpoint/flare_launcher = 3,
		/obj/item/ammo_magazine/hardpoint/turret_smoke = 2,
		// General supplies
		/obj/item/flashlight = 4,
		/obj/item/radio = 4,
		/obj/item/crowbar = 2,
		/obj/item/weldingtool = 2,
		/obj/item/stack/sheet/iron/fifty = 2,
		/obj/item/storage/medkit/regular = 2,
	)

/// W-Y skinned supply rack; the W-Y interior sheet has no "supply" state, so
/// the standard body is used with corporate branding in the name only.
/obj/machinery/vending/supply/vehicle/wy
	name = "\improper W-Y Automated Supply Rack"
