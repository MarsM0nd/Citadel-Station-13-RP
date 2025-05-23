GLOBAL_LIST_EMPTY(apcs)

/// EMP effect duration is divided by this number if the APC has "critical" flag
#define CRITICAL_APC_EMP_PROTECTION 10
//update_state
#define UPDATE_CELL_IN 1
#define UPDATE_OPENED1 2
#define UPDATE_OPENED2 4
#define UPDATE_MAINT 8
#define UPDATE_BROKE 16
#define UPDATE_BLUESCREEN 32
#define UPDATE_WIREEXP 64
#define UPDATE_ALLGOOD 128

//update_overlay
#define APC_UPOVERLAY_CHARGEING0 1
#define APC_UPOVERLAY_CHARGEING1 2
#define APC_UPOVERLAY_CHARGEING2 4
#define APC_UPOVERLAY_EQUIPMENT0 8
#define APC_UPOVERLAY_EQUIPMENT1 16
#define APC_UPOVERLAY_EQUIPMENT2 32
#define APC_UPOVERLAY_LIGHTING0 64
#define APC_UPOVERLAY_LIGHTING1 128
#define APC_UPOVERLAY_LIGHTING2 256
#define APC_UPOVERLAY_ENVIRON0 512
#define APC_UPOVERLAY_ENVIRON1 1024
#define APC_UPOVERLAY_ENVIRON2 2048
#define APC_UPOVERLAY_LOCKED 4096
#define APC_UPOVERLAY_OPERATING 8192


/// 10 seconds
#define APC_UPDATE_ICON_COOLDOWN 100
// the Area Power Controller (APC), formerly Power Distribution Unit (PDU)
// one per area, needs wire conection to power network through a terminal

// controls power to devices in that area
// may be opened to change power cell
// three different channels (lighting/equipment/environ) - may each be set to on, off, or auto
/// Power channel is off and will stay that way dammit
#define POWERCHAN_OFF      0
/// Power channel is off until power rises above a threshold
#define POWERCHAN_OFF_AUTO 1
/// Power channel is on until there is no power
#define POWERCHAN_ON       2
/// Power channel is on until power drops below a threshold
#define POWERCHAN_ON_AUTO  3
#define NIGHTSHIFT_AUTO 1
#define NIGHTSHIFT_NEVER 2
#define NIGHTSHIFT_ALWAYS 3

//NOTE: STUFF STOLEN FROM AIRLOCK.DM thx
//Critical//
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/critical, 22)
/obj/machinery/power/apc/critical
	is_critical = 1

/// High capacity cell APCs
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/high, 22)
/obj/machinery/power/apc/high
	cell_type = /obj/item/cell/high

/// Super capacity cell APCS
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/super, 22)
/obj/machinery/power/apc/super
	cell_type = /obj/item/cell/super

/// Critical APCs with super cells
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/super/critical, 22)
/obj/machinery/power/apc/super/critical
	is_critical = 1

/// APCS with hyper cells. How lewd
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/hyper, 22)
/obj/machinery/power/apc/hyper
	cell_type = /obj/item/cell/hyper

/// APCs with alarms hidden. Use these for POI's and offmap stuff so engineers dont get notified that shitty_ruins4 is running out of power -Bloop
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/alarms_hidden, 22)
/obj/machinery/power/apc/alarms_hidden
	alarms_hidden = TRUE

/// APCS with hidden alarms and no power cells
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc/alarms_hidden/no_cell, 22)
/obj/machinery/power/apc/alarms_hidden/no_cell
	cell_type = null
	chargelevel = 0

/**
 * APCs
 *
 * Power scale: Watts
 * Power is up-converted to kilowatts for grid.
 *
 * TODO: rewrite apcs entirely, the code barely works and it's all awful
 *
 * dev notes for the next time i'm insane enough to refactor power for no reason:
 * - dynamic power channels? probably not due to list overhead but maybe
 * - apc with 2-5kJ capacitor, letting us have actual accumulation + cell-less apc support
 * - config option for cell-less apc because i'm honestly evil
 * - unfuck icon update syste
 * - more wires, morre remote controls
 * - wiremod?
 * - WHY DOES IT HAVE SO MANY UNNECESSARY FLAGS JUST HAVE A SINGLE var/channels_enabled and var/channels_auto GOD
 * - configurable shutoff intervals??
 * - brownout support *drooling* (probably far in the future or impossible due to performance)
 *
 * ~silicons
 */
CREATE_WALL_MOUNTING_TYPES_SHIFTED(/obj/machinery/power/apc, 22)
/obj/machinery/power/apc
	name = "area power controller"
	desc = "A control terminal for the area electrical systems."
	icon = 'icons/obj/apc.dmi'
	icon_state = "apc0"
	plane = TURF_PLANE
	layer = ABOVE_TURF_LAYER
	anchored = 1
	use_power = USE_POWER_OFF
	req_access = list(ACCESS_ENGINEERING_ENGINE)
	armor_type = /datum/armor/object/medium
	var/area/area
	var/areastring = null
	var/obj/item/cell/cell
	var/chargelevel = 0.0005  // Cap for how fast APC cells charge, as a percentage-per-tick (0.01 means cellcharge is capped to 1% per second)
	var/start_charge = 90				// initial cell charge %
	var/cell_type = /obj/item/cell/apc
	var/opened = 0 //0=closed, 1=opened, 2=cover removed
	var/shorted = 0
	var/grid_check = FALSE
	var/lighting = POWERCHAN_ON_AUTO
	var/equipment = POWERCHAN_ON_AUTO
	var/environ = POWERCHAN_ON_AUTO
	var/operating = 1
	var/charging = 0
	var/chargemode = 1
	var/chargecount = 0
	var/locked = 1
	var/coverlocked = 1
	var/aidisabled = 0
	var/obj/machinery/power/terminal/terminal = null
	var/lastused_light = 0
	var/lastused_equip = 0
	var/lastused_environ = 0
	var/lastused_charging = 0
	var/lastused_total = 0
	var/main_status = 0
	var/mob/living/silicon/ai/hacker = null // Malfunction var. If set AI hacked the APC and has full control.
	var/wiresexposed = 0
	powernet = 0		// set so that APCs aren't found as powernet nodes //Hackish, Horrible, was like this before I changed it :(
	var/debug= 0
	var/autoflag= 0		// 0 = off, 1= eqp and lights off, 2 = eqp off, 3 = all on.
	var/has_electronics = 0 // 0 - none, 1 - plugged in, 2 - secured by screwdriver
	var/beenhit = 0 // used for counting how many times it has been hit, used for Aliens at the moment
	var/longtermpower = 10
	var/datum/wires/apc/wires = null
	var/emergency_lights = FALSE
	var/update_state = -1
	var/update_overlay = -1
	var/is_critical = 0
	var/global/status_overlays = 0
	var/failure_timer = 0
	var/force_update = 0
	var/updating_icon = 0
	var/global/list/status_overlays_lock
	var/global/list/status_overlays_charging
	var/global/list/status_overlays_equipment
	var/global/list/status_overlays_lighting
	var/global/list/status_overlays_environ
	var/alarms_hidden = FALSE //If power alarms from this APC are visible on consoles

	var/nightshift_lights = FALSE
	var/nightshift_setting = NIGHTSHIFT_AUTO
	var/last_nightshift_switch = 0

	/// tracks how behind we arre in charging TODO: literally rewrite apcs entirely to use a proper accumulator-cell system with an internal buffer, ffs
	var/lazy_draw_accumulator = 0

	//Used for shuttles, workaround for broken mounting
	//TODO: Remove when legacy walls are nuked
	var/old_wall = FALSE

