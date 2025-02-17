/datum/disease/cordyceps
	form = "Disease"
	name = "Cordyceps omniteralis"
	max_stages = 5
	spread_text = "Airborne"
	cure_text = "Spaceacillin & Convermol"
	cures = list(/datum/reagent/medicine/spaceacillin, /datum/reagent/medicine/c2/convermol)
	agent = "Fungal Cordycep bacillus"
	viable_mobtypes = list(/mob/living/carbon/human)
	cure_chance = 30
	desc = "Fungal virus that attacks patient's muscles and brain in an attempt to hijack them. Causes fever, headaches, muscle spasms, and fatigue."
	severity = DISEASE_SEVERITY_BIOHAZARD
	bypasses_immunity = TRUE

/datum/disease/cordyceps/stage_act()
	. = ..()
	if(!.)
		return

	switch(stage)
		if(2)
			if(prob(2))
				affected_mob.emote("twitch")
				to_chat(affected_mob, "<span class='danger'>You twitch.</span>")
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>Your feel tired</span>")
			if(prob(5))
				to_chat(affected_mob, "<span class='danger'>You head hurts.</span>")
		if(3,4)
			if(prob(2))
				to_chat(affected_mob, "<span class='userdanger'>You see four of everything!</span>")
				affected_mob.Dizzy(5)
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>You suddenly feel exhausted.</span>")
				affected_mob.adjustStaminaLoss(30, FALSE)
			if(prob(2))
				to_chat(affected_mob, "<span class='danger'>You feel hot.</span>")
				affected_mob.adjust_bodytemperature(20)
		if(5)
			if(prob(5))
				to_chat(affected_mob, "<span class='userdanger'>[pick("Your muscles seize!", "You collapse!")]</span>")
				affected_mob.adjustStaminaLoss(50, FALSE)
				affected_mob.Paralyze(40, FALSE)
				affected_mob.adjustBruteLoss(5) //It's damaging the muscles
			if(prob(2))
				affected_mob.adjustStaminaLoss(100, FALSE)
				affected_mob.visible_message("<span class='warning'>[affected_mob] faints!</span>", "<span class='userdanger'>You surrender yourself and feel at peace...</span>")
				affected_mob.AdjustSleeping(100)
			if(prob(5))
				to_chat(affected_mob, "<span class='userdanger'>You feel your mind relax and your thoughts drift!</span>")
				affected_mob.set_confusion(min(100, affected_mob.get_confusion() + 8))
				affected_mob.adjustOrganLoss(ORGAN_SLOT_BRAIN, 10)
			if(prob(10))
				to_chat(affected_mob, "<span class='danger'>[pick("You feel uncomfortably hot...", "You feel like unzipping your jumpsuit", "You feel like taking off some clothes...")]</span>")
				affected_mob.adjust_bodytemperature(30)

/datum/reagent/cordycepsspores
	name = "Cordycep bacillus microbes"
	description = "Active fungal spores."
	color = "#92D17D"
	chemical_flags = NONE
	taste_description = "slime"
	penetrates_skin = NONE

/datum/reagent/cordycepsspores/expose_mob(mob/living/exposed_mob, methods=TOUCH, reac_volume, show_message = TRUE, touch_protection = 0)
	. = ..()
	if((methods & (PATCH|INGEST|INJECT)) || ((methods & VAPOR) && prob(min(reac_volume,100)*(1 - touch_protection))))
		exposed_mob.ForceContractDisease(new /datum/disease/cordyceps(), FALSE, TRUE)
