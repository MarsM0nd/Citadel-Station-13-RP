// **********************
// Other harvested materials from plants (that are not food)
// **********************

/obj/item/grown // Grown weapons
	name = "grown_weapon"
	icon = 'icons/obj/weapons.dmi'
	var/plantname
	var/potency = 1

/obj/item/grown/Initialize(mapload, planttype)
	. = ..()
	var/datum/reagent_holder/R = new/datum/reagent_holder(50)
	reagents = R
	R.my_atom = src

	//Handle some post-spawn var stuff.
	if(planttype)
		plantname = planttype
		var/datum/seed/S = SSplants.seeds[plantname]
		if(!S || !S.chems)
			return

		potency = S.get_trait(TRAIT_POTENCY)

		for(var/rid in S.chems)
			var/list/reagent_data = S.chems[rid]
			var/rtotal = reagent_data[1]
			if(reagent_data.len > 1 && potency > 0)
				rtotal += round(potency/reagent_data[2])
			reagents.add_reagent(rid,max(1,rtotal))

/obj/item/corncob
	name = "corn cob"
	desc = "A reminder of meals gone by."
	icon = 'icons/obj/trash.dmi'
	icon_state = "corncob"
	atom_flags = NOCONDUCT
	w_class = WEIGHT_CLASS_SMALL
	throw_force = 0
	throw_speed = 4
	throw_range = 20

/obj/item/corncob/attackby(obj/item/W as obj, mob/user as mob)
	..()
	if(istype(W, /obj/item/surgical/circular_saw) || istype(W, /obj/item/material/knife/machete/hatchet) || istype(W, /obj/item/material/knife))
		to_chat(user, "<span class='notice'>You use [W] to fashion a pipe out of the corn cob!</span>")
		new /obj/item/clothing/mask/smokable/pipe/cobpipe (user.loc)
		qdel(src)
		return

//* Banana Peels *//

/datum/component/slippery/banana_peel

// todo: /banana_peel
/obj/item/bananapeel
	name = "banana peel"
	desc = "A peel from a banana."
	icon = 'icons/obj/items.dmi'
	icon_state = "banana_peel"
	atom_flags = NOCONDUCT
	w_class = WEIGHT_CLASS_SMALL
	throw_force = 0
	throw_speed = 4
	throw_range = 20

/obj/item/bananapeel/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/slippery/banana_peel)
