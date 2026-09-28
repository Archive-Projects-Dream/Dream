// horizon-dev-sync[bot] port
// Globals missing from upstream /tg/station codebase but referenced by
// horizon's _ammunition.dm (GLOB.proj_by_path_key).

/// Lazy-initialised list of projectile objects keyed by their type path.
/// Upstream /tg/station removed GLOB.proj_by_path_key. We provide a global
/// fallback that horizon's _ammunition.dm uses to look up a projectile's
/// stats for the examine UI.
GLOBAL_LIST_EMPTY(proj_by_path_key)
