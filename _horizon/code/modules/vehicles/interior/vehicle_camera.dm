/*
 * Vehicle cameras, ported from cmss13 /obj/structure/machinery/camera/vehicle
 * (which does not exist in Horizon-Dream's /obj/machinery/camera tree, so we
 * define it here as a subtype of the TG camera).
 */

/obj/machinery/camera/vehicle
	name = "vehicle camera"
	desc = "A rugged external camera mounted on a vehicle hull."
	icon = '_horizon/icons/vehicles/obj/interiors/general.dmi'
	icon_state = "vehicle_camera"
	base_icon_state = "vehicle_camera"
	c_tag = "VEHICLE"
	use_power = NO_POWER_USE
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	start_active = TRUE
/obj/machinery/camera/vehicle/Initialize(mapload)
	. = ..()
/// Toggles the camera on and off with the vehicle's power state.
/obj/machinery/camera/vehicle/proc/toggle_cam_status(on)
	if(camera_enabled == on)
		return
	toggle_cam(null, FALSE)