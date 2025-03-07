// The Casing //
/obj/item/ammo_casing/microbattery/medical
	name = "\'AML\' nanite cell - UNKNOWN"
	desc = "A miniature nanite fabricator for a medigun."
	catalogue_data = list(/datum/category_item/catalogue/information/organization/vey_med)
	icon_state = "ml3m_batt"
	origin_tech = list(TECH_BIO = 2, TECH_MATERIAL = 1, TECH_MAGNETS = 2)

/obj/projectile/beam/medical_cell
	name = "\improper healing beam"
	icon_state = "medbeam"
	nodamage = 1
	damage_force = 0
	damage_flag = ARMOR_LASER
	light_color = "#80F5FF"

	combustion = FALSE

	legacy_muzzle_type = /obj/effect/projectile/muzzle/medigun
	legacy_tracer_type = /obj/effect/projectile/tracer/medigun
	legacy_impact_type = /obj/effect/projectile/impact/medigun

/obj/projectile/beam/medical_cell/on_impact(atom/target, impact_flags, def_zone, efficiency)
	. = ..()
	if(ishuman(target))
		on_hit_legacy(target)

/obj/projectile/beam/medical_cell/proc/on_hit_legacy(var/mob/living/carbon/human/target) //what does it do when it hits someone?
	return

/obj/item/ammo_casing/microbattery/medical/brute
	name = "\'AML\' nanite cell - BRUTE"
	type_color = "#BF0000"
	type_name = "<span style='color:#BF0000;font-weight:bold;'>BRUTE</span>"
	projectile_type = /obj/projectile/beam/medical_cell/brute

/obj/projectile/beam/medical_cell/brute/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustBruteLoss(-10)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/burn
	name = "\'AML\' nanite cell - BURN"
	type_color = "#FF8000"
	type_name = "<span style='color:#FF8000;font-weight:bold;'>BURN</span>"
	projectile_type = /obj/projectile/beam/medical_cell/burn

/obj/projectile/beam/medical_cell/burn/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustFireLoss(-10)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/stabilize
	name = "\'AML\' nanite cell - STABILIZE" //Disinfects all open wounds, cures oxy damage
	type_color = "#0080FF"
	type_name = "<span style='color:#0080FF;font-weight:bold;'>STABILIZE</span>"
	projectile_type = /obj/projectile/beam/medical_cell/stabilize

/obj/projectile/beam/medical_cell/stabilize/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustOxyLoss(-30)
		for(var/name in list(BP_HEAD, BP_L_HAND, BP_R_HAND, BP_L_ARM, BP_R_ARM, BP_L_FOOT, BP_R_FOOT, BP_L_LEG, BP_R_LEG, BP_GROIN, BP_TORSO))
			var/obj/item/organ/external/O = target.organs_by_name[name]
			for (var/datum/wound/W as anything in O.wounds)
				if (W.internal)
					continue
				W.disinfect()
		target.add_modifier(/datum/modifier/stabilize, 20 SECONDS)
	else
		return 1

/datum/modifier/stabilize
	name = "stabilize"
	desc = "Your injuries are stabilized and your pain abates!"
	mob_overlay_state = "cyan_sparkles"
	stacks = MODIFIER_STACK_EXTEND
	pain_immunity = TRUE
	bleeding_rate_percent = 0.1 //only a little
	incoming_oxy_damage_percent = 0

/obj/item/ammo_casing/microbattery/medical/toxin
	name = "\'AML\' nanite cell - TOXIN"
	type_color = "#00A000"
	type_name = "<span style='color:#00A000;font-weight:bold;'>TOXIN</span>"
	projectile_type = /obj/projectile/beam/medical_cell/toxin

/obj/projectile/beam/medical_cell/toxin/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustToxLoss(-10)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/omni
	name = "\'AML\' nanite cell - OMNI"
	type_color = "#8040FF"
	type_name = "<span style='color:#8040FF;font-weight:bold;'>OMNI</span>"
	projectile_type = /obj/projectile/beam/medical_cell/omni