/obj/machinery/power/apc/updateDialog()
	if (machine_stat & (BROKEN|MAINT))
		return
	..()

/obj/machinery/power/apc/connect_to_network()
	//Override because the APC does not directly connect to the network; it goes through a terminal.
	//The terminal is what the power computer looks for anyway.
	if(!terminal)
		make_terminal()
	if(terminal)
		terminal.connect_to_network()

/obj/machinery/power/apc/drain_energy(datum/actor, amount, flags)
	charging = FALSE
	// makes sure fully draining apc cell won't break cell charging

	var/drained = 0

	if(terminal?.powernet)
		terminal.powernet.trigger_warning()
		// no conversion - amount = kj, draw_power is in kw
		drained += terminal.powernet.draw_power(amount)

	//The grid rarely gives the full amount requested, or perhaps the grid
	//isn't connected (wire cut), in either case we draw what we didn't get
	//from the cell instead.
	if((drained < amount) && cell)
		drained += cell.drain_energy(actor, amount, flags)

	return drained

/obj/machinery/power/apc/Initialize(mapload, ndir, building = FALSE)
	. = ..()
	wires = new(src)
	GLOB.apcs += src

	// offset 24 pixels in direction of dir
	// this allows the APC to be embedded in a wall, yet still inside an area
	if (building)
		setDir(ndir)

	if(!building)
		autobuild()
	else
		area = get_area(src)
		area.apc = src
		opened = 1
		operating = 0
		name = "[area.name] APC"
		machine_stat |= MAINT
		src.update_icon()
	setDir(dir)

/obj/machinery/power/apc/Destroy()
	GLOB.apcs -= src
	src.update()
	area.apc = null
	area.power_light = 0
	area.power_equip = 0
	area.power_environ = 0
	area.power_change()
	qdel(wires)
	wires = null
	qdel(terminal)
	terminal = null
	if(cell)
		cell.forceMove(loc)
		cell = null

	// Malf AI, removes the APC from AI's hacked APCs list.
	if((hacker) && (hacker.hacked_apcs) && (src in hacker.hacked_apcs))
		hacker.hacked_apcs -= src

	return ..()

/obj/machinery/power/apc/get_cell(inducer)
	return cell

// APCs are pixel-shifted, so they need to be updated.
/obj/machinery/power/apc/setDir(new_dir)
	. = ..()

	if(old_wall)
		return

	base_pixel_x = 0
	base_pixel_y = 0
	var/turf/T = get_step(src, turn(dir, 180))
	if(T.get_wallmount_anchor())
		switch(dir)
			if(SOUTH)
				base_pixel_y = 22
			if(NORTH)
				base_pixel_y = -22
			if(EAST)
				base_pixel_x = -22
			if(WEST)
				base_pixel_x = 22
	reset_pixel_offsets()

	if(terminal)
		terminal.disconnect_from_network()
		terminal.setDir(turn(src.dir, 180)) // Terminal has same dir as master
		terminal.connect_to_network() // Refresh the network the terminal is connected to.

/obj/machinery/power/apc/proc/energy_fail(var/duration)
	failure_timer = max(failure_timer, round(duration))

/obj/machinery/power/apc/proc/make_terminal()
	// create a terminal object at the same position as original turf loc
	// wires will attach to this
	terminal = new/obj/machinery/power/terminal(src.loc)
	terminal.setDir(turn(dir, 180))
	terminal.master = src

/obj/machinery/power/apc/proc/autobuild()
	has_electronics = 2 //installed and secured
	// is starting with a power cell installed, create it and set its charge level
	if(cell_type)
		src.cell = new cell_type(src)
		cell.charge = start_charge * cell.maxcharge / 100.0 		// (convert percentage to actual value)

	var/area/A = src.loc.loc

	//if area isn't specified use current
	if(isarea(A) && src.areastring == null)
		src.area = A
		name = "\improper [area.name] APC"
	else
		src.area = get_area_name(areastring)
		name = "\improper [area.name] APC"
	area.apc = src

	if(istype(area, /area/submap))
		alarms_hidden = TRUE

	update_icon()

	make_terminal()

/obj/machinery/power/apc/examine(mob/user, dist)
	. = ..()
	if(Adjacent(user))
		if(machine_stat & BROKEN)
			. += "This APC is broken."
			return
		if(opened)
			if(has_electronics && terminal)
				. += "The cover is [opened==2?"removed":"open"] and [ cell ? "a power cell is installed" : "the power cell is missing"]."
			else if (!has_electronics && terminal)
				. += "The frame is wired, but the electronics are missing."
			else if (has_electronics && !terminal)
				. += "The electronics are installed, but not wired."
			else
				. += "It's just an empty metal frame."

		else
			if (wiresexposed)
				. += "The cover is closed and the wires are exposed."
			else if ((locked && emagged) || hacker) //Some things can cause locked && emagged. Malf AI causes hacker.
				. += "The cover is closed, but the panel is unresponsive."
			else if(!locked && emagged) //Normal emag does this.
				. += "The cover is closed, but the panel is flashing an error."
			else
				. += "The cover is closed."

