// Sakimm are small scavengers with an adoration for shiny things. They won't attack you for them, but you will be their friend holding something like a coin.

/datum/category_item/catalogue/fauna/sakimm
	name = "Sivian Fauna - Sakimm"
	desc = "Classification: S Procyon cogitae \
	<br><br>\
	Small, social omnivores known to collect objects within their dens. \
	The Sakimm form colonies that have been known to grow up to a hundred individuals. Primarily carnivorous hunters, \
	they often supplement their diets with nuts, roots, and other fruits. \
	Individuals are known to steal food and reflective objects from unsuspecting Sivian residents. \
	It is advised to keep any valuable items within dull wraps when venturing near the den of a Sakimm."
	value = CATALOGUER_REWARD_EASY

/mob/living/simple_mob/animal/sif/sakimm
	name = "sakimm"
	desc = "What appears to be an oversized rodent with hands."
	tt_desc = "S Procyon cogitae"
	catalogue_data = list(/datum/category_item/catalogue/fauna/sakimm)

	iff_factions = MOB_IFF_FACTION_BIND_TO_MAP

	icon_state = "raccoon"
	icon_living = "raccoon"
	icon_dead = "raccoon_dead"
	icon_rest = "raccoon_dead"
	icon = 'icons/mob/animal.dmi'

	maxHealth = 50
	health = 50
	randomized = TRUE
	hand_count = 2
	humanoid_hands = TRUE

	pass_flags = ATOM_PASS_TABLE

	universal_understand = 1

	movement_base_speed = 6.66

	legacy_melee_damage_lower = 5
	legacy_melee_damage_upper = 15
	base_attack_cooldown = 1 SECOND
	attacktext = list("nipped", "bit", "cut", "clawed")

	armor_legacy_mob = list(
		"melee" = 15,
		"bullet" = 5,
		"laser" = 5,
		"energy" = 0,
		"bomb" = 10,
		"bio" = 100,
		"rad" = 100
		)

	say_list_type = /datum/say_list/sakimm
	ai_holder_type = /datum/ai_holder/polaris/simple_mob/retaliate/cooperative/sakimm

	bone_amount = 2
	hide_amount = 2

	var/obj/item/clothing/head/hat = null // The hat the Sakimm may be wearing.
	var/list/friend_loot_list = list(/obj/item/coin)	// What will make this animal non-hostile if held?
	var/randomize_size = TRUE

/mob/living/simple_mob/animal/sif/sakimm/verb/remove_hat()
	set name = "Remove Hat"
	set desc = "Remove the animal's hat. You monster."
	set category = "Abilities"
	set src in view(1)

	drop_hat(usr)

/mob/living/simple_mob/animal/sif/sakimm/proc/drop_hat(var/mob/user)
	if(hat)
		hat.forceMove(get_turf(user))
		hat = null
		update_icon()
		if(user == src)
			to_chat(user, "<span class='notice'>You removed your hat.</span>")
			return
		to_chat(user, "<span class='warning'>You removed \the [src]'s hat. You monster.</span>")
	else
		if(user == src)
			to_chat(user, "<span class='notice'>You are not wearing a hat!</span>")
			return
		to_chat(user, "<span class='notice'>\The [src] is not wearing a hat!</span>")

/mob/living/simple_mob/animal/sif/sakimm/verb/give_hat()
	set name = "Give Hat"
	set desc = "Give the animal a hat. You hero."
	set category = "Abilities"
	set src in view(1)

	take_hat(usr)

/mob/living/simple_mob/animal/sif/sakimm/proc/take_hat(var/mob/user)
	if(hat)
		if(user == src)
			to_chat(user, "<span class='notice'>You already have a hat!</span>")
			return
		to_chat(user, "<span class='notice'>\The [src] already has a hat!</span>")
	else
		if(user == src)
			if(istype(get_active_held_item(), /obj/item/clothing/head))
				hat = get_active_held_item()
				transfer_item_to_loc(hat, src, INV_OP_FORCE)
				to_chat(src, "<span class='notice'>You put on the hat.</span>")
				update_icon()
			return
		else if(ishuman(user))
			var/mob/living/carbon/human/H = user

			if(istype(H.get_active_held_item(), /obj/item/clothing/head) && !get_active_held_item())
				var/obj/item/clothing/head/newhat = H.get_active_held_item()
				if(!H.attempt_insert_item_for_installation(newhat, get_turf(src)))
					return
				if(!stat)
					a_intent = INTENT_HELP
					newhat.attack_hand(src)
			else if(src.get_active_held_item())
				to_chat(user, "<span class='notice'>\The [src] seems busy with \the [get_active_held_item()] already!</span>")

			else
				to_chat(user, "<span class='warning'>You aren't holding a hat...</span>")

