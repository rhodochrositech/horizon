#define FIREALARM_COOLDOWN 67 // Chosen fairly arbitrarily, it is the length of the audio in FireAlarm.ogg. The actual track length is 7 seconds 8ms but but the audio stops at 6s 700ms

/obj/item/electronics/firealarm
	name = "fire alarm electronics"
	desc = "A fire alarm circuit. Can handle heat levels up to 40 degrees celsius."

/obj/item/wallframe/firealarm
	name = "fire alarm frame"
	desc = "Used for building fire alarms."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire_bitem"
	result_path = /obj/machinery/firealarm

/obj/machinery/firealarm
	name = "fire alarm"
	desc = "<i>\"Pull this in case of emergency\"</i>. Thus, keep pulling it forever."
	icon = 'icons/obj/monitors.dmi'
	icon_state = "fire0"
	max_integrity = 250
	integrity_failure = 0.4
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 100, FIRE = 90, ACID = 30)
	use_power = IDLE_POWER_USE
	idle_power_usage = 2
	active_power_usage = 6
	power_channel = AREA_USAGE_ENVIRON
	resistance_flags = FIRE_PROOF

	light_power = 0
	light_range = 7
	light_color = COLOR_VIVID_RED

	//Trick to get the glowing overlay visible from a distance
	luminosity = 1

	var/detecting = 1
	var/buildstage = 2 // 2 = complete, 1 = no wires, 0 = circuit gone
	COOLDOWN_DECLARE(last_alarm)
	var/area/myarea = null
	//Has this firealarm been triggered by its enviroment?
	var/triggered = FALSE

/obj/machinery/firealarm/Initialize(mapload, dir, building)
	. = ..()
	if(dir)
		src.setDir(dir)
	if(building)
		buildstage = 0
		panel_open = TRUE
		pixel_x = (dir & 3)? 0 : (dir == 4 ? -24 : 24)
		pixel_y = (dir & 3)? (dir ==1 ? -24 : 24) : 0
	update_appearance()
	myarea = get_area(src)
	LAZYADD(myarea.firealarms, src)
	
	AddElement(/datum/element/atmos_sensitive, mapload)
	RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, .proc/check_security_level)

/obj/machinery/firealarm/Destroy()
	myarea.firereset(src)
	LAZYREMOVE(myarea.firealarms, src)
	return ..()

/obj/machinery/firealarm/update_icon_state()
	if(panel_open)
		icon_state = "fire_b[buildstage]"
		return ..()
	if(machine_stat & BROKEN)
		icon_state = "firex"
		return ..()
	icon_state = "fire0"
	return ..()

/obj/machinery/firealarm/update_overlays()
	. = ..()
	if(machine_stat & NOPOWER)
		return

	. += "fire_overlay"
	if(is_station_level(z))
		. += "fire_[SSsecurity_level.current_level]"
		. += mutable_appearance(icon, "fire_[SSsecurity_level.current_level]")
		. += emissive_appearance(icon, "fire_[SSsecurity_level.current_level]")
	else
		. += "fire_[SEC_LEVEL_GREEN]"
		. += mutable_appearance(icon, "fire_[SEC_LEVEL_GREEN]")
		. += emissive_appearance(icon, "fire_[SEC_LEVEL_GREEN]")

	var/area/A = get_area(src)

	if(!detecting || !A.fire)
		. += "fire_off"
		. += mutable_appearance(icon, "fire_off")
		. += emissive_appearance(icon, "fire_off")
	else if(obj_flags & EMAGGED)
		. += "fire_emagged"
		. += mutable_appearance(icon, "fire_emagged")
		. += emissive_appearance(icon, "fire_emagged")
	else
		. += "fire_on"
		. += mutable_appearance(icon, "fire_on")
		. += emissive_appearance(icon, "fire_on")

	if(!panel_open && detecting && triggered) //It just looks horrible with the panel open
		. += "fire_detected"
		. += mutable_appearance(icon, "fire_detected")
		. += emissive_appearance(icon, "fire_detected") //Pain

/obj/machinery/firealarm/emp_act(severity)
	. = ..()

	if (. & EMP_PROTECT_SELF)
		return

	if(prob(50 / severity))
		alarm()

/obj/machinery/firealarm/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	update_appearance()
	if(user)
		user.visible_message("<span class='warning'>Sparks fly out of [src]!</span>",
							"<span class='notice'>You emag [src], disabling its thermal sensors.</span>")
	playsound(src, "sparks", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)