// update the APC icon to show the three base states
// also add overlays for indicator lights
/obj/machinery/power/apc/update_icon()
	if (!status_overlays)
		status_overlays = 1
		status_overlays_lock = new
		status_overlays_charging = new
		status_overlays_equipment = new
		status_overlays_lighting = new
		status_overlays_environ = new

		status_overlays_lock.len = 2
		status_overlays_charging.len = 3
		status_overlays_equipment.len = 5
		status_overlays_lighting.len = 5
		status_overlays_environ.len = 5

		status_overlays_lock[1] = image(icon, "apcox-0")    // 0=blue 1=red
		status_overlays_lock[2] = image(icon, "apcox-1")

		status_overlays_charging[1] = image(icon, "apco3-0")
		status_overlays_charging[2] = image(icon, "apco3-1")
		status_overlays_charging[3] = image(icon, "apco3-2")

		var/list/channel_overlays = list(status_overlays_equipment, status_overlays_lighting, status_overlays_environ)
		var/channel = 0
		for(var/list/channel_leds in channel_overlays)
			channel_leds[POWERCHAN_OFF + 1] = overlay_image(icon,"apco[channel]",COLOR_RED)
			channel_leds[POWERCHAN_OFF_AUTO + 1] = overlay_image(icon,"apco[channel]",COLOR_ORANGE)
			channel_leds[POWERCHAN_ON + 1] = overlay_image(icon,"apco[channel]",COLOR_LIME)
			channel_leds[POWERCHAN_ON_AUTO + 1] = overlay_image(icon,"apco[channel]",COLOR_BLUE)
			channel++

	var/update = check_updates() 		//returns 0 if no need to update icons.
						// 1 if we need to update the icon_state
						// 2 if we need to update the overlays

	if(!update)
		return

	if(update & 1) // Updating the icon state
		if(update_state & UPDATE_ALLGOOD)
			icon_state = "apc0"
		else if(update_state & (UPDATE_OPENED1|UPDATE_OPENED2))
			var/basestate = "apc[ get_cell(FALSE) ? "2" : "1" ]"
			if(update_state & UPDATE_OPENED1)
				if(update_state & (UPDATE_MAINT|UPDATE_BROKE))
					icon_state = "apcmaint" //disabled APC cannot hold cell
				else
					icon_state = basestate
			else if(update_state & UPDATE_OPENED2)
				icon_state = "[basestate]-nocover"
		else if(update_state & UPDATE_BROKE)
			icon_state = "apc-b"
		else if(update_state & UPDATE_BLUESCREEN)
			icon_state = "apcemag"
		else if(update_state & UPDATE_WIREEXP)
			icon_state = "apcewires"

	if(!(update_state & UPDATE_ALLGOOD))
		cut_overlays()

	if(update & 2)
		cut_overlays()
		if(!(machine_stat & (BROKEN|MAINT)) && update_state & UPDATE_ALLGOOD)
			add_overlay(status_overlays_lock[locked+1])
			add_overlay(status_overlays_charging[charging+1])
			if(operating)
				add_overlay(status_overlays_equipment[equipment+1])
				add_overlay(status_overlays_lighting[lighting+1])
				add_overlay(status_overlays_environ[environ+1])

	if(update & 3)
		if((update_state & (UPDATE_OPENED1|UPDATE_OPENED2|UPDATE_BROKE)))
			set_light(0)
		else if(update_state & UPDATE_BLUESCREEN)
			set_light(l_range = 2, l_power = 0.5, l_color = "#00ecff")
		else if(!(machine_stat & (BROKEN|MAINT)) && update_state & UPDATE_ALLGOOD)
			var/color
			switch(charging)
				if(0)
					color = "#f86060"
				if(1)
					color = "#a8b0f8"
				if(2)
					color = "#82ff4c"
			set_light(l_range = 2, l_power = 0.5, l_color = color)
		else
			set_light(0)

/obj/machinery/power/apc/proc/check_updates()

	var/last_update_state = update_state
	var/last_update_overlay = update_overlay
	update_state = 0
	update_overlay = 0

	if(cell)
		update_state |= UPDATE_CELL_IN
	if(machine_stat & BROKEN)
		update_state |= UPDATE_BROKE
	if(machine_stat & MAINT)
		update_state |= UPDATE_MAINT
	if(opened)
		if(opened==1)
			update_state |= UPDATE_OPENED1
		if(opened==2)
			update_state |= UPDATE_OPENED2
	else if(wiresexposed)
		update_state |= UPDATE_WIREEXP
	else if(emagged || hacker || failure_timer)
		update_state |= UPDATE_BLUESCREEN
	if(update_state <= 1)
		update_state |= UPDATE_ALLGOOD

	if(operating)
		update_overlay |= APC_UPOVERLAY_OPERATING

	if(update_state & UPDATE_ALLGOOD)
		if(locked)
			update_overlay |= APC_UPOVERLAY_LOCKED

		if(!charging)
			update_overlay |= APC_UPOVERLAY_CHARGEING0
		else if(charging == 1)
			update_overlay |= APC_UPOVERLAY_CHARGEING1
		else if(charging == 2)
			update_overlay |= APC_UPOVERLAY_CHARGEING2

		if (!equipment)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT0
		else if(equipment == 1)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT1
		else if(equipment == 2)
			update_overlay |= APC_UPOVERLAY_EQUIPMENT2

		if(!lighting)
			update_overlay |= APC_UPOVERLAY_LIGHTING0
		else if(lighting == 1)
			update_overlay |= APC_UPOVERLAY_LIGHTING1
		else if(lighting == 2)
			update_overlay |= APC_UPOVERLAY_LIGHTING2

		if(!environ)
			update_overlay |= APC_UPOVERLAY_ENVIRON0
		else if(environ==1)
			update_overlay |= APC_UPOVERLAY_ENVIRON1
		else if(environ==2)
			update_overlay |= APC_UPOVERLAY_ENVIRON2


	var/results = 0
	if(last_update_state == update_state && last_update_overlay == update_overlay)
		return 0
	if(last_update_state != update_state)
		results += 1
	if(last_update_overlay != update_overlay)
		results += 2
	return results

// Used in process so it doesn't update the icon too much
/obj/machinery/power/apc/proc/queue_icon_update()

	if(!updating_icon)
		updating_icon = 1
		// Start the update
		spawn(APC_UPDATE_ICON_COOLDOWN)
			update_icon()
			updating_icon = 0

//attack with an item - open/close cover, insert cell, or (un)lock interface

