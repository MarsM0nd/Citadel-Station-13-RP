/datum/power/shadekin

/mob/living/carbon/human/is_incorporeal()
	if(ability_flags & AB_PHASE_SHIFTED) //Shadekin
		return TRUE
	return ..()

/////////////////////
///  PHASE SHIFT  ///
/////////////////////
//Visual effect for phase in/out
/obj/effect/temp_visual/shadekin
	randomdir = FALSE
	duration = 5
	icon = 'icons/mob/vore_shadekin.dmi'

/obj/effect/temp_visual/shadekin/phase_in
	icon_state = "tp_in"

/obj/effect/temp_visual/shadekin/phase_out
	icon_state = "tp_out"

/datum/power/shadekin/phase_shift
	name = "Phase Shift (100)"
	desc = "Shift yourself out of alignment with realspace to travel quickly to different areas."
	verbpath = /mob/living/carbon/human/proc/phase_shift
	ability_icon_state = "wiz_jaunt"

/mob/living/carbon/human/proc/phase_shift()
	set name = "Phase Shift (100)"
	set desc = "Shift yourself out of alignment with realspace to travel quickly to different areas."
	set category = "Shadekin"

	var/ability_cost = 100

	if(species.get_species_id() != SPECIES_ID_SHADEKIN)
		to_chat(src, SPAN_WARNING("Only a shadekin can use that!"))
		return FALSE
	else if(stat)
		to_chat(src, SPAN_WARNING("Can't use that ability in your state!"))
		return FALSE
	else if(shadekin_get_energy() < ability_cost && !(ability_flags & AB_PHASE_SHIFTED))
		to_chat(src, SPAN_WARNING("Not enough energy for that ability!"))
		return FALSE

	var/darkness = 1
	var/turf/T = get_turf(src)
	if(!T)
		to_chat(src, SPAN_WARNING("You can't use that here!"))
		return FALSE

	var/brightness = T.get_lumcount() //Brightness in 0.0 to 1.0
	darkness = 1-brightness //Invert

	var/watcher = 0
	for(var/mob/living/carbon/human/watchers in oview(7,src ))	// If we can see them...
		if(watchers in oviewers(7,src))	// And they can see us...
			if(!(watchers.stat) && !isbelly(watchers.loc) && !istype(watchers.loc, /obj/item/holder))	// And they are alive and not being held by someone...
				watcher++	// They are watching us!

	ability_cost = clamp(ability_cost/(0.01+darkness*2),50, 80)//This allows for 1 watcher in full light
	if(watcher>0)
		ability_cost = ability_cost + ( 15 * watcher )
	if(!(ability_flags & AB_PHASE_SHIFTED))
		log_debug(SPAN_DEBUGWARNING("[src] attempted to shift with [watcher] visible Carbons with a  cost of [ability_cost] in a darkness level of [darkness]"))

	if(!(ability_flags & AB_PHASE_SHIFTED))
		shadekin_adjust_energy(-ability_cost)
	playsound(src, 'sound/effects/stealthoff.ogg', 75, TRUE)

	if(!T.CanPass(src,T) || loc != T)
		to_chat(src, SPAN_WARNING("You can't use that here!"))
		return FALSE

	if(!(ability_flags & AB_PHASE_SHIFTED))
		shadekin_adjust_energy(-ability_cost)
	playsound(src, 'sound/effects/stealthoff.ogg', 75, TRUE)

	forceMove(T)
	set_stunned(0)
	set_paralyzed(0)
	unbuckle(BUCKLE_OP_FORCE)
	break_pull()
	stop_pulling()

	//Shifting in
	if(ability_flags & AB_PHASE_SHIFTED)
		ability_flags &= ~AB_PHASE_SHIFTED
		mouse_opacity = 2
		name = real_name
		for(var/belly in vore_organs)
			var/obj/belly/B = belly
			B.escapable = initial(B.escapable)

		// cut_overlays()
		invisibility = initial(invisibility)
		see_invisible = initial(see_invisible)
		incorporeal_move = initial(incorporeal_move)
		density = initial(density)
		remove_movespeed_modifier(/datum/movespeed_modifier/forced_speedup/shadein_jaunt)
		update_icon()

		//Cosmetics mostly
		var/obj/effect/temp_visual/shadekin/phase_in/phaseanim = new /obj/effect/temp_visual/shadekin/phase_in(src.loc)
		phaseanim.dir = dir
		alpha = 0
		custom_emote(1,"phases in!")
		remove_a_modifier_of_type(/datum/modifier/shadekin_phase_vision)
		RemoveSightSelf(SEE_THRU)
		sleep(5) //The duration of the TP animation
		alpha = initial(alpha)

		// probably replace with a trait later.
		remove_atom_phasing(SPECIES_SHADEKIN_PHASING_TRAIT)

		//Potential phase-in vore
		if(can_be_drop_pred) //Toggleable in vore panel
			var/list/potentials = living_mobs(0)
			if(potentials.len)
				var/mob/living/target = pick(potentials)
				if(istype(target) && vore_selected)
					target.forceMove(vore_selected)
					to_chat(target, SPAN_WARNING("\The [src] phases in around you, [vore_selected.vore_verb]ing you into their [vore_selected.name]!"))

		//Affect nearby lights
		var/destroy_lights = 0

		for(var/obj/machinery/light/L in GLOB.machines)
			if(L.z != z || get_dist(src,L) > 10)
				continue

			if(prob(destroy_lights))
				spawn(rand(5,25))
					L.broken()
			else
				L.flicker(10)
	//Shifting out
	else
		ability_flags |= AB_PHASE_SHIFTED
		mouse_opacity = 0
		custom_emote(1,"phases out!")
		name = "Something"

		for(var/obj/belly/B as anything in vore_organs)
			B.escapable = FALSE

		var/obj/effect/temp_visual/shadekin/phase_out/phaseanim = new /obj/effect/temp_visual/shadekin/phase_out(src.loc)
		phaseanim.dir = dir
		alpha = 0
		add_modifier(/datum/modifier/shadekin_phase_vision)
		sleep(5)
		invisibility = INVISIBILITY_LEVEL_TWO
		see_invisible = INVISIBILITY_LEVEL_TWO
		// cut_overlays()
		update_icon()
		alpha = 127

		// probably replace with a trait later.
		add_atom_phasing(SPECIES_SHADEKIN_PHASING_TRAIT)
		add_movespeed_modifier(/datum/movespeed_modifier/forced_speedup/shadein_jaunt)

		incorporeal_move = TRUE
		density = FALSE

