///////////////////////////
// Dost thou even hoist? //
///////////////////////////

/obj/item/hoist_kit
	name = "hoist kit"
	desc = "A setup kit for a hoist that can be used to lift things. The hoist will deploy in the direction you're facing."
	icon = 'icons/obj/hoists.dmi'
	icon_state = "hoist_case"

/obj/item/hoist_kit/attack_self(mob/user)
	new /obj/structure/hoist (get_turf(user), user.dir)
	user.visible_message(
		"<span class='warning'>[user] deploys the hoist kit!</span>",
		"<span class='notice'>You deploy the hoist kit!</span>",
		"<span class='notice'>You hear the sound of parts snapping into place.</span>"
		)
	qdel(src)

/obj/effect/hoist_hook
	name = "hoist clamp"
	desc = "A clamp used to lift people or things."
	icon = 'icons/obj/hoists.dmi'
	icon_state = "hoist_hook"
	var/obj/structure/hoist/source_hoist
	can_buckle = 1
	anchored = 1

/obj/effect/hoist_hook/attack_hand(mob/living/user)
	return // no, bad

/obj/effect/hoist_hook/MouseDrop_T(atom/movable/AM,mob/user)
	var/canuse = use_check(user, USE_DISALLOW_SILICONS)
	if(canuse) // to cut it down from 4+ return statements to just 1
		switch(canuse)
			if(USE_FAIL_INCAPACITATED)
				to_chat(user, "<span class='warning'>You can't do that while incapacitated!</span>")
			if(USE_FAIL_NONLIVING)
				to_chat(user, "<span class='warning'>You can't do that while dead.</span>")
			if(USE_FAIL_IS_SILICON)
				to_chat(user, "<span class='notice'>You need hands for that.</span>")
			if(USE_FAIL_NON_ADV_TOOL_USR)
				to_chat(user, "<span class='warning'>You stare cluelessly at \the [src].</span>")
		return

	if (!AM.simulated || AM.anchored)
		to_chat(user, "<span class='notice'>You can't do that.</span>")
		return
	if (source_hoist.hoistee)
		to_chat(user, "<span class='notice'>\The [source_hoist.hoistee] is already attached to \the [src]!</span>")
		return
	source_hoist.attach_hoistee(AM)
	user.visible_message(
		"<span class='danger'>[user] attaches \the [AM] to \the [src].</span>",
		"<span class='danger'>You attach \the [AM] to \the [src].</span>",
		"<span class='danger'>You hear something clamp into place.</span>"
		)

/obj/structure/hoist/proc/attach_hoistee(atom/movable/AM)
	if (get_turf(AM) != get_turf(source_hook))
		AM.forceMove(get_turf(source_hook))
	hoistee = AM
	if(ismob(AM))
		source_hook.buckle_mob(AM)
	AM.anchored = 1 // why isn't this being set by buckle_mob for silicons?

/obj/effect/hoist_hook/MouseDrop(atom/dest)
	..()
	if(!Adjacent(usr) || !dest.Adjacent(usr)) return // carried over from the default proc

	if (!ishuman(usr))
		return

	if (usr.incapacitated())
		to_chat(usr, "<span class='notice'>You can't do that while incapacitated.</span>")
		return

	if (!usr.IsAdvancedToolUser())
		to_chat(usr, "<span class='notice'>You stare cluelessly at \the [src].</span>")
		return

	if (!source_hoist.hoistee)
		return
	if (!isturf(dest))
		return
	if (!dest.Adjacent(source_hoist.hoistee))
		return

	source_hoist.check_consistency()

	var/turf/desturf = dest
	source_hoist.hoistee.forceMove(desturf)
	usr.visible_message(
		"<span class='danger'>[usr] detaches \the [source_hoist.hoistee] from the hoist clamp.</span>",
		"<span class='danger'>You detach \the [source_hoist.hoistee] from the hoist clamp.</span>",
		"<span class='danger'>You hear something unclamp.</span>"
		)
	source_hoist.release_hoistee()

/obj/structure/hoist
	icon = 'icons/obj/hoists.dmi'
	icon_state = "hoist_base"
	var/broken = 0
	density = 1
	anchored = 1
	name = "hoist"
	desc = "A manual hoist, uses a clamp and pulley to hoist things."
	var/atom/movable/hoistee
	var/movedir = UP
	var/obj/effect/hoist_hook/source_hook

/obj/structure/hoist/Initialize(mapload, ndir)
	. = ..()
	dir = ndir
	var/turf/newloc = get_step(src, dir)
	source_hook = new(newloc)
	source_hook.source_hoist = src

/obj/structure/hoist/Destroy()
	if(hoistee)
		release_hoistee()
	QDEL_NULL(src.source_hook)
	return ..()

/obj/effect/hoist_hook/Destroy()
	source_hoist = null
	return ..()