/obj/machinery/power/apc/attackby(obj/item/W, mob/user)
	if(user.a_intent == INTENT_HARM)
		return ..()

	if (istype(user, /mob/living/silicon) && get_dist(src,user)>1)
		return src.attack_hand(user)
	src.add_fingerprint(user)
	if (W.is_crowbar() && opened)
		if (has_electronics==1)
			if (terminal)
				to_chat(user,"<span class='warning'>Disconnect the wires first.</span>")
				return
			playsound(src, W.tool_sound, 50, 1)
			to_chat(user,"You begin to remove the power control board...") //lpeters - fixed grammar issues //Ner - grrrrrr
			if(do_after(user, 50 * W.tool_speed))
				if (has_electronics==1)
					has_electronics = 0
					if ((machine_stat & BROKEN))
						user.visible_message(\
							"<span class='warning'>[user.name] has broken the charred power control board inside [src.name]!</span>",\
							"<span class='notice'>You broke the charred power control board and remove the remains.</span>",
							"You hear a crack!")
						//SSticker.mode:apcs-- //XSI said no and I agreed. -rastaf0
					else
						user.visible_message(\
							"<span class='warning'>[user.name] has removed the power control board from [src.name]!</span>",\
							"<span class='notice'>You remove the power control board.</span>")
						new /obj/item/module/power_control(loc)
		else if (opened!=2) //cover isn't removed
			opened = 0
			update_icon()
	else if (W.is_crowbar() && !(machine_stat & BROKEN) )
		if(coverlocked && !(machine_stat & MAINT))
			to_chat(user,"<span class='warning'>The cover is locked and cannot be opened.</span>")
			return
		else
			opened = 1
			update_icon()
	else if	(istype(W, /obj/item/cell) && opened)	// trying to put a cell inside
		if(cell)
			to_chat(user,"The [src.name] already has a power cell installed.")
			return
		if (machine_stat & MAINT)
			to_chat(user,"<span class='warning'>You need to install the wiring and electronics first.</span>")
			return
		if(W.w_class != WEIGHT_CLASS_NORMAL)
			to_chat(user,"\The [W] is too [W.w_class < 3? "small" : "large"] to work here.")
			return
		if(!user.attempt_insert_item_for_installation(W, src))
			return
		cell = W
		user.visible_message(\
			"<span class='warning'>[user.name] has inserted a power cell into [src.name]!</span>",\
			"<span class='notice'>You insert the power cell.</span>")
		chargecount = 0
		update_icon()
	else if	(W.is_screwdriver())	// haxing
		if(opened)
			if (cell)
				to_chat(user,"<span class='warning'>Remove the power cell first.</span>")
				return
			else
				if (has_electronics==1 && terminal)
					has_electronics = 2
					machine_stat &= ~MAINT
					playsound(src.loc, W.tool_sound, 50, 1)
					to_chat(user,"You screw the circuit electronics into place.")
				else if (has_electronics==2)
					has_electronics = 1
					machine_stat |= MAINT
					playsound(src.loc, W.tool_sound, 50, 1)
					to_chat(user,"You unfasten the electronics.")
				else /* has_electronics==0 */
					to_chat(user,"<span class='warning'>There is nothing to secure.</span>")
					return
				update_icon()
		else
			wiresexposed = !wiresexposed
			to_chat(user,"The wires have been [wiresexposed ? "exposed" : "unexposed"].")
			playsound(src, W.tool_sound, 50, 1)
			update_icon()

	else if (istype(W, /obj/item/card/id)||istype(W, /obj/item/pda))			// trying to unlock the interface with an ID card
		if(emagged)
			to_chat(user,"The panel is unresponsive.")
		else if(opened)
			to_chat(user,"You must close the cover to swipe an ID card.")
		else if(wiresexposed)
			to_chat(user,"You must close the wire panel.")
		else if(machine_stat & (BROKEN|MAINT))
			to_chat(user,"Nothing happens.")
		else if(hacker)
			to_chat(user,"<span class='warning'>Access denied.</span>")
		else
			if(src.allowed(usr) && !wires.is_cut(WIRE_IDSCAN))
				locked = !locked
				to_chat(user,"You [ locked ? "lock" : "unlock"] the APC interface.")
				update_icon()
			else
				to_chat(user,"<span class='warning'>Access denied.</span>")
	else if (istype(W, /obj/item/stack/cable_coil) && !terminal && opened && has_electronics!=2)
		var/turf/T = loc
		if(istype(T) && !T.is_plating())
			to_chat(user,"<span class='warning'>You must remove the floor plating in front of the APC first.</span>")
			return
		var/obj/item/stack/cable_coil/C = W
		if(C.get_amount() < 10)
			to_chat(user,"<span class='warning'>You need ten lengths of cable for that.</span>")
			return
		user.visible_message("<span class='warning'>[user.name] adds cables to the APC frame.</span>", \
							"You start adding cables to the APC frame...")
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 20))
			if (C.amount >= 10 && !terminal && opened && has_electronics != 2)
				var/obj/structure/cable/N = T.get_cable_node()
				if (prob(50) && electrocute_mob(usr, N, N))
					var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
					s.set_up(5, 1, src)
					s.start()
					if(!CHECK_MOBILITY(user, MOBILITY_CAN_MOVE))
						return
				C.use(10)
				user.visible_message(\
					"<span class='warning'>[user.name] has added cables to the APC frame!</span>",\
					"You add cables to the APC frame.")
				make_terminal()
				terminal.connect_to_network()
	else if (W.is_wirecutter() && terminal && opened && has_electronics!=2)
		var/turf/T = loc
		if(istype(T) && !T.is_plating())
			to_chat(user,"<span class='warning'>You must remove the floor plating in front of the APC first.</span>")
			return
		user.visible_message("<span class='warning'>[user.name] starts dismantling the [src]'s power terminal.</span>", \
							"You begin to cut the cables...")
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 50 * W.tool_speed))
			if(terminal && opened && has_electronics!=2)
				if (prob(50) && electrocute_mob(usr, terminal.powernet, terminal))
					var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
					s.set_up(5, 1, src)
					s.start()
					if(!CHECK_MOBILITY(user, MOBILITY_CAN_MOVE))
						return
				new /obj/item/stack/cable_coil(loc,10)
				to_chat(user,"<span class='notice'>You cut the cables and dismantle the power terminal.</span>")
				qdel(terminal)
	else if (istype(W, /obj/item/module/power_control) && opened && has_electronics==0 && !((machine_stat & BROKEN)))
		user.visible_message("<span class='warning'>[user.name] inserts the power control board into [src].</span>", \
							"You start to insert the power control board into the frame...")
		playsound(src.loc, 'sound/items/Deconstruct.ogg', 50, 1)
		if(do_after(user, 10))
			if(has_electronics==0)
				has_electronics = 1
				reboot()
				to_chat(user,"<span class='notice'>You place the power control board inside the frame.</span>")
				qdel(W)
	else if (istype(W, /obj/item/module/power_control) && opened && has_electronics==0 && ((machine_stat & BROKEN)))
		to_chat(user,"<span class='warning'>The [src] is too broken for that. Repair it first.</span>")
		return
	else if (istype(W, /obj/item/weldingtool) && opened && has_electronics==0 && !terminal)
		var/obj/item/weldingtool/WT = W
		if (WT.get_fuel() < 3)
			to_chat(user,"<span class='warning'>You need more welding fuel to complete this task.</span>")
			return
		user.visible_message("<span class='warning'>[user.name] begins cutting apart [src] with the [WT.name].</span>", \
							"You start welding the APC frame...", \
							"You hear welding.")
		playsound(src, WT.tool_sound, 25, 1)
		if(do_after(user, 50 * WT.tool_speed))
			if(!src || !WT.remove_fuel(3, user)) return
			if (emagged || (machine_stat & BROKEN) || opened==2)
				new /obj/item/stack/material/steel(loc)
				user.visible_message(\
					"<span class='warning'>[src] has been cut apart by [user.name] with the [WT.name].</span>",\
					"<span class='notice'>You disassembled the broken APC frame.</span>",\
					"You hear welding.")
			else
				new /obj/item/frame2/apc(loc)
				user.visible_message(\
					"<span class='warning'>[src] has been cut from the wall by [user.name] with the [WT.name].</span>",\
					"<span class='notice'>You cut the APC frame from the wall.</span>",\
					"You hear welding.")
			qdel(src)
			return
	else if (opened && ((machine_stat & BROKEN) || hacker || emagged))
		if (istype(W, /obj/item/frame2/apc) && (machine_stat & BROKEN))
			if(cell)
				to_chat(user, "<span class='warning'>You need to remove the power cell first.</span>")
				return
			user.visible_message("<span class='warning'>[user.name] begins replacing the damaged APC cover with a new one.</span>",\
								"You begin to replace the damaged APC cover...")
			if(do_after(user, 50))
				user.visible_message("<span class='notice'>[user.name] has replaced the damaged APC cover with a new one.</span>",\
					"You replace the damaged APC cover with a new one.")
				qdel(W)
				machine_stat &= ~BROKEN
				reboot()
				if (opened==2)
					opened = 1
				update_icon()
		else if (istype(W, /obj/item/multitool) && (hacker || emagged))
			if(cell)
				to_chat(user, "<span class='warning'>You need to remove the power cell first.</span>")
				return
			user.visible_message("<span class='warning'>[user.name] connects their [W.name] to the APC and begins resetting it.</span>",\
								"You begin resetting the APC...")
			if(do_after(user, 50))
				user.visible_message("<span class='notice'>[user.name] resets the APC with a beep from their [W.name].</span>",\
									"You finish resetting the APC.")
				playsound(src.loc, 'sound/machines/chime.ogg', 25, 1)
				reboot()
	else
		if ((machine_stat & BROKEN) \
				&& !opened \
				&& W.damage_force >= 5 \
				&& W.w_class >= WEIGHT_CLASS_SMALL )
			user.visible_message("<span class='danger'>The [src.name] has been hit with the [W.name] by [user.name]!</span>", \
				"<span class='danger'>You hit the [src.name] with your [W.name]!</span>", \
				"You hear a bang!")
			if(prob(20))
				opened = 2
				user.visible_message("<span class='danger'>The APC cover was knocked down with the [W.name] by [user.name]!</span>", \
					"<span class='danger'>You knock down the APC cover with your [W.name]!</span>", \
					"You hear a bang!")
				update_icon()
		else
			if (istype(user, /mob/living/silicon))
				return src.attack_hand(user)
			if (!opened && wiresexposed && (istype(W, /obj/item/multitool) || W.is_wirecutter() || istype(W, /obj/item/assembly/signaler)))
				return src.attack_hand(user)