/*
/mob/living/carbon/human/MouseDroppedOnLegacy(atom/dropping, mob/user)
	if(ability_flags & AB_PHASE_SHIFTED)
		return FALSE	//Nope!

	return ..()
*/

/datum/modifier/shadekin_phase_vision
	name = "Shadekin Phase Vision"
	vision_flags = SEE_THRU


//////////////////////////
///  REGENERATE OTHER  ///
//////////////////////////
/datum/power/shadekin/regenerate_other
	name = "Regenerate Other (50)"
	desc = "Spend energy to heal physical wounds in another creature."
	verbpath = /mob/living/carbon/human/proc/regenerate_other
	ability_icon_state = "tech_biomedaura"

/mob/living/carbon/human/proc/regenerate_other()
	set name = "Regenerate Other (50)"
	set desc = "Spend energy to heal physical wounds in another creature."
	set category = "Shadekin"

	var/ability_cost = 50

	//var/datum/species/shadekin/SK = species
	if(species.get_species_id() != SPECIES_ID_SHADEKIN)
		to_chat(src, "<span class='warning'>Only a shadekin can use that!</span>")
		return FALSE
	else if(stat)
		to_chat(src, "<span class='warning'>Can't use that ability in your state!</span>")
		return FALSE
	else if(shadekin_get_energy() < ability_cost)
		to_chat(src, "<span class='warning'>Not enough energy for that ability!</span>")
		return FALSE
	else if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, "<span class='warning'>You can't use that while phase shifted!</span>")
		return FALSE

	var/list/targets = list()
	for(var/mob/living/L in view(1))
		targets += L
	if(!targets.len)
		to_chat(src,"<span class='warning'>Nobody nearby to mend!</span>")
		return FALSE

	var/mob/living/target = input(src,"Pick someone to mend:","Mend Other") as null|anything in targets
	if(!target)
		return FALSE

	target.add_modifier(/datum/modifier/shadekin/heal_boop,1 MINUTE)
	playsound(src, 'sound/effects/EMPulse.ogg', 75, 1)
	shadekin_adjust_energy(-ability_cost)
	visible_message("<span class='notice'>\The [src] gently places a hand on \the [target]...</span>")
	face_atom(target)
	return TRUE

