// horizon-dev-sync[bot] port
// Globals missing from upstream /tg/station codebase but referenced by
// horizon's _firing.dm (GLOB.bodyparts_by_zone) and _ammunition.dm
// (GLOB.proj_by_path_key).

/// Lazy-initialised list of bodypart datums keyed by body_zone.
/// Upstream /tg/station removed GLOB.bodyparts_by_zone in favour of
/// mob.get_bodyparts_by_zones(). We provide a global fallback that
/// looks up a "template" bodypart for each zone, used by horizon's
/// _firing.dm to read ranged_hit_zone_modifier.
GLOBAL_LIST_EMPTY(bodyparts_by_zone)

/// Lazy-initialised list of projectile objects keyed by their type path.
/// Upstream /tg/station removed GLOB.proj_by_path_key. We provide a global
/// fallback that horizon's _ammunition.dm uses to look up a projectile's
/// stats for the examine UI.
GLOBAL_LIST_EMPTY(proj_by_path_key)