// attack with hand - remove cell (if cover open) or interact with the APC

//Altclick APCs to toggle the controlls
/obj/machinery/power/apc/AltClick(mob/user)
	if(user.Adjacent(src))
		if(src.allowed(usr) && !wires.is_cut(WIRE_IDSCAN))
			locked = !locked
			to_chat(user,"You [ locked ? "lock" : "unlock"] the APC interface.")
			update_icon()
		else
			to_chat(user,"<span class='warning'>Access denied.</span>")

/obj/machinery/power/apc/emag_act(var/remaining_charges, var/mob/user)
	if (!(emagged || hacker))		// trying to unlock with an emag card
		if(opened)
			to_chat(user,"You must close the cover to do that.")
		else if(wiresexposed)
			to_chat(user,"You must close the wire panel first.")
		else if(machine_stat & (BROKEN|MAINT))
			to_chat(user,"The [src] isn't working.")
		else
			flick("apc-spark", src)
			if (do_after(user,6))
				emagged = 1
				locked = 0
				to_chat(user,"<span class='notice'>You emag the APC interface.</span>")
				update_icon()
				return 1

/obj/machinery/power/apc/blob_act()
	if(!wires.is_all_cut())
		wiresexposed = TRUE
		wires.cut_all()
		update_icon()

/obj/machinery/power/apc/attack_hand(mob/user, datum/event_args/actor/clickchain/e_args)
//	if (!can_use(user)) This already gets called in interact() and in topic()
//		return
	if(!user)
		return
	src.add_fingerprint(user)

	//Human mob special interaction goes here.
	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user

		if(H.species.can_shred(H))
			user.setClickCooldownLegacy(user.get_attack_speed_legacy())
			user.visible_message("<span call='warning'>[user.name] slashes at the [src.name]!</span>", "<span class='notice'>You slash at the [src.name]!</span>")
			playsound(src.loc, 'sound/weapons/slash.ogg', 100, 1)

			var/allcut = wires.is_all_cut()

			if(beenhit >= pick(3, 4) && wiresexposed != 1)
				wiresexposed = 1
				src.update_icon()
				src.visible_message("<span call='warning'>The [src.name]'s cover flies open, exposing the wires!</span>")

			else if(wiresexposed == 1 && allcut == 0)
				wires.cut_all()
				src.update_icon()
				src.visible_message("<span call='warning'>The [src.name]'s wires are shredded!</span>")
			else
				beenhit += 1
			return

	if(usr == user && opened && (!issilicon(user)))
		if(cell)
			user.put_in_hands(cell)
			cell.add_fingerprint(user)
			cell.update_icon()

			src.cell = null
			user.visible_message("<span class='warning'>[user.name] removes the power cell from [src.name]!</span>",\
								 "<span class='notice'>You remove the power cell.</span>")
			charging = 0
			src.update_icon()
		return
	if(machine_stat & (BROKEN|MAINT))
		return
	// do APC interaction
	src.interact(user)

/obj/machinery/power/apc/attack_ai(mob/user)
	add_hiddenprint(user)
	ui_interact(user)

/obj/machinery/power/apc/interact(mob/user)
	if(!user)
		return

	if(wiresexposed && !istype(user, /mob/living/silicon/ai))
		wires.Interact(user)
		return	//The panel is visibly dark when the wires are exposed, so we shouldn't be able to interact with it.

	return ui_interact(user)

/obj/machinery/power/apc/ui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "APC", name) // 510, 460
		ui.open()

