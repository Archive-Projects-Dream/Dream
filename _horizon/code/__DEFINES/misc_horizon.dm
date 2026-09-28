// horizon-dev-sync[bot] port
// Defines missing from upstream /tg/station codebase but referenced by
// horizon mechanics (blood projectile, species inborn, element detach flag).

// ~ Plane / layer defines for legacy horizon code
/// Plane above the regular game plane - used by blood projectiles for FOV-hidden rendering
#define GAME_PLANE_UPPER (GAME_PLANE + 1)
/// Plane hidden from FOV effects, above GAME_PLANE_UPPER
#define GAME_PLANE_UPPER_FOV_HIDDEN (GAME_PLANE_UPPER + 1)
/// Layer for blood projectiles (above most mobs)
#define BLOOD_PROJECTILE_LAYER (ABOVE_ALL_MOB_LAYER + 0.5)

// ~ Species flags
/// Species trait: mob is inborn / can't be changed via character setup
#define SPECIES_INBORN "inborn"

// ~ Element flags (legacy - upstream uses ELEMENT_BESPOKE etc.)
/// Element should be detached when its host is destroyed
#define ELEMENT_DETACH (1<<1)

// ~ Bodypart / mob vars
/// Global list of bodypart datums keyed by body_zone. Upstream uses GLOB.all_bodyparts instead.
/// We initialize it from GLOB.all_bodyparts on first access.
