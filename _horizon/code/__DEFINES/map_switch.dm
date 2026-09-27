// Cant really be a build flag as this is a mapping thing.
//#define SHOW_INVENTORY_ICONS //uncomment this to make mapping software use inventory icons rather then world icons

#if defined(CBT) || defined(SHOW_INVENTORY_ICONS)
#define ONFLOOR_ICON_HELPER(_icon) onflooricon = ##_icon
#else
#define ONFLOOR_ICON_HELPER(_icon) icon = ##_icon; onflooricon = ##_icon
#endif

// Was getting weird behavoir when I had the defines in the same if define.
#if defined(CBT) || defined(SHOW_INVENTORY_ICONS)
#define ONFLOOR_ICONSTATE_HELPER(_icon_state) onflooricon_state = ##_icon_state
#else
#define ONFLOOR_ICONSTATE_HELPER(_icon_state) icon_state = ##_icon_state; onflooricon_state = ##_icon_state
#endif
