/obj/item/clothing/head/helmet/space/chronos/hrvfoxcat
	name = "Chronosuit Helmet"
	desc = "A white helmet with an opaque blue visor."
	icon_state = "skiesuit"
	inhand_icon_state = "skiesuit"
	slowdown = 1
	armor = list(MELEE = 60, BULLET = 60, LASER = 60, ENERGY = 60, BOMB = 30, BIO = 90, RAD = 90, FIRE = 100, ACID = 100)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	var/list/chronosafe_items = list(/obj/item/chrono_eraser, /obj/item/gun/energy/chrono_gun, /obj/item/gun/energy/pulse/pistol/m1911, /obj/item/storage/backpack/holding)
	mutant_variants = NONE


/obj/item/clothing/suit/space/chronos/hrvfoxcat
	name = "Chronosuit"
	desc = "An advanced spacesuit equipped with time-bluespace teleportation and anti-compression technology."
	icon_state = "skiesuit"
	inhand_icon_state = "skiesuit"
	actions_types = list(/datum/action/item_action/toggle_spacesuit, /datum/action/item_action/toggle)
	armor = list(MELEE = 60, BULLET = 60, LASER = 60, ENERGY = 60, BOMB = 30, BIO = 90, RAD = 90, FIRE = 100, ACID = 1000)
	resistance_flags = FIRE_PROOF | ACID_PROOF
