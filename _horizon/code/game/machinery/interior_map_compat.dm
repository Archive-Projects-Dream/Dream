/*
 * cmss13 compatibility vars and flags for objects placed by vehicle interior
 * maps. cmss13 declares explo_proof on /atom (code/game/atoms.dm);
 * Horizon-Dream does not, so interior map instances that set it would
 * otherwise throw "Undefined variable" runtimes in the map preloader
 * while their edits load.
 */

/obj/machinery/computer/crew
	var/explo_proof = FALSE

/obj/machinery/computer/security
	var/explo_proof = FALSE

/// Vehicle interiors are self-powered and have no APC; their looping ambient
/// buzz (engine hum) must not be gated on the station APC power check in
/// /mob/proc/refresh_looping_ambience(). Only /area/interior sets this.
/area
	var/ambient_buzz_apc_independent = FALSE