/datum/say_list/sakimm
	speak = list("Shurr.", "|R|rr?", "Hss.")
	emote_see = list("sniffs","looks around", "rubs its hands")
	emote_hear = list("chitters", "clicks")

/mob/living/simple_mob/animal/sif/sakimm/Destroy()
	if(hat)
		drop_hat(src)
	..()

/mob/living/simple_mob/animal/sif/sakimm/update_icon()
	cut_overlays()
	..()
	if(hat)
		var/mutable_appearance/MA = hat.render_mob_appearance(src, SLOT_ID_HEAD, BODYTYPE_STRING_DEFAULT)
		MA.appearance_flags = RESET_COLOR
		add_overlay(MA)

/mob/living/simple_mob/animal/sif/sakimm/Initialize(mapload)
	. = ..()

	add_verb(src, /mob/living/proc/ventcrawl)
	add_verb(src, /mob/living/proc/hide)

	if(randomize_size)
		adjust_scale(rand(8, 11) / 10)

/mob/living/simple_mob/animal/sif/sakimm/IIsAlly(mob/living/L)
	. = ..()

	var/mob/living/carbon/human/H = L
	if(!istype(H))
		return .

	if(!.)
		var/has_loot = FALSE
		var/obj/item/I = H.get_active_held_item()
		if(I)
			for(var/item_type in friend_loot_list)
				if(istype(I, item_type))
					has_loot = TRUE
					break
		return has_loot

/datum/ai_holder/polaris/simple_mob/retaliate/cooperative/sakimm/handle_special_strategical()	// Just needs to take hats.
	var/mob/living/simple_mob/animal/sif/sakimm/S = holder

	if(holder.get_active_held_item() && istype(holder.get_active_held_item(), /obj/item/clothing/head) && !S.hat)
		var/obj/item/I = holder.get_active_held_item()
		S.take_hat(S)
		holder.visible_message("<span class='notice'>\The [holder] wears \the [I]</span>")

/mob/living/simple_mob/animal/sif/sakimm/intelligent
	desc = "What appears to be an oversized rodent with hands. This one has a curious look in its eyes."
	ai_holder_type = /datum/ai_holder/polaris/simple_mob/intentional/sakimm
	randomize_size = FALSE	// Most likely to have a hat.

