// horizon-dev-sync[bot] port
// Signals missing from upstream /tg/station codebase but referenced by
// horizon mechanics (gun wielding checks, etc.).

/// Sent to a two-handed item to ask whether it is currently wielded with both hands.
/// Returns `COMPONENT_TWOHANDED_WIELDED` (or a truthy value) when wielded.
#define COMSIG_TWOHANDED_WIELD_CHECK "twohanded_wield_check"

/// Returned by two-handed items when they ARE currently wielded in both hands.
#define COMPONENT_TWOHANDED_WIELDED (1<<0)