/obj/machinery/firealarm/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	if(obj_flags & EMAGGED || machine_stat)
		return FALSE
	var/turf/open/open_turf = loc
	if(istype(open_turf) && open_turf.turf_fire)
		return TRUE
	if(exposed_temperature > T0C + 80 || exposed_temperature < T0C - 10)
		return TRUE

/obj/machinery/firealarm/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	if(!detecting)
		return
	if(!triggered)
		triggered = TRUE
		myarea.triggered_firealarms += 1
		update_appearance()
	alarm()

/obj/machinery/firealarm/atmos_end()
	if(!detecting)
		return
	if(triggered)
		triggered = FALSE
		myarea.triggered_firealarms -= 1
		update_appearance()

/**
 * Signal handler for checking if we should update fire alarm appearance accordingly to a newly set security level
 *
 * Arguments:
 * * source The datum source of the signal
 * * new_level The new security level that is in effect
 */
/obj/machinery/firealarm/proc/check_security_level(datum/source, new_level)
	SIGNAL_HANDLER

	if(is_station_level(z))
		update_appearance()

/obj/machinery/firealarm/proc/alarm(mob/user)
	if(!is_operational || !COOLDOWN_FINISHED(src, last_alarm))
		return
	COOLDOWN_START(src, last_alarm, FIREALARM_COOLDOWN)
	var/area/A = get_area(src)
	A.firealert(src)
	playsound(loc, 'goon/sound/machinery/FireAlarm.ogg', 75)
	if(user)
		log_game("[user] triggered a fire alarm at [COORD(src)]")

/obj/machinery/firealarm/proc/reset(mob/user)
	if(!is_operational)
		return
	var/area/A = get_area(src)
	A.firereset()
	if(user)
		log_game("[user] reset a fire alarm at [COORD(src)]")

/obj/machinery/firealarm/attack_hand(mob/user, list/modifiers)
	if(buildstage != 2)
		return ..()
	add_fingerprint(user)
	var/area/A = get_area(src)
	if(A.fire)
		reset(user)
	else
		alarm(user)

