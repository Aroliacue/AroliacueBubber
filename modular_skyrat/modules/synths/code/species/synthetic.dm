/datum/species/synthetic
	name = "Synthetic Humanoid"
	id = SPECIES_SYNTH
	inherent_biotypes = MOB_ROBOTIC | MOB_HUMANOID
	inherent_traits = list(
		TRAIT_CAN_STRIP,
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_RADIMMUNE,
		TRAIT_NOBREATH,
		TRAIT_TOXIMMUNE,
		TRAIT_GENELESS,
		TRAIT_STABLEHEART,
		TRAIT_LIMBATTACHMENT,
		TRAIT_NO_HUSK,
		TRAIT_LITERATE,
		TRAIT_NOCRITDAMAGE, // We do our own handling of crit damage.
		TRAIT_ROBOTIC_DNA_ORGANS,
		TRAIT_SYNTHETIC,
	)
	mutant_bodyparts = list()
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN | RACE_SWAP | SLIME_EXTRACT
	reagent_flags = PROCESS_SYNTHETIC
	payday_modifier = 1.0 // Matches the rest of the pay penalties the non-human crew have
	species_language_holder = /datum/language_holder/machine
	mutant_organs = list(/obj/item/organ/cyberimp/arm/toolkit/power_cord)
	mutantbrain = /obj/item/organ/brain/synth
	mutantstomach = /obj/item/organ/stomach/synth
	mutantears = /obj/item/organ/ears/synth
	mutanttongue = /obj/item/organ/tongue/synth
	mutanteyes = /obj/item/organ/eyes/synth
	mutantlungs = /obj/item/organ/lungs/synth
	mutantheart = /obj/item/organ/heart/synth
	mutantliver = /obj/item/organ/liver/synth
	mutantappendix = null
	exotic_bloodtype = BLOOD_TYPE_OIL
	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/synth,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/synth,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/synth,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/synth,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/synth,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/synth,
	)
	digitigrade_customization = DIGITIGRADE_OPTIONAL
	coldmod = 1.2
	heatmod = 2 // TWO TIMES DAMAGE FROM BEING TOO HOT?! WHAT?! No wonder lava is literal instant death for us.
	siemens_coeff = 1.4 // Not more because some shocks will outright crit you, which is very unfun
	/// The innate action that synths get, if they've got a screen selected on species being set.
	var/datum/action/innate/monitor_change/screen
	/// This is the screen that is given to the user after they get revived. On death, their screen is temporarily set to BSOD before it turns off, hence the need for this var.
	var/saved_screen = "Blank"

	/// Set to TRUE if the species was emagged before
	var/emag_effect = FALSE

/datum/species/synthetic/allows_food_preferences()
	return FALSE

/datum/species/synthetic/get_default_mutant_bodyparts()
	return list(
		"tail" = list("None", FALSE),
		"ears" = list("None", FALSE),
		"legs" = list("Normal Legs", FALSE),
		"snout" = list("None", FALSE),
		MUTANT_SYNTH_ANTENNA = list("None", FALSE),
		MUTANT_SYNTH_SCREEN = list("None", FALSE),
		MUTANT_SYNTH_CHASSIS = list("Default Chassis", FALSE),
		MUTANT_SYNTH_HEAD = list("Default Head", FALSE),
	)

/datum/species/synthetic/spec_life(mob/living/carbon/human/human)
	. = ..()

	if(human.stat == SOFT_CRIT || human.stat == HARD_CRIT)
		human.adjustFireLoss(1) //Still deal some damage in case a cold environment would be preventing us from the sweet release to robot heaven
		human.adjust_bodytemperature(13) //We're overheating!!
		if(prob(10))
			to_chat(human, span_warning("Alert: Critical damage taken, all systems failing."))
			do_sparks(3, TRUE, human)

	var/obj/item/organ/lungs/lungs = human.get_organ_slot(ORGAN_SLOT_LUNGS)
	if(!lungs || (lungs.organ_flags & ORGAN_FAILING))
		// No lungs or failing lungs present, apply overheating
		human.adjust_bodytemperature(50)
		human.adjustFireLoss(1)
		if(prob(10))
			to_chat(human, span_warning("Alert: Cooling system is non-functional or missing, OVERHEATING is imminent."))
			do_sparks(3, TRUE, human)

	var/obj/item/organ/heart/heart = human.get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart || (heart.organ_flags & ORGAN_FAILING))
		// No heart or failing heart present, apply slowdown
		human.adjust_staggered_up_to(STAGGERED_SLOWDOWN_LENGTH, 5 SECONDS)
		if(prob(10))
			to_chat(human, span_warning("Alert: Oil pump is non-functional or missing. Hydraulics efficiency reduced."))

	var/obj/item/organ/liver/liver = human.get_organ_slot(ORGAN_SLOT_LIVER)
	if(!liver || (liver.organ_flags & ORGAN_FAILING))
		// No liver or failing liver present, apply message informing of the missing liver
		if(prob(10))
			to_chat(human, span_warning("Alert: Reagent processing unit is non-functional or missing. Systems clogging."))