/obj/machinery/power/apc/ui_data(mob/user, datum/tgui/ui)
	var/list/data = list(
		"locked" = locked,
		"normallyLocked" = locked,
		"emagged" = emagged,
		"isOperating" = operating,
		"externalPower" = main_status,
		"powerCellStatus" = cell ? cell.percent() : null,
		"chargeMode" = chargemode,
		"chargingStatus" = charging,
		"totalLoad" = round(lastused_total),
		"totalCharging" = round(lastused_charging),
		"failTime" = failure_timer * 2,
		"gridCheck" = grid_check,
		"coverLocked" = coverlocked,
		"siliconUser" = issilicon(user) || (isobserver(user) && is_admin(user)), //I add observer here so admins can have more control, even if it makes 'siliconUser' seem inaccurate.
		"emergencyLights" = !emergency_lights,
		"nightshiftLights" = nightshift_lights,
		"nightshiftSetting" = nightshift_setting,

		"powerChannels" = list(
			list(
				"title" = "Equipment",
				"powerLoad" = lastused_equip,
				"status" = equipment,
				"topicParams" = list(
					"auto" = list("eqp" = 3),
					"on"   = list("eqp" = 2),
					"off"  = list("eqp" = 1)
				)
			),
			list(
				"title" = "Lighting",
				"powerLoad" = round(lastused_light),
				"status" = lighting,
				"topicParams" = list(
					"auto" = list("lgt" = 3),
					"on"   = list("lgt" = 2),
					"off"  = list("lgt" = 1)
				)
			),
			list(
				"title" = "Environment",
				"powerLoad" = round(lastused_environ),
				"status" = environ,
				"topicParams" = list(
					"auto" = list("env" = 3),
					"on"   = list("env" = 2),
					"off"  = list("env" = 1)
				)
			)
		)
	)

	return data

/obj/machinery/power/apc/ui_act(action, list/params, datum/tgui/ui)
	if(..() || !can_use(usr, TRUE))
		return TRUE

	// There's a handful of cases where we want to allow users to bypass the `locked` variable.
	// If can_admin_interact() wasn't only defined on observers, this could just be part of a single-line
	// conditional.
	var/locked_exception = FALSE
	if(issilicon(usr) || action == "nightshift")
		locked_exception = TRUE
	if(isobserver(usr))
		var/mob/observer/dead/D = usr
		if(D.can_admin_interact())
			locked_exception = TRUE

	if(locked && !locked_exception)
		return

	. = TRUE
	switch(action)
		if("lock")
			if(locked_exception) // Yay code reuse
				if(emagged || (machine_stat & (BROKEN|MAINT)))
					to_chat(usr, "The APC does not respond to the command.")
					return
				locked = !locked
				update_icon()
		if("cover")
			coverlocked = !coverlocked
		if("breaker")
			toggle_breaker()
		if("nightshift")
			if(last_nightshift_switch > world.time - 10 SECONDS) // don't spam...
				to_chat(usr, "<span class='warning'>[src]'s night lighting circuit breaker is still cycling!</span>")
				return 0
			last_nightshift_switch = world.time
			nightshift_setting = params["nightshift"]
			update_nightshift()
		if("charge")
			chargemode = !chargemode
			if(!chargemode)
				charging = 0
				update_icon()
		if("channel")
			if(params["eqp"])
				equipment = setsubsystem(text2num(params["eqp"]))
				update_icon()
				update()
			else if(params["lgt"])
				lighting = setsubsystem(text2num(params["lgt"]))
				update_icon()
				update()
			else if(params["env"])
				environ = setsubsystem(text2num(params["env"]))
				update_icon()
				update()
		if("reboot")
			failure_timer = 0
			update_icon()
			update()
		if("emergency_lighting")
			emergency_lights = !emergency_lights
			for(var/obj/machinery/light/L in area)
				if(!initial(L.no_emergency)) //If there was an override set on creation, keep that override
					L.no_emergency = emergency_lights
					INVOKE_ASYNC(L, TYPE_PROC_REF(/obj/machinery/light, update), FALSE)
				CHECK_TICK
		if("overload")
			if(locked_exception) // Reusing for simplicity!
				overload_lighting()

/obj/machinery/power/apc/proc/report()
	return "[area.name] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"

/obj/machinery/power/apc/proc/update()
	if(operating && !shorted && !grid_check && !failure_timer)
		area.power_light = (lighting >= POWERCHAN_ON)
		area.power_equip = (equipment >= POWERCHAN_ON)
		area.power_environ = (environ >= POWERCHAN_ON)
//		if (area.name == "AI Chamber")
//			spawn(10)
//				to_chat(world, " [area.name] [area.power_equip]")
	else
		area.power_light = 0
		area.power_equip = 0
		area.power_environ = 0
//		if (area.name == "AI Chamber")
//			to_chat(world, "[area.power_equip]")
	area.power_change()

/obj/machinery/power/apc/proc/can_use(mob/user as mob, var/loud = 0) //used by attack_hand() and Topic()
	if(!user.client)
		return 0
	if(IsAdminGhost(user)) //This is to allow nanoUI interaction by ghost admins.
		return TRUE
	if(user.stat)
		return 0
	if(inoperable())
		return 0
	if(!user.IsAdvancedToolUser())
		return 0
	if(user.restrained())
		to_chat(user,"<span class='warning'>Your hands must be free to use [src].</span>")
		return 0
	if(user.lying)
		to_chat(user,"<span class='warning'>You must stand to use [src]!</span>")
		return 0
	autoflag = 5
	if(istype(user, /mob/living/silicon))
		var/permit = 0 // Malfunction variable. If AI hacks APC it can control it even without AI control wire.
		var/mob/living/silicon/ai/AI = user
		var/mob/living/silicon/robot/robot = user
		if(hacker)
			if(hacker == AI)
				permit = 1
			else if(istype(robot) && robot.connected_ai && robot.connected_ai == hacker) // Cyborgs can use APCs hacked by their AI
				permit = 1

		if(aidisabled && !permit)
			if(!loud)
				to_chat(user, "<span class='danger'>\The AI control for [src] has been disabled!</span>")
			return 0
	else
		if(!in_range(src, user) || !istype(loc, /turf))
			return 0
	var/mob/living/carbon/human/H = user
	if(istype(H) && prob(H.getBrainLoss()))
		to_chat(user, "<span class='danger'>You momentarily forget how to use [src].</span>")
		return 0
	return 1

/obj/machinery/power/apc/proc/toggle_breaker()
	operating = !operating
	src.update()
	update_icon()

