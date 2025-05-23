/datum/map/gateway/carpfarm_140
	id = "carpfarm_140"
	name = "Gateway - Carp Farm"
	width = 140
	height = 140
	levels = list(
		/datum/map_level/gateway/carpfarm_140,
	)

/datum/map_level/gateway/carpfarm_140
	id = "Carpfarm140"
	name = "Gateway - Carp Farm"
	display_name = "Carp Farm"
	path = "maps/away_missions/carpfarm_140/levels/carpfarm.dmm"
	base_turf = /turf/space
	base_area = /area/space

/obj/overmap/entity/visitable/sector/gateway/carpfarm
	initial_generic_waypoints = list("carpfarm1", "carpfarm2")
	scanner_name = "Carp-Infested Outpost"
	scanner_desc = @{"[i]Registration[/i]: UNKNOWN
[i]Class[/i]: Installation
[i]Transponder[/i]: None Detected
[b]Notice[/b]: Many spaceborne lifesigns detected"}

/area/awaymission/carpfarm
	icon_state = "blank"
	requires_power = 0

/area/awaymission/carpfarm/arrival
	icon_state = "away"
	requires_power = 0

/area/awaymission/carpfarm/base
	icon_state = "away"

/area/awaymission/carpfarm/base/entry
	icon_state = "blue"

/obj/item/paper/awaygate/carpfarm/suicide
	name = "suicide letter"
	info = "dear rescue,<br><br>my name markov. if reading this, i am dead. i <s>am</s> was miner for 3rd union of soviet socialist republiks. \
			comrades yuri, dimitri, ivan, all eaten by space carp. all started month ago when soviet shipment sent new sonic jackhammers. \
			carp attracted to vibrations. killed dimitri. yuri thought good idea to jury-rig hoverpods with lasers. not good idea. \
			very bad idea. only pissed them off. giant white carp appeared. killed ivan. then giant carp cracked yuri pod like \
			eggshell and swallowed yuri.<br><br>no food. can't call help. carp chewed comms relay. 2 weeks since then. \
			can't eat carp. is poison.<br><br>avenge comrades. avenge me. i die in glory.<br><br>-markov"
