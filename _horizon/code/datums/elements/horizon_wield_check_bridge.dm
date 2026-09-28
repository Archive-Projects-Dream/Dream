// horizon-dev-sync[bot] port
// Bridge between horizon's legacy COMSIG_TWOHANDED_WIELD_CHECK signal and
// upstream /tg/station's TRAIT_WIELDED trait system.
//
// Upstream /tg/station's /datum/component/two_handed adds TRAIT_WIELDED to
// the item when it's wielded, but does NOT send COMSIG_TWOHANDED_WIELD_CHECK
// (that signal is horizon-only). Horizon's _gun.dm uses
// `SEND_SIGNAL(src, COMSIG_TWOHANDED_WIELD_CHECK)` to check wield state.
//
// This element registers a signal handler on the item that returns
// COMPONENT_TWOHANDED_WIELDED when TRAIT_WIELDED is present, bridging the
// two systems without needing to override upstream's two_handed component.

/datum/element/horizon_wield_check_bridge
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH_ON_HOST_DESTROY

/datum/element/horizon_wield_check_bridge/Attach(datum/target)
	. = ..()
	if(!isitem(target))
		return ELEMENT_INCOMPATIBLE
	RegisterSignal(target, COMSIG_TWOHANDED_WIELD_CHECK, PROC_REF(on_wield_check))

/datum/element/horizon_wield_check_bridge/Detach(datum/source)
	. = ..()
	UnregisterSignal(source, COMSIG_TWOHANDED_WIELD_CHECK)

/// Returns COMPONENT_TWOHANDED_WIELDED if the item has TRAIT_WIELDED,
/// otherwise returns 0 (falsy) to indicate "not wielded".
/datum/element/horizon_wield_check_bridge/proc/on_wield_check(datum/source)
	SIGNAL_HANDLER
	if(HAS_TRAIT(source, TRAIT_WIELDED))
		return COMPONENT_TWOHANDED_WIELDED
	return NONE

// =============================================================================
// Auto-attach the bridge to all /obj/item so horizon's
// COMSIG_TWOHANDED_WIELD_CHECK checks work for any wieldable item.
// =============================================================================

/obj/item/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/horizon_wield_check_bridge)