/datum/species/synthetic/spec_revival(mob/living/carbon/human/transformer)
	switch_to_screen(transformer, "Console")
	addtimer(CALLBACK(src, PROC_REF(switch_to_screen), transformer, saved_screen), 5 SECONDS)
	playsound(transformer.loc, 'sound/machines/chime.ogg', 50, TRUE)
	transformer.visible_message(span_notice("[transformer]'s [screen ? "monitor lights up" : "eyes flicker to life"]!"), span_notice("All systems nominal. You're back online!"))

/datum/species/synthetic/on_species_gain(mob/living/carbon/human/human_who_gained_species, datum/species/old_species, pref_load, regenerate_icons = TRUE)
	. = ..()

	RegisterSignal(human_who_gained_species, COMSIG_ATOM_EMAG_ACT, PROC_REF(on_emag_act))

	var/datum/action/sing_tones/sing_action = new
	sing_action.Grant(human_who_gained_species)

	var/screen_mutant_bodypart = human_who_gained_species.dna.mutant_bodyparts[MUTANT_SYNTH_SCREEN]
	var/obj/item/organ/eyes/eyes = human_who_gained_species.get_organ_slot(ORGAN_SLOT_EYES)

	if(!screen && screen_mutant_bodypart && screen_mutant_bodypart[MUTANT_INDEX_NAME] && screen_mutant_bodypart[MUTANT_INDEX_NAME] != "None")

		if(eyes)
			eyes.eye_icon_state = "None"

		screen = new(human_who_gained_species)
		screen.Grant(human_who_gained_species)

		RegisterSignal(human_who_gained_species, COMSIG_LIVING_DEATH, PROC_REF(bsod_death)) // screen displays bsod on death, if they have one

		return

	if(eyes)
		eyes.eye_icon_state = initial(eyes.eye_icon_state)


/datum/species/synthetic/apply_supplementary_body_changes(mob/living/carbon/human/target, datum/preferences/preferences, visuals_only = FALSE)
	var/list/chassis = target.dna.mutant_bodyparts[MUTANT_SYNTH_CHASSIS]
	var/list/head = target.dna.mutant_bodyparts[MUTANT_SYNTH_HEAD]
	if(!chassis && !head)
		return

	var/datum/sprite_accessory/synth_chassis/chassis_of_choice = SSaccessories.sprite_accessories[MUTANT_SYNTH_CHASSIS][chassis[MUTANT_INDEX_NAME]]
	var/datum/sprite_accessory/synth_head/head_of_choice = SSaccessories.sprite_accessories[MUTANT_SYNTH_HEAD][head[MUTANT_INDEX_NAME]]
	if(!chassis_of_choice && !head_of_choice)
		return

	examine_limb_id = chassis_of_choice.icon_state

	if(chassis_of_choice.color_src || head_of_choice.color_src)
		target.add_traits(list(TRAIT_MUTANT_COLORS), SPECIES_TRAIT)

	// We want to ensure that the IPC gets their chassis and their head correctly.
	for(var/obj/item/bodypart/limb as anything in target.bodyparts)
		if(limb.limb_id != SPECIES_SYNTH && initial(limb.base_limb_id) != SPECIES_SYNTH) // No messing with limbs that aren't actually synthetic.
			continue

		if(limb.body_zone == BODY_ZONE_HEAD)
			if(head_of_choice.color_src && head[MUTANT_INDEX_COLOR_LIST] && length(head[MUTANT_INDEX_COLOR_LIST]))
				limb.add_color_override(head[MUTANT_INDEX_COLOR_LIST][1], LIMB_COLOR_SYNTH)
			limb.change_appearance(head_of_choice.icon, head_of_choice.icon_state, !!head_of_choice.color_src, head_of_choice.dimorphic)
			continue

		if(chassis_of_choice.color_src && chassis[MUTANT_INDEX_COLOR_LIST] && length(chassis[MUTANT_INDEX_COLOR_LIST]))
			limb.add_color_override(chassis[MUTANT_INDEX_COLOR_LIST][1], LIMB_COLOR_SYNTH)
		limb.change_appearance(chassis_of_choice.icon, chassis_of_choice.icon_state, !!chassis_of_choice.color_src, limb.body_part == CHEST && chassis_of_choice.dimorphic)
		limb.name = "\improper[chassis_of_choice.name] [parse_zone(limb.body_zone)]"


/datum/species/synthetic/on_species_loss(mob/living/carbon/human/human)
	. = ..()

	UnregisterSignal(human, COMSIG_ATOM_EMAG_ACT)

	var/obj/item/organ/eyes/eyes = human.get_organ_slot(ORGAN_SLOT_EYES)

	if(eyes)
		eyes.eye_icon_state = initial(eyes.eye_icon_state)

	if(screen)
		screen.Remove(human)
		UnregisterSignal(human, COMSIG_LIVING_DEATH)