/datum/modifier/shadekin/heal_boop
	name = "Shadekin Regen"
	desc = "You feel serene and well rested."
	mob_overlay_state = "green_sparkles"

	on_created_text = "<span class='notice'>Sparkles begin to appear around you, and all your ills seem to fade away.</span>"
	on_expired_text = "<span class='notice'>The sparkles have faded, although you feel much healthier than before.</span>"
	stacks = MODIFIER_STACK_EXTEND

/datum/modifier/shadekin/heal_boop/tick()
	if(!holder.getBruteLoss() && !holder.getFireLoss() && !holder.getToxLoss() && !holder.getOxyLoss() && !holder.getCloneLoss()) // No point existing if the spell can't heal.
		expire()
		return
	holder.adjustBruteLoss(-2)
	holder.adjustFireLoss(-2)
	holder.adjustToxLoss(-2)
	holder.adjustOxyLoss(-2)
	holder.adjustCloneLoss(-2)


//////////////////////
///  CREATE SHADE  ///
//////////////////////
/datum/power/shadekin/create_shade
	name = "Create Shade (25)"
	desc = "Create a field of darkness that follows you."
	verbpath = /mob/living/carbon/human/proc/create_shade
	ability_icon_state = "tech_dispelold"

/mob/living/carbon/human/proc/create_shade()
	set name = "Create Shade (25)"
	set desc = "Create a field of darkness that follows you."
	set category = "Shadekin"

	var/ability_cost = 25

	//var/datum/species/shadekin/SK = species
	if(species.get_species_id() != SPECIES_ID_SHADEKIN)
		to_chat(src, "<span class='warning'>Only a shadekin can use that!</span>")
		return FALSE
	else if(stat)
		to_chat(src, "<span class='warning'>Can't use that ability in your state!</span>")
		return FALSE
	else if(shadekin_get_energy() < ability_cost)
		to_chat(src, "<span class='warning'>Not enough energy for that ability!</span>")
		return FALSE
	else if(ability_flags & AB_PHASE_SHIFTED)
		to_chat(src, "<span class='warning'>You can't use that while phase shifted!</span>")
		return FALSE

	playsound(src, 'sound/effects/bamf.ogg', 75, 1)

	add_modifier(/datum/modifier/shadekin/create_shade,20 SECONDS)
	shadekin_adjust_energy(-ability_cost)
	return TRUE

/datum/modifier/shadekin/create_shade
	name = "Shadekin Shadegen"
	desc = "Darkness envelops you."
	mob_overlay_state = ""

	on_created_text = "<span class='notice'>You drag part of The Dark into realspace, enveloping yourself.</span>"
	on_expired_text = "<span class='warning'>You lose your grasp on The Dark and realspace reasserts itself.</span>"
	stacks = MODIFIER_STACK_EXTEND

	var/mob/living/carbon/human/my_kin
	var/range = 8
	var/power = -10

/datum/modifier/shadekin/create_shade/tick()
	if(my_kin.ability_flags & AB_PHASE_SHIFTED)
		expire()

/datum/modifier/shadekin/create_shade/on_applied()
	my_kin = holder
	holder.glow_toggle = TRUE
	holder.set_light(range, power, "#FFFFFF")

/datum/modifier/shadekin/create_shade/on_expire()
	holder.glow_toggle = initial(holder.glow_toggle)
	holder.set_light(initial(holder.glow_range), initial(holder.glow_intensity), initial(holder.glow_color))
	my_kin = null