//This isn't used for now, so might as well disable it
/*
/obj/machinery/power/apc/proc/ion_act()
	if(prob(3))
		src.locked = 1
		if (src.cell.charge > 0)
			src.cell.charge = 0
			cell.corrupt()
			update_icon()
			var/datum/effect_system/smoke_spread/smoke = new /datum/effect_system/smoke_spread()
			smoke.set_up(3, 0, src.loc)
			smoke.attach(src)
			smoke.start()
			var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
			s.set_up(3, 1, src)
			s.start()
			visible_message("<span class='danger'>The [src.name] suddenly lets out a blast of smoke and some sparks!</span>", \
							"<span class='danger'>You hear sizzling electronics.</span>")
*/

/obj/machinery/power/apc/surplus()
	if(terminal)
		return terminal.surplus()
	else
		return 0

//Returns 1 if the APC should attempt to charge
/obj/machinery/power/apc/proc/attempt_charging()
	return (chargemode && charging == 1 && operating)

/obj/machinery/power/apc/draw_power(var/amount)
	if(terminal && terminal.powernet)
		return terminal.powernet.draw_power(amount)
	return 0

/obj/machinery/power/apc/avail()
	if(terminal)
		return terminal.avail()
	else
		return 0

/obj/machinery/power/apc/process(delta_time)

	if(machine_stat & (BROKEN|MAINT))
		return
	if(!area.requires_power)
		return
	if(failure_timer)
		update()
		queue_icon_update()
		failure_timer--
		force_update = 1
		return

	lastused_light = area.usage(LIGHT)
	lastused_equip = area.usage(EQUIP)
	lastused_environ = area.usage(ENVIRON)
	area.clear_usage()

	lastused_total = lastused_light + lastused_equip + lastused_environ

	//store states to update icon if any change
	var/last_lt = lighting
	var/last_eq = equipment
	var/last_en = environ
	var/last_ch = charging

	var/excess = surplus()

	if(!src.avail())
		main_status = 0
	else if(excess < 0)
		main_status = 1
	else
		main_status = 2

	if(debug)
		log_debug(SPAN_DEBUGINFO("Status: [main_status] - Excess: [excess] - Last Equip: [lastused_equip] - Last Light: [lastused_light] - Longterm: [longtermpower]"))

	if(cell && !shorted && !grid_check)
		// draw power from cell as before to power the area
		var/cellused = min(cell.charge, DYNAMIC_W_TO_CELL_UNITS(lastused_total, 1))	// clamp deduction to a max, amount left in cell
		cell.use(cellused)
		// TODO: the rest of this code is war crime territory
		// TODO: rewrite APCs. entirely.
		// if we're empty just kill it all
		if(cell.percent() < 1)
			// This turns everything off in the case that there is still a charge left on the battery, just not enough to run the room.
			equipment = autoset(equipment, 0)
			lighting = autoset(lighting, 0)
			environ = autoset(environ, 0)
			autoflag = 0

		// we're lazy and i'm not writing a real accumulator, and we need to recharge in units of 1 due to floating point bullshit
		// hence..
		// we recharge at most lastused kw rounded down
		var/kw = round(lastused_total * 0.001)
		lazy_draw_accumulator += lastused_total - kw * 1000
		if(lazy_draw_accumulator > 1000)
			kw += round(lazy_draw_accumulator * 0.001)
			lazy_draw_accumulator = lazy_draw_accumulator % 1000
		if(excess > kw)
			var/draw = draw_power(kw)
			cell.give(DYNAMIC_KW_TO_CELL_UNITS(draw, 1))

		// Set channels depending on how much charge we have left
		update_channels()

		// now trickle-charge the cell
		lastused_charging = 0 // Clear the variable for new use.
		if(src.attempt_charging())
			if(excess > 0)		// check to make sure we have enough to charge
				// Max charge is capped to % per second constant
				var/ch = min(DYNAMIC_KW_TO_CELL_UNITS(excess, 1), cell.maxcharge * chargelevel, cell.maxcharge - cell.charge)
				var/charged = draw_power(DYNAMIC_CELL_UNITS_TO_KW(ch, 1)) // Removes the power we're taking from the grid
				cell.give(DYNAMIC_KW_TO_CELL_UNITS(charged, 1)) // actually recharge the cell
				lastused_charging = charged * 1000
				lastused_total += lastused_charging // Sensors need this to stop reporting APC charging as "Other" load
			else
				charging = 0		// stop charging
				chargecount = 0

		// show cell as fully charged if so
		if(cell.percent() >= 99)	// TODO: apc refactor - this is the only way for now, otherrwise we'll never stop charging as we don't ever charge to full entirely
			charging = 2
		else if(charging == 2)		// if charging is supposedly fully charged but we're not actually fully charged, shunt back to charging
			charging = 1

		if(chargemode)
			if(!charging)
				var/charge_tick = cell.maxcharge * chargelevel
				charge_tick = DYNAMIC_CELL_UNITS_TO_KW(charge_tick, 1)
				if(excess > charge_tick)
					chargecount++
				else
					chargecount = 0

				if(chargecount >= 5)

					chargecount = 0
					charging = 1

		else // chargemode off
			charging = 0
			chargecount = 0

	else // no cell, switch everything off
		charging = 0
		chargecount = 0
		equipment = autoset(equipment, 0)
		lighting = autoset(lighting, 0)
		environ = autoset(environ, 0)
		power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
		autoflag = 0

	// update icon & area power if anything changed
	if(last_lt != lighting || last_eq != equipment || last_en != environ || force_update)
		force_update = 0
		queue_icon_update()
		update()
	else if (last_ch != charging)
		queue_icon_update()

/obj/machinery/power/apc/proc/update_channels()
	// Allow the APC to operate as normal if the cell can charge
	if(charging && longtermpower < 10)
		longtermpower += 1
	else if(longtermpower > -10)
		longtermpower -= 2

	if((cell.percent() > 30) || longtermpower > 0)              // Put most likely at the top so we don't check it last, effeciency 101
		if(autoflag != 3)
			equipment = autoset(equipment, 1)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			autoflag = 3
			power_alarm.clearAlarm(loc, src)
	else if((cell.percent() <= 30) && (cell.percent() > 15) && longtermpower < 0)                       // <30%, turn off equipment
		if(autoflag != 2)
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 1)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
			autoflag = 2
	else if(cell.percent() <= 15)        // <15%, turn off lighting & equipment
		if((autoflag > 1 && longtermpower < 0) || (autoflag > 1 && longtermpower >= 0))
			equipment = autoset(equipment, 2)
			lighting = autoset(lighting, 2)
			environ = autoset(environ, 1)
			power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
			autoflag = 1
	else                                   // zero charge, turn all off
		if(autoflag != 0)
			equipment = autoset(equipment, 0)
			lighting = autoset(lighting, 0)
			environ = autoset(environ, 0)
			power_alarm.triggerAlarm(loc, src, hidden=alarms_hidden)
			autoflag = 0

