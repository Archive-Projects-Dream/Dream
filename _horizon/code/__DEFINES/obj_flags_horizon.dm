// horizon-dev-sync[bot] port
// Item flags missing from upstream /tg/station obj_flags.dm but referenced
// by horizon mechanics (do_messy / ammo_stack drops etc.).

/// Item flag: when dropped, the item will NOT have a randomized turn angle.
/// Mirrors upstream's NO_PIXEL_RANDOM_DROP but for the icon rotation.
#define NO_ANGLE_RANDOM_DROP (1<<18)