/obj/projectile/beam/medical_cell/omni/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustBruteLoss(-2.5)
		target.adjustFireLoss(-2.5)
		target.adjustToxLoss(-2.5)
		target.adjustOxyLoss(-20)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/antirad
	name = "\'AML\' nanite cell - ANTIRAD"
	type_color = "#008000"
	type_name = "<span style='color:#008000;font-weight:bold;'>ANTIRAD</span>"
	projectile_type = /obj/projectile/beam/medical_cell/antirad

/obj/projectile/beam/medical_cell/antirad/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustToxLoss(-2.5)
		target.cure_radiation(RAD_MOB_CURE_STRENGTH_MEDIGUN)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/brute2
	name = "\'AML\' nanite cell - BRUTE-II"
	type_color = "#BF0000"
	type_name = "<span style='color:#BF0000;font-weight:bold;'>BRUTE-II</span>"
	projectile_type = /obj/projectile/beam/medical_cell/brute2

/obj/projectile/beam/medical_cell/brute2/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustBruteLoss(-20)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/burn2
	name = "\'AML\' nanite cell - BURN-II"
	type_color = "#FF8000"
	type_name = "<span style='color:#FF8000;font-weight:bold;'>BURN-II</span>"
	projectile_type = /obj/projectile/beam/medical_cell/burn2

/obj/projectile/beam/medical_cell/burn2/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustFireLoss(-20)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/stabilize2
	name = "\'AML\' nanite cell - STABILIZE-II" //Disinfects and bandages all open wounds, cures all oxy damage
	type_color = "#0080FF"
	type_name = "<span style='color:#0080FF;font-weight:bold;'>STABILIZE-II</span>"
	projectile_type = /obj/projectile/beam/medical_cell/stabilize2

/obj/projectile/beam/medical_cell/stabilize2/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustOxyLoss(-200)
		for(var/name in list(BP_HEAD, BP_L_HAND, BP_R_HAND, BP_L_ARM, BP_R_ARM, BP_L_FOOT, BP_R_FOOT, BP_L_LEG, BP_R_LEG, BP_GROIN, BP_TORSO))
			var/obj/item/organ/external/O = target.organs_by_name[name]
			for (var/datum/wound/W as anything in O.wounds)
				if(W.internal)
					continue
				if(O.is_bandaged() == FALSE)
					W.bandage()
				if(O.is_salved() == FALSE)
					W.salve()
				W.disinfect()
		target.add_modifier(/datum/modifier/stabilize, 20 SECONDS)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/omni2
	name = "\'AML\' nanite cell - OMNI-II"
	type_color = "#8040FF"
	type_name = "<span style='color:#8040FF;font-weight:bold;'>OMNI-II</span>"
	projectile_type = /obj/projectile/beam/medical_cell/omni2

/obj/projectile/beam/medical_cell/omni2/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustBruteLoss(-5)
		target.adjustFireLoss(-5)
		target.adjustToxLoss(-5)
		target.adjustOxyLoss(-30)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/toxin2
	name = "\'AML\' nanite cell - TOXIN-II"
	type_color = "#00A000"
	type_name = "<span style='color:#00A000;font-weight:bold;'>TOXIN-II</span>"
	projectile_type = /obj/projectile/beam/medical_cell/toxin2

/obj/projectile/beam/medical_cell/toxin2/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustToxLoss(-20)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/haste
	name = "\'AML\' nanite cell - HASTE"
	type_color = "#FF3300"
	type_name = "<span style='color:#FF3300;font-weight:bold;'>HASTE</span>"
	projectile_type = /obj/projectile/beam/medical_cell/haste

/obj/projectile/beam/medical_cell/haste/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.add_modifier(/datum/modifier/medigunhaste, 20 SECONDS)
	else
		return 1

/datum/modifier/medigunhaste
	name = "haste"
	desc = "You can move much faster!"
	mob_overlay_state = "haste"
	stacks = MODIFIER_STACK_EXTEND
	slowdown = -0.5 //a little faster!
	evasion = 1.15 //and a little harder to hit!

/obj/item/ammo_casing/microbattery/medical/resist
	name = "\'AML\' nanite cell - RESIST"
	type_color = "#555555"
	type_name = "<span style='color:#555555;font-weight:bold;'>RESIST</span>"
	projectile_type = /obj/projectile/beam/medical_cell/resist

/obj/projectile/beam/medical_cell/resist/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.add_modifier(/datum/modifier/resistance, 20 SECONDS)
	else
		return 1