// val 0=off, 1=off(auto) 2=on 3=on(auto)
// on 0=off, 1=on, 2=autooff
// defines a state machine, returns the new state
/obj/machinery/power/apc/proc/autoset(cur_state, on)
	switch(cur_state)
		if(POWERCHAN_OFF_AUTO)
			if(on == 1)
				return POWERCHAN_ON_AUTO
		if(POWERCHAN_ON)
			if(on == 0)
				return POWERCHAN_OFF
		if(POWERCHAN_ON_AUTO)
			if(on == 0 || on == 2)
				return POWERCHAN_OFF_AUTO

	return cur_state //leave unchanged


// damage and destruction acts
/obj/machinery/power/apc/emp_act(severity)
	// Fail for 8-12 minutes (divided by severity)
	// Division by 2 is required, because machinery ticks are every two seconds. Without it we would fail for 16-24 minutes.
	if(is_critical)
		// Critical APCs are considered EMP shielded and will be offline only for about half minute. Prevents AIs being one-shot disabled by EMP strike.
		// Critical APCs are also more resilient to cell corruption/power drain.
		energy_fail(rand(240, 360) / severity / CRITICAL_APC_EMP_PROTECTION)
		if(cell)
			cell.emp_act(severity+2)
	else
		// Regular APCs fail for normal time.
		energy_fail(rand(240, 360) / severity)
		//Cells are partially shielded by the APC frame.
		if(cell)
			cell.emp_act(severity+1)

	update_icon()
	..()

/obj/machinery/power/apc/legacy_ex_act(severity)

	switch(severity)
		if(1)
			//set_broken() //now qdel() do what we need
			if (cell)
				LEGACY_EX_ACT(cell, 1, null) // more lags woohoo
			qdel(src)
			return
		if(2)
			if (prob(75))
				set_broken()
				if (cell && prob(50))
					LEGACY_EX_ACT(cell, 2, null)
		if(3)
			if (prob(50))
				set_broken()
				if (cell && prob(50))
					LEGACY_EX_ACT(cell, 3, null)
		if(4)
			if (prob(25))
				set_broken()
				if (cell && prob(50))
					LEGACY_EX_ACT(cell, 3, null)
	return

/obj/machinery/power/apc/disconnect_terminal()
	if(terminal)
		terminal.master = null
		terminal = null

/obj/machinery/power/apc/proc/set_broken()
	// Aesthetically much better!
	spawn(rand(2,5))
		src.visible_message("<span class='warning'>[src]'s screen flickers suddenly, then explodes in a rain of sparks and small debris!</span>")
		machine_stat |= BROKEN
		operating = 0
		update_icon()
		update()

// overload the lights in this APC area

/obj/machinery/power/apc/proc/overload_lighting(var/chance = 100)
	if(/* !get_connection() || */ !operating || shorted || grid_check)
		return
	if( cell && cell.charge>=20)
		cell.use(20);
		spawn(0)
			for(var/obj/machinery/light/L in area)
				if(prob(chance))
					L.on = 1
					L.broken()
				sleep(1)

/obj/machinery/power/apc/proc/flicker_lights(var/chance = 100)
	for(var/obj/machinery/light/L in area)
		L.flicker(rand(15,25))

/obj/machinery/power/apc/proc/setsubsystem(val)
	if(cell && cell.charge > 0)
		return (val==1) ? 0 : val
	else if(val == 3)
		return 1
	else
		return 0

// Malfunction: Transfers APC under AI's control
/obj/machinery/power/apc/proc/ai_hack(var/mob/living/silicon/ai/A = null)
	if(!A || !A.hacked_apcs || hacker || aidisabled || A.stat == DEAD)
		return 0
	src.hacker = A
	A.hacked_apcs += src
	locked = 1
	update_icon()
	return 1

/obj/machinery/power/apc/proc/reboot()
	//reset various counters so that process() will start fresh
	charging = initial(charging)
	chargecount = initial(chargecount)
	autoflag = initial(autoflag)
	longtermpower = initial(longtermpower)
	failure_timer = initial(failure_timer)

	//start with main breaker off, chargemode in the default state and all channels on auto upon reboot
	operating = 0
	chargemode = initial(chargemode)
	power_alarm.clearAlarm(loc, src)

	lighting = POWERCHAN_ON_AUTO
	equipment = POWERCHAN_ON_AUTO
	environ = POWERCHAN_ON_AUTO

	//If malf AI had this APC before, they don't now.
	if(hacker && hacker.hacked_apcs && (src in hacker.hacked_apcs))
		hacker.hacked_apcs -= src
		hacker = null

	emagged = initial(emagged) //Resets emagging, too.

	update_icon()
	update()

/obj/machinery/power/apc/overload(var/obj/machinery/power/source)
	if(is_critical)
		return

	if(prob(30)) // Nothing happens.
		return

	if(prob(40)) // Lights blow.
		overload_lighting()

	if(prob(40)) // Spooky flickers.
		for(var/obj/machinery/light/L in area)
			L.flicker(rand(20,30))

	if(prob(25)) // Bluescreens.
		emagged = 1
		locked = 0
		update_icon()

	if(prob(25)) // Cell gets damaged.
		if(cell)
			cell.corrupt()

	if(prob(10)) // Computers get broken.
		for(var/obj/machinery/computer/comp in area)
			LEGACY_EX_ACT(comp, 3, null)

	if(prob(5)) // APC completely ruined.
		set_broken()

/obj/machinery/power/apc/do_grid_check()
	if(is_critical)
		return
	grid_check = TRUE
	spawn(15 MINUTES) // Protection against someone deconning the grid checker after a grid check happens, preventing infinte blackout.
		if(src && grid_check == TRUE)
			grid_check = FALSE

/obj/machinery/power/apc/proc/update_area()//From apc_vr.dm
	var/area/NA = get_area(src)
	if(!(NA == area))
		if(area.apc == src)
			area.apc = null
		NA.apc = src
		area = NA
		name = "[area.name] APC"
	update()

/obj/machinery/power/apc/proc/set_nightshift(on, automated)
	set waitfor = FALSE
	if(automated && istype(area, /area/shuttle))
		return
	if(nightshift_lights == on)
		return //no change
	nightshift_lights = on
	update_nightshift()

/obj/machinery/power/apc/proc/update_nightshift()
	var/new_state = nightshift_lights

	switch(nightshift_setting)
		if(NIGHTSHIFT_NEVER)
			new_state = FALSE
		if(NIGHTSHIFT_ALWAYS)
			new_state = TRUE

	for(var/obj/machinery/light/L in area)
		L.nightshift_mode(new_state)
		CHECK_TICK

#undef APC_UPDATE_ICON_COOLDOWN