/datum/ai_holder/polaris/simple_mob/intentional/sakimm
	hostile = FALSE
	retaliate = TRUE
	vision_range = 10
	can_flee = TRUE
	flee_when_dying = TRUE

	var/greed = 0	// The probability we will try to steal something. Increases over time if we are not holding something, or wearing a hat.
	var/list/steal_loot_list = list(/obj/item/coin, /obj/item/gun, /obj/item/fossil, /obj/item/stack/material, /obj/item/material, /obj/item/reagent_containers/food/snacks, /obj/item/clothing/head, /obj/item/reagent_containers/glass, /obj/item/flashlight, /obj/item/stack/medical, /obj/item/seeds, /obj/item/spacecash)
	var/hoard_items = TRUE
	var/hoard_distance = 1	// How far an item can be from the Sakimm's home turf to be counted inside its 'hoard'.
	var/original_home_distance = null
	var/search_delay = 2 SECONDS	// How often can we look for item targets?
	var/last_search = 0

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/New()
	..()
	original_home_distance = max_home_distance

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/post_melee_attack(atom/A)
	if(istype(A, /obj/item) && !holder.get_active_held_item() && holder.Adjacent(A))
		var/obj/item/I = A
		I.attack_hand(holder)
		lose_target()
	if(istype(A,/mob/living) && holder.Adjacent(A))	// Not the dumbest tool in the shed. If we're fighting, we're gonna dance around them.
		holder.IMove(get_step(holder, pick(GLOB.alldirs)))
		holder.face_atom(A)
		request_help()	// And we're going to call friends, too.

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/list_targets()
	. = hearers(vision_range, holder) - holder

	var/static/hostile_machines = typecacheof(list(/obj/machinery/porta_turret, /obj/vehicle/sealed/mecha))

	for(var/HM in typecache_filter_list(range(vision_range, holder), hostile_machines))
		if(can_see(holder, HM, vision_range))
			. += HM

	if(holder.get_active_held_item())	// We don't want item targets if we have an item!
		return .

	if(world.time <= last_search + search_delay)	// Don't spam searching for item targets, since they can be in areas with a -lot- of items.
		return .

	for(var/obj/item/I in view(holder, vision_range))
		last_search = world.time
		if(!hoard_items || get_dist(I, home_turf) <= 1)
			continue
		for(var/itemtype in steal_loot_list)
			if(istype(I, itemtype))
				if(!I.anchored)
					. += I
				break

	. -= holder.contents

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/find_target(var/list/possible_targets, var/has_targets_list = FALSE)
	var/can_pick_mobs = TRUE

	if(!hostile)
		can_pick_mobs = FALSE

	. = list()
	if(!has_targets_list)
		possible_targets = list_targets()

	for(var/possible_target in possible_targets)
		var/atom/A = possible_target
		if(found(A))
			. = list(A)
			break
		if(istype(A, /mob/living) && !can_pick_mobs)
			continue
		if(can_attack(A)) // Can we attack it?
			. += A
			continue

	for(var/obj/item/I in .)
		last_search = world.time
		if(!hoard_items || get_dist(I, home_turf) <= 1)
			. -= I

	var/new_target = pick_target(.)
	give_target(new_target)
	return new_target

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/pre_melee_attack(atom/A)
	if(isliving(A))
		var/mob/living/L = A
		// Are we holding something? If so, drop it, we have a new target to kill, and we shouldn't use their weapons.
		holder.drop_active_held_item()

		if(ishuman(L))
			if(L.incapacitated(INCAPACITATION_DISABLED))	// Is our target on the ground? If so, let's scratch!
				if(prob(30))	// Unless we decide to cut and run, and take their stuff while we're at it.
					var/turf/T = get_turf(L)
					var/obj/item/IT = locate() in T.contents
					if(IT)
						lose_target()
						give_target(IT)
					return
				holder.a_intent = INTENT_HARM
			else
				holder.a_intent = INTENT_DISARM	// Otherwise, try to disarm them!
		else
			holder.a_intent = INTENT_HARM	// We can't disarm you, so we're going to hurt you.

	else if(istype(A, /obj/item))
		var/obj/item/I = A
		if(istype(I, /obj/item/reagent_containers/food/snacks))	// If we can't pick it up, or it's edible, go to harm.
			holder.a_intent = INTENT_HARM
		else
			holder.a_intent = INTENT_HELP

	else
		holder.a_intent = INTENT_HARM

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/should_go_home()
	if((!returns_home && !holder.get_active_held_item()) || !home_turf)	// If we have an item, we want to go home.
		return FALSE
	if(get_dist(holder, home_turf) > max_home_distance)
		if(!home_low_priority)
			return TRUE
		else if(!leader && !target)
			return TRUE
	return FALSE

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/handle_special_tactic()
	var/mob/living/simple_mob/animal/sif/sakimm/S = holder
	if(S.hat)
		hoard_items = FALSE
	else
		hoard_items = TRUE

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/handle_special_strategical()
	var/mob/living/simple_mob/animal/sif/sakimm/S = holder
	var/carrying_item = FALSE

	if(holder.get_active_held_item())	// Do we have loot?
		if(istype(holder) && istype(holder.get_active_held_item(), /obj/item/clothing/head) && !S.hat)
			var/obj/item/I = holder.get_active_held_item()
			S.take_hat(S)
			holder.visible_message("<span class='notice'>\The [holder] wears \the [I]</span>")
		carrying_item = TRUE

	if(istype(holder) && S.hat)		// Do we have a hat? Hats are loot.
		carrying_item = TRUE

	if(!carrying_item)	// Not carrying or wearing anything? We want to carry something more.
		greed++
		greed = min(95, greed)
	else
		greed = 0
	if(!target && prob(5 + greed) && !holder.get_active_held_item())
		find_target()
	if(holder.get_active_held_item() && hoard_items)
		lose_target()
		max_home_distance = 1
	if(get_dist(holder, home_turf) <= max_home_distance)
		holder.drop_active_held_item()
	if(!holder.get_active_held_item())
		max_home_distance = original_home_distance

/datum/ai_holder/polaris/simple_mob/intentional/sakimm/special_flee_check()
	return holder.get_active_held_item()

/mob/living/simple_mob/animal/sif/sakimm/dexter
	name = "Dexter"
	desc = "A tame, oversized rodent with hands. It seems really friendly."
	iff_factions = MOB_IFF_FACTION_NEUTRAL