/obj/structure/hoist/proc/check_consistency()
	if (!hoistee)
		return
	if (hoistee.z != source_hook.z)
		release_hoistee()
		return

/obj/structure/hoist/proc/release_hoistee()
	if(ismob(hoistee))
		source_hook.unbuckle_mob(hoistee)
	else
		hoistee.anchored = 0
	hoistee = null

/obj/structure/hoist/proc/break_hoist()
	if(broken)
		return
	broken = 1
	desc += " It looks broken, and the clamp has retracted back into the hoist. Seems like you'd have to re-deploy it to get it to work again."
	if(hoistee)
		release_hoistee()
	QDEL_NULL(source_hook)

/obj/structure/hoist/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
			return
		if(2.0)
			if(prob(50))
				qdel(src)
			else
				visible_message("\The [src] shakes violently, and neatly collapses as its damage sensors go off.")
				collapse_kit()
			return
		if(3.0)
			if(prob(50) && !broken)
				break_hoist()
			return

/obj/effect/hoist_hook/ex_act(severity)
	switch(severity)
		if(1.0)
			source_hoist.break_hoist()
			return
		if(2.0)
			if(prob(50))
				source_hoist.break_hoist()
			return
		if(3.0)
			if(prob(25))
				source_hoist.break_hoist()
			return


/obj/structure/hoist/attack_hand(mob/living/user)
	if (!ishuman(user))
		return

	if (user.incapacitated())
		to_chat(user, "<span class='notice'>You can't do that while incapacitated.</span>")
		return

	if (!user.IsAdvancedToolUser())
		to_chat(user, "<span class='notice'>You stare cluelessly at \the [src].</span>")
		return

	if(broken)
		to_chat(user, "<span class='warning'>The hoist is broken!</span>")
		return
	var/can = can_move_dir(movedir)
	var/movtext = movedir == UP ? "raise" : "lower"
	if (!can) // If you can't...
		movedir = movedir == UP ? DOWN : UP // switch directions!
		to_chat(user, "<span class='notice'>You switch the direction of the pulley.</span>")
		return

	if (!hoistee)
		user.visible_message(
			"<span class='notice'>[user] begins to [movtext] the clamp.</span>",
			"<span class='notice'>You begin to [movtext] the clamp.</span>",
			"<span class='notice'>You hear the sound of a crank.</span>"
			)
		move_dir(movedir, 0)
		return

	check_consistency()

	var/size
	if (ismob(hoistee))
		var/mob/M = hoistee
		size = M.mob_size
	else if (isobj(hoistee))
		var/obj/O = hoistee
		size = O.w_class

	user.visible_message(
		"<span class='notice'>[user] begins to [movtext] \the [hoistee]!</span",
		"<span class='notice'>You begin to [movtext] \the [hoistee]!</span>",
		"<span class='notice'>You hear the sound of a crank.</span>"
		)
	if (do_after(user, (1 SECONDS) * size / 4, src))
		move_dir(movedir, 1)

/obj/structure/hoist/proc/collapse_kit()
	new /obj/item/hoist_kit(get_turf(src))
	qdel(src)

/obj/structure/hoist/verb/collapse_hoist()
	set name = "Collapse Hoist"
	set category = "Object"
	set src in range(1)

	if (!ishuman(usr))
		return

	if (isobserver(usr) || usr.incapacitated())
		return
	if (!usr.IsAdvancedToolUser()) // thanks nanacode
		to_chat(usr, "<span class='notice'>You stare cluelessly at \the [src].</span>")
		return

	if (hoistee)
		to_chat(usr, "<span class='notice'>You cannot collapse the hoist with \the [hoistee] attached!</span>")
		return
	collapse_kit()

/obj/structure/hoist/proc/can_move_dir(direction)
	var/turf/dest = direction == UP ? GetAbove(source_hook) : GetBelow(source_hook)
	switch(direction)
		if (UP)
			if (!isopenturf(dest)) // can't move into a solid tile
				return 0
			if (source_hook in get_step(src, dir)) // you don't get to move above the hoist
				return 0
		if (DOWN)
			if (!isopenturf(get_turf(source_hook))) // can't move down through a solid tile
				return 0
	if (!dest) // can't move if there's nothing to move to
		return 0
	return 1 // i thought i could trust myself to write something as simple as this, guess i was wrong

/obj/structure/hoist/proc/move_dir(direction, ishoisting)
	var/can = can_move_dir(direction)
	if (!can)
		return 0
	var/turf/move_dest = direction == UP ? GetAbove(source_hook) : GetBelow(source_hook)
	source_hook.forceMove(move_dest)
	if (!ishoisting)
		return 1
	hoistee.hoist_act(move_dest)
	return 1

/atom/movable/proc/hoist_act(turf/dest)
	src.forceMove(dest)