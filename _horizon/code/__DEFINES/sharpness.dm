// horizon-dev-sync[bot] port
// Sharpness flag missing from upstream /tg/station obj_flags.dm but used
// by horizon's translate_sharpness() helper and various projectile/item defines.

/// Items/projectiles with this sharpness flag impale targets on hit.
#define SHARP_IMPALING (1<<2)