/datum/modifier/resistance
	name = "resistance"
	desc = "You resist 15% of all incoming damage and stuns!"
	mob_overlay_state = "repel_missiles"
	stacks = MODIFIER_STACK_EXTEND
	disable_duration_percent = 0.85
	incoming_damage_percent = 0.85

/obj/item/ammo_casing/microbattery/medical/corpse_mend
	name = "\'AML\' nanite cell - CORPSE MEND"
	type_color = "#669900"
	type_name = "<span style='color:#669900;font-weight:bold;'>CORPSE MEND</span>"
	projectile_type = /obj/projectile/beam/medical_cell/corpse_mend

/obj/projectile/beam/medical_cell/corpse_mend/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		if(target.stat == DEAD)
			target.adjustBruteLoss(-50)
			target.adjustFireLoss(-50)
			target.adjustToxLoss(-50)
			target.adjustOxyLoss(-200)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/brute3
	name = "\'AML\' nanite cell - BRUTE-III"
	type_color = "#BF0000"
	type_name = "<span style='color:#BF0000;font-weight:bold;'>BRUTE-III</span>"
	projectile_type = /obj/projectile/beam/medical_cell/brute3

/obj/projectile/beam/medical_cell/brute3/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustBruteLoss(-40)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/burn3
	name = "\'AML\' nanite cell - BURN-III"
	type_color = "#FF8000"
	type_name = "<span style='color:#FF8000;font-weight:bold;'>BURN-III</span>"
	projectile_type = /obj/projectile/beam/medical_cell/burn3

/obj/projectile/beam/medical_cell/burn3/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustFireLoss(-40)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/toxin3
	name = "\'AML\' nanite cell - TOXIN-III"
	type_color = "#00A000"
	type_name = "<span style='color:#00A000;font-weight:bold;'>TOXIN-III</span>"
	projectile_type = /obj/projectile/beam/medical_cell/toxin3

/obj/projectile/beam/medical_cell/toxin3/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustToxLoss(-40)
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/omni3
	name = "\'AML\' nanite cell - OMNI-III"
	type_color = "#8040FF"
	type_name = "<span style='color:#8040FF;font-weight:bold;'>OMNI-III</span>"
	projectile_type = /obj/projectile/beam/medical_cell/omni3

/obj/projectile/beam/medical_cell/omni3/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.adjustBruteLoss(-10)
		target.adjustFireLoss(-10)
		target.adjustToxLoss(-10)
		target.adjustOxyLoss(-60)
	else
		return 1

// Illegal cells!
/obj/item/ammo_casing/microbattery/medical/shrink
	name = "\'AML\' nanite cell - SHRINK"
	type_color = "#910ffc"
	type_name = "<span style='color:#910ffc;font-weight:bold;'>SHRINK</span>"
	projectile_type = /obj/projectile/beam/medical_cell/shrink

/obj/projectile/beam/medical_cell/shrink/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.resize(0.5)
		target.show_message("<font color=#4F49AF>The beam fires into your body, changing your size!</font>")
		target.updateicon()
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/grow
	name = "\'AML\' nanite cell - GROW"
	type_color = "#fc0fdc"
	type_name = "<span style='color:#fc0fdc;font-weight:bold;'>GROW</span>"
	projectile_type = /obj/projectile/beam/medical_cell/grow

/obj/projectile/beam/medical_cell/grow/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.resize(2.0)
		target.show_message("<font color=#4F49AF>The beam fires into your body, changing your size!</font>")
		target.updateicon()
	else
		return 1

/obj/item/ammo_casing/microbattery/medical/normalsize
	name = "\'AML\' nanite cell - NORMALSIZE"
	type_color = "#C70FEC"
	type_name = "<span style='color:#C70FEC;font-weight:bold;'>NORMALSIZE</span>"
	projectile_type = /obj/projectile/beam/medical_cell/normalsize

/obj/projectile/beam/medical_cell/normalsize/on_hit_legacy(var/mob/living/carbon/human/target)
	if(istype(target, /mob/living/carbon/human))
		target.resize(1)
		target.show_message("<font color=#4F49AF>The beam fires into your body, changing your size!</font>")
		target.updateicon()
	else
		return 1