/obj/machinery/firealarm/attack_ai(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attack_robot(mob/user)
	return attack_hand(user)

/obj/machinery/firealarm/attackby(obj/item/W, mob/living/user, params)
	add_fingerprint(user)

	if(W.tool_behaviour == TOOL_SCREWDRIVER && buildstage == 2)
		W.play_tool_sound(src)
		panel_open = !panel_open
		to_chat(user, "<span class='notice'>The wires have been [panel_open ? "exposed" : "unexposed"].</span>")
		update_appearance()
		return

	if(panel_open)

		if(W.tool_behaviour == TOOL_WELDER && !user.combat_mode)
			if(obj_integrity < max_integrity)
				if(!W.tool_start_check(user, amount=0))
					return

				to_chat(user, "<span class='notice'>You begin repairing [src]...</span>")
				if(W.use_tool(src, user, 40, volume=50))
					obj_integrity = max_integrity
					to_chat(user, "<span class='notice'>You repair [src].</span>")
			else
				to_chat(user, "<span class='warning'>[src] is already in good condition!</span>")
			return

		switch(buildstage)
			if(2)
				if(W.tool_behaviour == TOOL_MULTITOOL)
					detecting = !detecting
					if (src.detecting)
						user.visible_message("<span class='notice'>[user] reconnects [src]'s detecting unit!</span>", "<span class='notice'>You reconnect [src]'s detecting unit.</span>")
					else
						user.visible_message("<span class='notice'>[user] disconnects [src]'s detecting unit!</span>", "<span class='notice'>You disconnect [src]'s detecting unit.</span>")
					return

				else if(W.tool_behaviour == TOOL_WIRECUTTER)
					buildstage = 1
					W.play_tool_sound(src)
					new /obj/item/stack/cable_coil(user.loc, 5)
					to_chat(user, "<span class='notice'>You cut the wires from \the [src].</span>")
					update_appearance()
					return

				else if(W.force) //hit and turn it on
					..()
					var/area/A = get_area(src)
					if(!A.fire)
						alarm()
					return

			if(1)
				if(istype(W, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/coil = W
					if(coil.get_amount() < 5)
						to_chat(user, "<span class='warning'>You need more cable for this!</span>")
					else
						coil.use(5)
						buildstage = 2
						to_chat(user, "<span class='notice'>You wire \the [src].</span>")
						update_appearance()
					return

				else if(W.tool_behaviour == TOOL_CROWBAR)
					user.visible_message("<span class='notice'>[user.name] removes the electronics from [src.name].</span>", \
										"<span class='notice'>You start prying out the circuit...</span>")
					if(W.use_tool(src, user, 20, volume=50))
						if(buildstage == 1)
							if(machine_stat & BROKEN)
								to_chat(user, "<span class='notice'>You remove the destroyed circuit.</span>")
								set_machine_stat(machine_stat & ~BROKEN)
							else
								to_chat(user, "<span class='notice'>You pry out the circuit.</span>")
								new /obj/item/electronics/firealarm(user.loc)
							buildstage = 0
							update_appearance()
					return
			if(0)
				if(istype(W, /obj/item/electronics/firealarm))
					to_chat(user, "<span class='notice'>You insert the circuit.</span>")
					qdel(W)
					buildstage = 1
					update_appearance()
					return

				else if(istype(W, /obj/item/electroadaptive_pseudocircuit))
					var/obj/item/electroadaptive_pseudocircuit/P = W
					if(!P.adapt_circuit(user, 15))
						return
					user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
					"<span class='notice'>You adapt a fire alarm circuit and slot it into the assembly.</span>")
					buildstage = 1
					update_appearance()
					return

				else if(W.tool_behaviour == TOOL_WRENCH)
					user.visible_message("<span class='notice'>[user] removes the fire alarm assembly from the wall.</span>", \
						"<span class='notice'>You remove the fire alarm assembly from the wall.</span>")
					var/obj/item/wallframe/firealarm/frame = new /obj/item/wallframe/firealarm()
					frame.forceMove(user.drop_location())
					W.play_tool_sound(src)
					qdel(src)
					return

	return ..()

/obj/machinery/firealarm/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	if((buildstage == 0) && (the_rcd.upgrade & RCD_UPGRADE_SIMPLE_CIRCUITS))
		return list("mode" = RCD_UPGRADE_SIMPLE_CIRCUITS, "delay" = 20, "cost" = 1)
	return FALSE

/obj/machinery/firealarm/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	switch(passed_mode)
		if(RCD_UPGRADE_SIMPLE_CIRCUITS)
			user.visible_message("<span class='notice'>[user] fabricates a circuit and places it into [src].</span>", \
			"<span class='notice'>You adapt a fire alarm circuit and slot it into the assembly.</span>")
			buildstage = 1
			update_appearance()
			return TRUE
	return FALSE

/obj/machinery/firealarm/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(.) //damage received
		if(obj_integrity > 0 && !(machine_stat & BROKEN) && buildstage != 0)
			if(prob(33))
				alarm()

/obj/machinery/firealarm/singularity_pull(S, current_size)
	if (current_size >= STAGE_FIVE) // If the singulo is strong enough to pull anchored objects, the fire alarm experiences integrity failure
		deconstruct()
	..()

/obj/machinery/firealarm/obj_break(damage_flag)
	if(buildstage == 0) //can't break the electronics if there isn't any inside.
		return
	. = ..()
	if(.)
		LAZYREMOVE(myarea.firealarms, src)

/obj/machinery/firealarm/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		new /obj/item/stack/sheet/iron(loc, 1)
		if(!(machine_stat & BROKEN))
			var/obj/item/I = new /obj/item/electronics/firealarm(loc)
			if(!disassembled)
				I.obj_integrity = I.max_integrity * 0.5
		new /obj/item/stack/cable_coil(loc, 3)
	qdel(src)

/obj/machinery/firealarm/proc/update_fire_light(fire)
	if(fire == !!light_power)
		return  // do nothing if we're already active
	if(fire)
		set_light(l_power = 0.8)
	else
		set_light(l_power = 0)

/obj/machinery/firealarm/directional/north
	pixel_y = 26

/obj/machinery/firealarm/directional/south
	dir = NORTH
	pixel_y = -26

/obj/machinery/firealarm/directional/east
	dir = WEST
	pixel_x = 26

/obj/machinery/firealarm/directional/west
	dir = EAST
	pixel_x = -26

/*
 * Return of Party button
 */

/area
	var/party = FALSE

/obj/machinery/firealarm/partyalarm
	name = "\improper PARTY BUTTON"
	desc = "Cuban Pete is in the house!"
	var/static/party_overlay

/obj/machinery/firealarm/partyalarm/reset()
	if (machine_stat & (NOPOWER|BROKEN))
		return
	var/area/A = get_area(src)
	if (!A || !A.party)
		return
	A.party = FALSE
	A.cut_overlay(party_overlay)

/obj/machinery/firealarm/partyalarm/alarm()
	if (machine_stat & (NOPOWER|BROKEN))
		return
	var/area/A = get_area(src)
	if (!A || A.party || A.name == "Space")
		return
	A.party = TRUE
	if (!party_overlay)
		party_overlay = iconstate2appearance('icons/turf/areas.dmi', "party")
	A.add_overlay(party_overlay)
