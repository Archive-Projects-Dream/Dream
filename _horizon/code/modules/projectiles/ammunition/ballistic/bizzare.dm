/obj/item/ammo_casing/batteries
    name = "double ay battery"
    desc = "Finally, I can get that fucking gas analyzer."
    icon = '_horizon/icons/obj/items/ammo/batteries.dmi'
    world_icon_state = '_horizon/icons/obj/items/ammo/batteries.dmi'
    icon_state = "BB"
    base_icon_state = "BB"
    world_icon_state = "BB"
    caliber = CALIBER_BATTERY
    projectile_type = /obj/projectile/bullet/p50
    bounce_sound = list('_horizon/sound/weapons/guns/pistol/pistol_shell1.wav', '_horizon/sound/weapons/guns/pistol/pistol_shell2.wav', '_horizon/sound/weapons/guns/pistol/pistol_shell3.wav')
    bounce_volume = 35
    stack_type = /obj/item/ammo_box/magazine/ammo_stack/batteries
    w_class = WEIGHT_CLASS_TINY

/obj/item/ammo_casing/batteries/bigvolt
    name = "single ay battery"
    desc = "that's a very chunky battery"
    icon = '_horizon/icons/obj/items/ammo/batteries.dmi'
    world_icon_state = '_horizon/icons/obj/items/ammo/batteries.dmi'
    icon_state = "AA"
    base_icon_state = "AA"
    world_icon_state = "AA"
    caliber = CALIBER_BATTERY
    projectile_type = /obj/projectile/bullet/p50
    bounce_sound = list('_horizon/sound/weapons/guns/pistol/pistol_shell1.wav', '_horizon/sound/weapons/guns/pistol/pistol_shell2.wav', '_horizon/sound/weapons/guns/pistol/pistol_shell3.wav')
    bounce_volume = 35
    stack_type = null
    w_class = WEIGHT_CLASS_TINY
