/obj/item/stamp
	name = "rubber stamp"
	desc = "A rubber stamp for stamping important documents."
	icon = 'icons/obj/bureaucracy.dmi'
	icon_state = "stamp-qm"
	item_state = "stamp"
	throw_force = 0
	w_class = WEIGHT_CLASS_TINY
	slot_flags = SLOT_HOLSTER
	throw_speed = 7
	throw_range = 15
	materials_base = list(MAT_STEEL = 60)
	pressure_resistance = 2
	attack_verb = list("stamped")

	var/list/stamp_sounds = list(
		'sound/items/stamp1.ogg',
		'sound/items/stamp2.ogg',
		'sound/items/stamp3.ogg'
		)

/obj/item/stamp/legacy_mob_melee_hook(mob/target, mob/user, clickchain_flags, list/params, mult, target_zone, intent)
	. = ..()
	playsound(target, pick(stamp_sounds), 30, 1, -1)

/obj/item/stamp/captain
	name = "Facility Director's rubber stamp"
	icon_state = "stamp-cap"

/obj/item/stamp/hop
	name = "head of personnel's rubber stamp"
	icon_state = "stamp-hop"

/obj/item/stamp/hos
	name = "head of security's rubber stamp"
	icon_state = "stamp-hos"

/obj/item/stamp/ward
	name = "warden's rubber stamp"
	icon_state = "stamp-ward"

/obj/item/stamp/ce
	name = "chief engineer's rubber stamp"
	icon_state = "stamp-ce"

/obj/item/stamp/rd
	name = "research director's rubber stamp"
	icon_state = "stamp-rd"

/obj/item/stamp/cmo
	name = "chief medical officer's rubber stamp"
	icon_state = "stamp-cmo"

/obj/item/stamp/denied
	name = "\improper DENIED rubber stamp"
	icon_state = "stamp-deny"

/obj/item/stamp/clown
	name = "clown's rubber stamp"
	icon_state = "stamp-clown"

/obj/item/stamp/internalaffairs
	name = "internal affairs rubber stamp"
	icon_state = "stamp-intaff"

/obj/item/stamp/centcom
	name = "\improper CentCom rubber stamp"
	icon_state = "stamp-cent"

/obj/item/stamp/qm
	name = "quartermaster's rubber stamp"
	icon_state = "stamp-qm"

/obj/item/stamp/cargo
	name = "cargo rubber stamp"
	icon_state = "stamp-cargo"

/obj/item/stamp/oricon
	name = "\improper Orion Confederation rubber stamp"
	icon_state = "stamp-sg"


// Syndicate stamp to forge documents.
/obj/item/stamp/chameleon/attack_self(mob/user, datum/event_args/actor/actor)
	. = ..()
	if(.)
		return

	var/list/stamp_types = typesof(/obj/item/stamp) - src.type // Get all stamp types except our own
	var/list/stamps = list()

	// Generate them into a list
	for(var/stamp_type in stamp_types)
		var/obj/item/stamp/S = new stamp_type
		stamps[capitalize(S.name)] = S

	var/list/show_stamps = list("EXIT" = null) + sortList(stamps) // the list that will be shown to the user to pick from

	var/input_stamp = input(user, "Choose a stamp to disguise as.", "Choose a stamp.") in show_stamps

	if(user && (src in user.contents))

		var/obj/item/stamp/chosen_stamp = stamps[capitalize(input_stamp)]

		if(chosen_stamp)
			name = chosen_stamp.name
			icon_state = chosen_stamp.icon_state
