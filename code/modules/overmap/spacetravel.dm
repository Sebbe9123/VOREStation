//list used to cache empty zlevels to avoid nedless map bloat
var/list/cached_space = list()

//Space stragglers go here

/obj/effect/overmap/visitable/sector/temporary
	name = "Deep Space"
	invisibility = 101
	known = 0

/obj/effect/overmap/visitable/sector/temporary/New(var/nx, var/ny, var/nz)
	loc = locate(nx, ny, global.using_map.overmap_z)
	x = nx
	y = ny
	map_z += nz
	map_sectors["[nz]"] = src
	testing("Temporary sector at [x],[y] was created, corresponding zlevel is [nz].")

/obj/effect/overmap/visitable/sector/temporary/Destroy()
	map_sectors["[map_z]"] = null
	testing("Temporary sector at [x],[y] was deleted.")

/obj/effect/overmap/visitable/sector/temporary/proc/can_die(var/mob/observer)
	testing("Checking if sector at [map_z[1]] can die.")
	for(var/mob/M in global.player_list)
		if(M != observer && (M.z in map_z))
			testing("There are people on it.")
			return 0
	return 1

proc/get_deepspace(x,y)
	var/obj/effect/overmap/visitable/sector/temporary/res = locate(x,y,global.using_map.overmap_z)
	if(istype(res))
		return res
	else if(cached_space.len)
		res = cached_space[cached_space.len]
		cached_space -= res
		res.x = x
		res.y = y
		return res
	else
		return new /obj/effect/overmap/visitable/sector/temporary(x, y, global.using_map.get_empty_zlevel())

/atom/movable/proc/lost_in_space()
	for(var/atom/movable/AM in contents)
		if(!AM.lost_in_space())
			return FALSE
	return TRUE

/mob/lost_in_space()
	return isnull(client)

/mob/living/carbon/human/lost_in_space()
	return isnull(client) && !key && stat == DEAD

proc/overmap_spacetravel(var/turf/space/T, var/atom/movable/A)
	if (!T || !A)
		return

	var/obj/effect/overmap/visitable/M = map_sectors["[T.z]"]
	if (!M)
		return

	if(A.lost_in_space())
		if(!QDELETED(A))
			qdel(A)
		return

	var/nx = 1
	var/ny = 1
	var/nz = 1

	if(T.x <= TRANSITIONEDGE)
		nx = world.maxx - TRANSITIONEDGE - 2
		ny = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

	else if (A.x >= (world.maxx - TRANSITIONEDGE - 1))
		nx = TRANSITIONEDGE + 2
		ny = rand(TRANSITIONEDGE + 2, world.maxy - TRANSITIONEDGE - 2)

	else if (T.y <= TRANSITIONEDGE)
		ny = world.maxy - TRANSITIONEDGE -2
		nx = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

	else if (A.y >= (world.maxy - TRANSITIONEDGE - 1))
		ny = TRANSITIONEDGE + 2
		nx = rand(TRANSITIONEDGE + 2, world.maxx - TRANSITIONEDGE - 2)

	testing("[A] spacemoving from [M] ([M.x], [M.y]).")

	var/turf/map = locate(M.x,M.y,global.using_map.overmap_z)
	var/obj/effect/overmap/visitable/TM
	for(var/obj/effect/overmap/visitable/O in map)
		if(O != M && O.in_space && prob(50))
			TM = O
			break
	if(!TM)
		TM = get_deepspace(M.x,M.y)
	nz = pick(TM.get_space_zlevels())

	var/turf/dest = locate(nx,ny,nz)
	if(istype(dest))
		A.forceMove(dest)
		if(ismob(A))
			var/mob/D = A
			if(D.pulling)
				D.pulling.forceMove(dest)

	if(istype(M, /obj/effect/overmap/visitable/sector/temporary))
		var/obj/effect/overmap/visitable/sector/temporary/source = M
		if (source.can_die())
			testing("Caching [M] for future use")
			source.loc = null
			cached_space += source