/datum/species/synthetic/proc/on_emag_act(mob/living/carbon/human/source, mob/user)
	SIGNAL_HANDLER

	if(emag_effect)
		return
	emag_effect = TRUE
	playsound(source.loc, 'sound/misc/interference.ogg', 50)
	to_chat(source, span_warning("Alert: Security breach detected in central processing unit. Error Code: 540-EXO"))

/**
 * Makes the IPC screen switch to BSOD followed by a blank screen
 *
 * Arguments:
 * * transformer - The human that will be affected by the screen change (read: IPC).
 * * screen_name - The name of the screen to switch the ipc_screen mutant bodypart to. Defaults to BSOD.
 */
/datum/species/synthetic/proc/bsod_death(mob/living/carbon/human/transformer, screen_name = "BSOD")
	saved_screen = screen // remember the old screen in case of revival
	switch_to_screen(transformer, screen_name)
	addtimer(CALLBACK(src, PROC_REF(switch_to_screen), transformer, "Blank"), 5 SECONDS)

/**
 * Simple proc to switch the screen of a monitor-enabled synth, while updating their appearance.
 *
 * Arguments:
 * * transformer - The human that will be affected by the screen change (read: IPC).
 * * screen_name - The name of the screen to switch the ipc_screen mutant bodypart to.
 */
/datum/species/synthetic/proc/switch_to_screen(mob/living/carbon/human/transformer, screen_name)
	if(!screen)
		return

	// This is awful. Please find a better way to do this.
	var/obj/item/organ/synth_screen/screen_organ = transformer.get_organ_slot(ORGAN_SLOT_EXTERNAL_SYNTH_SCREEN)
	if(!istype(screen_organ))
		return

	transformer.dna.mutant_bodyparts[MUTANT_SYNTH_SCREEN][MUTANT_INDEX_NAME] = screen_name
	screen_organ.bodypart_overlay.set_appearance_from_dna(transformer.dna)
	transformer.update_body()

/datum/species/synthetic/get_types_to_preload()
	return ..() - typesof(/obj/item/organ/cyberimp/arm/toolkit/power_cord) // Don't cache things that lead to hard deletions.

/datum/species/synthetic/create_pref_unique_perks()
	var/list/perk_descriptions = list()

	perk_descriptions += list(list( //tryin to keep traits minimal since synths will get a lot of traits when my upstream traits pr is merged
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = "robot",
		SPECIES_PERK_NAME = "Synthetic Benefits",
		SPECIES_PERK_DESC = "Unlike organics, you DON'T explode when faced with a vacuum! Additionally, your chassis is built with such strength as to \
		grant you immunity to OVERpressure! Just make sure that the extreme cold or heat doesn't fry your circuitry."
	))

	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = "star-of-life",
		SPECIES_PERK_NAME = "Unhuskable",
		SPECIES_PERK_DESC = "[plural_form] can't be husked, disappointing changelings galaxy-wide.",
	))

	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEUTRAL_PERK,
		SPECIES_PERK_ICON = "robot",
		SPECIES_PERK_NAME = "Synthetic Oddities",
		SPECIES_PERK_DESC = "[plural_form] are unable to gain nutrition from traditional foods. Instead, you must either consume welding fuel or extend a \
		wire from your arm to draw power from an APC. In addition to this, welders and wires are your sutures and mesh and only specific chemicals even metabolize inside \
		of you. This ranges from whiskey, to synthanol, to various obscure medicines. Finally, you suffer from a set of wounds exclusive to synthetics."
	))

	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_POSITIVE_PERK,
		SPECIES_PERK_ICON = "music",
		SPECIES_PERK_NAME = "Tone Synthesizer",
		SPECIES_PERK_DESC = "[plural_form] can sing musical tones using an internal synthesizer.",
	))

	perk_descriptions += list(list(
		SPECIES_PERK_TYPE = SPECIES_NEGATIVE_PERK,
		SPECIES_PERK_ICON = "band-aid",
		SPECIES_PERK_NAME = "Structural Damage",
		SPECIES_PERK_DESC = "[plural_form] are weak to blunt objects.",
	))

	return perk_descriptions

/datum/species/synthetic/prepare_human_for_preview(mob/living/carbon/human/beepboop)
	beepboop.dna.mutant_bodyparts[MUTANT_SYNTH_SCREEN] = list(MUTANT_INDEX_NAME = "Console", MUTANT_INDEX_COLOR_LIST = list(COLOR_WHITE, COLOR_WHITE, COLOR_WHITE))
	regenerate_organs(beepboop, src, visual_only = TRUE)
	beepboop.update_body(TRUE)
