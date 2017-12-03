-- Main engine functions -------------------------------------------------------

DEBUG = false
GRAVITY = 0.5
PARTICLE = true
config_sound_effect = 1
show_intro = true
function love.load(arg)
  -- body...
  love.graphics.setDefaultFilter("nearest", "nearest", 0)
  load_ressources()
  love.graphics.setDefaultFilter("linear", "linear", 0)
  game_load(700)

end

function load_ressources ()
  asset_background = love.graphics.newImage("assets/background.png")
  asset_player = love.graphics.newImage("assets/player.png")
  asset_ground = love.graphics.newImage("assets/ground.png")
  asset_crystal = love.graphics.newImage("assets/crystal.png")
  asset_portal = love.graphics.newImage("assets/portal.png")
  asset_melee = love.graphics.newImage("assets/melee_damage.png")
  asset_star = love.graphics.newImage("assets/ninja_star.png")
  asset_snowball = love.graphics.newImage("assets/snowball.png")
  asset_monster_1 = love.graphics.newImage("assets/monster_1.png")
  asset_snowman= love.graphics.newImage("assets/snowman.png")
  asset_crystal_crack = love.graphics.newImage("assets/crystal_crack.png")

  asset_stick = love.graphics.newImage("assets/stick.png")
  asset_wall = love.graphics.newImage("assets/wall.png")
  asset_hotplate = love.graphics.newImage("assets/hot_plate.png")
  asset_slowplate = love.graphics.newImage("assets/slow_plate.png")
  asset_maker_logo = love.graphics.newImage("assets/maker.png")
  asset_tools_bar = love.graphics.newImage("assets/tools_bar.png")

  assets_begin = "assets/begin.wave"
end
delta = 0
function love.update(dt)
  delta = delta + dt
  handle_input()
  if not show_intro then
    game_update(dt)
  end
end

function handle_input ()
  mouse_x = love.mouse.getX()
  mouse_y = love.mouse.getY()

  mouse_world_x = (camera_x * camera_zoom + mouse_x - love.graphics.getWidth() / 2) / camera_zoom
  mouse_world_y = (camera_y * camera_zoom + mouse_y - love.graphics.getHeight() / 2) / camera_zoom

  input_left = love.keyboard.isDown("q") or love.keyboard.isDown("a")
  input_right = love.keyboard.isDown("d")
  input_jump = love.keyboard.isDown("space")

  input_attack = love.keyboard.isDown("g")
  input_attack_2 = love.keyboard.isDown("h")
  input_wall = love.keyboard.isDown("j")
  input_slow_plate = love.keyboard.isDown("k")
  input_hot_plate = love.keyboard.isDown("l")
end

splash_time = 0
function love.draw()
  game_draw()

  if splash_time < 200 and show_intro then
    love.graphics.setColor(0,0,0, math.min(255, 255 * math.cos(splash_time / 100)))
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    love.graphics.setColor(255,255,255, math.min(255, 255 * math.cos(splash_time / 100)))
    love.graphics.draw(asset_maker_logo, love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0, 0.5, 0.5, asset_maker_logo:getWidth() / 2, asset_maker_logo:getHeight() / 2)
    love.graphics.print("Present a game made in 48Hours for the 40th \"Ludum Dare\".", love.graphics.getWidth() / 2 - asset_maker_logo:getWidth() / 4 - 32, love.graphics.getHeight() / 2 + 64)
    love.graphics.print("\"The more you have, the worst it is\".", love.graphics.getWidth() / 2 - asset_maker_logo:getWidth() / 4 - 32, love.graphics.getHeight() / 2 + 86)
    love.graphics.setColor(255,255,255,255)
    splash_time = splash_time + 1
  else
    show_intro = false
    love.graphics.draw(asset_tools_bar, love.graphics.getWidth() / 2, love.graphics.getHeight() - 128, 0, 2, 2, asset_tools_bar:getWidth() / 2, asset_tools_bar:getHeight() / 2)
    love.graphics.print("Mana: " .. player_mana, 128 , love.graphics.getHeight() - 128, 0 , 2,2)
    love.graphics.print("\nHeal: " .. player_heal, 128 , love.graphics.getHeight() - 128, 0 , 2,2)
  end
end

-- Main Game function ----------------------------------------------------------
function game_load (world_size)
  -- Camera
  camera_x = 0
  camera_y = 0
  camera_zoom = 2.0

  -- Player
  player_x = 0
  player_y = -48
  player_center_x = 10

  player_facing = "left"
  player_speed_x = 0
  player_max_speed_x = 5
  player_speed_y = 0
  player_max_cooldow= 30
  player_cooldown = 0
  player_damage_cooldown = 0

  player_width = 21
  player_height = 48

  -- Ground
  ground_x = -(1600 / 2)
  ground_y = 0

  ground_width = 1600
  ground_height = 32

  player_mana = 0
  player_heal = 128

  -- game zone
  game_zone_x = -700
  game_zone_y = -800 + 32
  game_zone_width = 1400
  game_zone_height = 800

  entities_counter = 0
  entity_id_counter = 0
  entities = {}

  camera_x = player_x + (player_width / 2)
  camera_y = player_y + (player_height / 2)

  add_entity(create_entity("portal", -world_size + 32, -96, "left"))
  add_entity(create_entity("portal", world_size - 38 - 32, -96, "right"))
  add_entity(create_entity("crystal", 0, -87, {life = 1000}))
end

play_melee_sound = false

function game_update (dt)
  update_soundmanager()
  update_player(dt)
  update_entity ()

  -- Update the camera
  camera_x = player_x + (player_width / 2)
  camera_y = player_y + (player_height / 2)

  if play_melee_sound then
    soundmanager_play("assets/hurt.wav", 1)
    play_melee_sound = false
  end

end

function update_player (dt)
  player_speed_y = player_speed_y + GRAVITY

  if input_left then
    player_speed_x = player_speed_x - 0.5
    player_facing = "left"
  elseif input_right then
    player_speed_x = player_speed_x + 0.5
    player_facing = "right"
  else
    player_speed_x = player_speed_x * 0.9
  end

  player_speed_x = math.min(player_speed_x, player_max_speed_x)
  player_speed_x = math.max(player_speed_x, -player_max_speed_x)

  if not check_collision(player_x + player_speed_x, player_y + player_speed_y, player_width, player_height, game_zone_x, game_zone_y, game_zone_width, game_zone_height) then
    player_speed_x = 0
  end

  if (check_collision(player_x + player_speed_x, player_y + player_speed_y, player_width, player_height, ground_x, ground_y, ground_width, ground_height)) then
    player_speed_y = 0
    player_y = -player_height
    player_touch_ground = true
  else
    player_touch_ground = false
  end

  if player_touch_ground and input_jump then
    player_speed_y = -10
  end

  -- Update the player
  player_x = player_x + player_speed_x
  player_y = player_y + player_speed_y
  player_center_x = player_x + 10

  -- Player trap and weapon ----------------------------------------------------

  player_cooldown = math.max(player_cooldown - 1, 0)
  player_damage_cooldown = player_damage_cooldown * 0.90

  if (input_attack or input_attack_2 or input_wall or input_hot_plate or input_slow_plate) and (player_cooldown == 0) then
    local weapon = nil
    player_speed_x = player_speed_x - (player_speed_x * 1.5)

    if input_attack then
      if player_facing == "left" then
          weapon = create_entity("melee", player_center_x - 48, player_y , {from="player", facing = player_facing})
      else
          weapon = create_entity("melee", player_center_x, player_y, {from="player", facing = player_facing})
      end
    end

    if input_attack_2 then
      if player_facing == "left" then
          weapon = create_entity("star", player_center_x, player_y, {from="player", dir = -1})
      else
          weapon = create_entity("star", player_center_x, player_y, {from="player", dir = 1})
      end
    end

    if input_wall then
      weapon = create_entity("wall", player_center_x, player_y, nil)
    end

    if input_hot_plate then
      weapon = create_entity("hot_plate", player_center_x, player_y, nil)
    end

    if input_slow_plate then
      weapon = create_entity("slow_plate", player_center_x, player_y, nil)
    end

    add_entity(weapon)
    player_cooldown = player_max_cooldow
  end
end

function game_draw ()
  love.graphics.push()
  -- Set camera transform.
  love.graphics.translate(-(camera_x * camera_zoom - love.graphics.getWidth() / 2), -(camera_y * camera_zoom - love.graphics.getHeight() / 2))
  love.graphics.scale(camera_zoom, camera_zoom)

  -- Draw the ground
  love.graphics.draw(asset_background, game_zone_x, game_zone_y, 0,2,2 )
  love.graphics.draw(asset_ground, ground_x, ground_y - 16)


  draw_entities()
  -- Draw the player
  love.graphics.setColor(255, 255 - player_damage_cooldown, 255 - player_damage_cooldown, 255)
  if player_facing == "right" then
    love.graphics.draw(asset_player, player_x + player_width, player_y, 0, -1, 1)
    love.graphics.draw(asset_stick, player_x + player_width - 5, player_y + 30, (player_cooldown / player_max_cooldow * 2) - 3.14 / 2)
  else
    love.graphics.draw(asset_player, player_x, player_y)
    love.graphics.draw(asset_stick, player_x, player_y + 30, -(player_cooldown / player_max_cooldow * 2) - 3.14 / 2)
  end
  love.graphics.setColor(255, 255, 255, 255)
  --love.graphics.draw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)

  love.graphics.points(mouse_world_x, mouse_world_y)

  if DEBUG then
    love.graphics.rectangle("line", game_zone_x, game_zone_y, game_zone_width, game_zone_height)
  end



  love.graphics.pop()

end

--------------------------------------------------------------------------------
-- ENTITIES UPDATE -------------------------------------------------------------
--------------------------------------------------------------------------------

function update_entity ()
  for _, v in pairs(entities) do

    v.speed_x = v.speed_x * 0.99
    v.damage_cool_down = v.damage_cool_down * 0.90
    if not check_collision(v.x, v.y, v.width, v.height, game_zone_x, game_zone_y, game_zone_width, game_zone_height) then
      if v.type == "star" or v.type == "coin" then
        remove_entity(v)
      end
    end

    -- Life time ---------------------------------------------------------------
    if not (v.life_time == -1) then
      if v.life_time == 0 then
        remove_entity(v)
      end
      v.life_time = v.life_time - 1
    end

    -- Portal ------------------------------------------------------------------
    if v.type == "portal" then
      if math.random(0, 300 ) == 5 then
        add_entity(create_entity("monster", v.x, v.y, nil))
        for i=1,50 do
          emite_particle(v.x+ math.random(0, v.width), v.y + math.random(0, v.height), math.random(-5, 5), math.random(-5, 5), math.random(0, 3), 255, 0, 255, math.random(0, 30))
        end
      end

      if math.random(0, 500 ) == 5 then
        add_entity(create_entity("snowman", v.x, v.y, nil))
        for i=1,50 do
          emite_particle(v.x+ math.random(0, v.width), v.y + math.random(0, v.height), math.random(-5, 5), math.random(-5, 5), math.random(0, 3), 255, 255, 255, math.random(0, 30))
        end
      end

      emite_particle(v.x+ v.width / 2, v.y + v.height / 2, math.random(-25, 25) / 100, math.random(-50, 50) / 100, math.random(0, 5), math.random(0, 255), 0, math.random(0, 255), math.random(0, 200))

    end

    if v.type == "crystal" then
      emite_particle(v.x + v.width / 2 + math.random(-16, 16), v.y + v.height - 5, math.random(-10, 10) / 1000, math.random(-5, 0), math.random(0, 3), 71, 130, 130, math.random(0, 150), false)
    end

    if v.type == "wall" then
      emite_particle(v.x + v.width / 2 + math.random(-4, 4), v.y + v.height - 5, math.random(-10, 10) / 1000, math.random(-5, 0), math.random(0, 3), 255, 130, 130, math.random(0, 50), false)
    end

    if v.type == "hot_plate" then
      emite_particle(v.x + v.width / 2 + math.random(-16, 16), v.y + v.height - 5, math.random(-10, 10) / 1000, math.random(-5, 0), math.random(0, 3), 255, 130, 130, math.random(0, 30), false)
    end

    if v.type == "slow_plate" then
      emite_particle(v.x + v.width / 2 + math.random(-16, 16), v.y + v.height - 5, math.random(-10, 10) / 1000, math.random(-5, 0), math.random(0, 3), 71, 130, 130, math.random(0, 30), false)
    end

    -- Monsters ----------------------------------------------------------------
    if v.type == "monster" or v.type == "snowman" then

      if v.on_ground and ((v.speed_x < 1) or (v.speed_x > -1))  then
        if (v.x > 0) then
          v.speed_x = -1
          v.facing = "left"
        else
          v.speed_x = 1
          v.facing = "right"
        end

        if math.random(0, 100) == 5 then v.speed_y = -10 end
      end

      if math.random(0, 150) == 5 then
        v.speed_x = -(v.speed_x * 2)
        v.speed_y = 0
          if v.type == "snowman" then
            if v.facing == "left" then
                add_entity(create_entity("snowball", v.x, v.y , {dir = -1}))
            else
                add_entity(create_entity("snowball", v.x, v.y, {dir = 1}))
            end
          else
            if v.facing == "left" then
              add_entity(create_entity("melee", v.x - 48, v.y, {from="monster", facing = v.facing}))
            else
              add_entity(create_entity("melee", v.x + 48, v.y, {from="monster", facing = v.facing}))
            end
          end

        end

    end

    -- Gravity -----------------------------------------------------------------
    if v.gravity then v.speed_y = v.speed_y + GRAVITY end

    -- Colision ----------------------------------------------------------------
    if v.colide then
      for _, e in pairs(entities) do
        if check_collision(v.x, v.y, v.width, v.height,
                           e.x, e.y, e.width, e.height) and not (e.id == v.id) then
          entity_colide_entity(v, e)
        end

      end
    end

    if check_collision(v.x, v.y, v.width, v.height, player_x, player_y, player_width, player_height) then
      entity_colide_player(v)
    end

    if check_collision(v.x + v.speed_x, v.y + v.speed_y, v.width, v.height, ground_x, ground_y, ground_width, ground_height) then
      v.speed_y = 0
      v.on_ground = true
    else
      v.on_ground = false
    end

    if (v.type == "star" or v.type == "snowball") and (v.on_ground) then
      for i=1,10 do
        emite_particle(v.x, v.y, math.random(-5, 5) / 5, math.random(-5, 0) / 5, 5, 128, 128, 128, 30)
      end
      remove_entity(v)
    end

    v.speed_x = v.speed_x * v.acceleration_x
    v.speed_y = v.speed_y * v.acceleration_y

    v.x = v.x + v.speed_x
    v.y = v.y + v.speed_y

    if v.damages >= v.heal then
      entity_died(v)
    end

  end
end

function entity_colide_entity (a, b)

  if (a.type == "monster" or a.type == "snowman") and b.type == "crystal" then a.speed_x = 0 end
  if (a.type == "monster" or a.type == "snowman") and b.type == "wall"    then a.speed_x = 0 end
  if (a.type == "monster" or a.type == "snowman") and b.type == "slow_plate" then a.speed_x = a.speed_x / 2 end

  if (a.type == "monster" or a.type == "snowman") and b.type == "hot_plate" then
    if math.random(0, 100) == 5 then
      a.damages = a.damages + 1
      a.damage_cool_down = 255
    end
  end

  if (a.type == "snowball" or (b.type == "melee" and b.attr.from == "monster")) and (b.type == "crystal" or b.type == "wall" ) then
    b.damages = b.damages + 1
    b.damage_cool_down = 255

    for i=1,math.random(0, 10) do
      emite_particle(a.x + math.random(0, a.width), a.y + math.random(0, a.height), math.random(-10, 10 ) / 10, math.random(-10, 10 ) / 10, math.random(1, 3), 255,255,255, 100, true)
    end

    remove_entity(a)
    soundmanager_play("assets/crystal_hit.wav", 1)
  end

  if (a.type == "monster" or a.type == "snowman") and b.type == "melee" and b.attr.from == "player" then
    if b.attr.facing == "left" then
      a.speed_x = -5
      a.speed_y = -5
    else
      a.speed_x = 5
      a.speed_y = -5
    end

    a.damages = a.damages + 1
    play_melee_sound = true
  end
end

function entity_colide_player (entity)
  if entity.type == "monster" or  entity.type == "snowman" then
    entity.speed_x = 0
  end
  if entity.type == "coin" then
    soundmanager_play("assets/coin.wav", 1)
    player_mana = player_mana + 1
    remove_entity(entity)
  end

  if entity.type == "snowball" then
    play_melee_sound = true
    player_heal = player_heal - 5
    remove_entity(entity)
    player_damage_cooldown = 255
  end

  if entity.type == "melee" and entity.attr.from == "monster" then
    play_melee_sound = true
    player_heal = player_heal - 4
    remove_entity(entity)

    if entity.attr.facing == "left" then
      player_speed_x = -5
      player_speed_y = -5
    else
      player_speed_x = 5
      player_speed_y = -5
    end

    player_damage_cooldown = 255
  end


end

function entity_died(entity)
  if entity.type == "crystal" then
    -- game over
    for i=1,math.random(0, 250) do
       local b = math.random(-50, 50)
       emite_particle(entity.x + entity.width / 2, entity.y + entity.height / 2, math.random(-100, 100 ) / 100, math.random(-100, 50 ) / 10, math.random(1, 10), 71 + b, 130 + b, 130 + b, math.random(0, 1000), true)
    end
    soundmanager_play("assets/crystal_hit.wav", 1)
  end

  if entity.type == "monster" then
    for i=1,math.random(0, 10) do
      emite_particle(entity.x, entity.y + math.random(0, entity.height), math.random(-10, 10), math.random(-10, 0), math.random(0, 5), math.random(0, 255), 0, 0, 100, true)
    end

    for i=1,math.random(1, 3) do
      emite_coin(entity.x, entity.y, math.random(-3, 3), math.random(-3, 0))
    end
  end

  if entity.type == "snowman" then
    for i=1,math.random(0, 25) do
      emite_particle(entity.x, entity.y + math.random(0, entity.height), math.random(-30, 30) / 30, math.random(-10, 0) / 10, math.random(1, 10), 255, 255, 255, 300, true)
    end

    for i=1,math.random(3, 5) do
      emite_coin(entity.x, entity.y, math.random(-3, 3), math.random(-3, 0))
    end
  end

  remove_entity(entity)
end

function draw_entities ()
  for i,v in pairs(entities) do


    if not (v.heal == -1) then
      love.graphics.setColor(0, 0, 0, 100)
      love.graphics.rectangle("fill", v.x - 1 , v.y + v.height + 7, v.width + 2, 4 + 2)
      love.graphics.setColor(255, 255, 255, 255)

      love.graphics.rectangle("line", v.x, v.y + v.height + 8, v.width, 4)
      love.graphics.rectangle("fill", v.x, v.y + v.height + 8, v.width * ( 1 - v.damages / v.heal), 4)
    end

    if v.type == "particle" then
      love.graphics.setPointSize(v.attr.size)
      love.graphics.setColor(v.attr.r, v.attr.g, v.attr.b, (v.life_time / v.max_life_time) * 255)
      love.graphics.points(v.x, v.y)
      love.graphics.setColor(255, 255, 255, 255)
    end

    if v.type == "coin" then
      love.graphics.setPointSize(5)
      love.graphics.setColor(247, 2013, 0, 255)
      love.graphics.points(v.x, v.y)
      love.graphics.setColor(255, 255, 255, 255)
    end

    love.graphics.setColor(255 , 255 - v.damage_cool_down, 255 - v.damage_cool_down, 255)

    if v.type == "crystal" then
      love.graphics.draw(asset_crystal, v.x, v.y)
      love.graphics.setColor(255, 255, 255, v.damages)
      love.graphics.draw(asset_crystal_crack, v.x, v.y)
      love.graphics.setColor(255, 255, 255, 255)
    end

    if v.type == "monster" then
      if v.facing == "left" then
        love.graphics.draw(asset_monster_1, v.x + v.width, v.y, 0, -1, 1)
      else
        love.graphics.draw(asset_monster_1, v.x, v.y)
      end
    end

    if v.type == "snowman" then
      if v.facing == "left" then
        love.graphics.draw(asset_snowman, v.x + v.width, v.y, 0, -1, 1)
      else
        love.graphics.draw(asset_snowman, v.x, v.y)
      end
    end

    if v.type == "portal" and v.attr == "left" then  love.graphics.draw(asset_portal, v.x, v.y) end
    if v.type == "portal" and v.attr == "right" then love.graphics.draw(asset_portal, v.x + v.width, v.y, 0, -1, 1) end
    if v.type == "star" then      love.graphics.draw( asset_star, v.x, v.y, delta ) end
    if v.type == "snowball" then  love.graphics.draw( asset_snowball, v.x, v.y ) end
    if v.type == "wall" then      love.graphics.draw(asset_wall, v.x, v.y) end
    if v.type == "hot_plate" then  love.graphics.draw(asset_hotplate, v.x, v.y) end
    if v.type == "slow_plate" then love.graphics.draw(asset_slowplate, v.x, v.y) end
    love.graphics.setColor(255, 255, 255, 255)

    if DEBUG and v.debug then
      love.graphics.setColor(255, 0, 0, 255)
      love.graphics.rectangle("line", v.x, v.y, v.width, v.height)
      love.graphics.print("id:" .. v.id .. "\nc" .. v.damage_cool_down, v.x, v.y)
      love.graphics.setColor(255, 255, 255, 255)
    end
  end
end

function emite_particle(x, y, sx, sy, size, r, g, b, l, gravity)
  if PARTICLE then
    add_entity(create_entity("particle", x, y, {r = r, g = g, b = b, l = l, size = size, sx = sx, sy = sy, gravity = gravity}))
  end
end

function emite_coin(x, y, sx, sy)
  add_entity(create_entity("coin", x, y, {sx = sx, sy = sy, gravity = gravity}))
end

function create_entity (type, x, y, attr)
  local entity = {type = type,
                  id = entity_id_counter,
                  x = x,
                  y = y,
                  speed_x = 0,
                  speed_y = 0.1,
                  acceleration_x = 1,
                  acceleration_y = 1,
                  width = 48,
                  height = 48,
                  colide = true,
                  colide_box = false,
                  damages = -9999,
                  heal = -1,
                  damage_cool_down = 0,
                  life_time = -1,
                  max_life_time = -1,

                  gravity = false,
                  on_ground = false,
                  attr = attr,
                  debug = true}

  if type == "portal" then
    entity.width = 38
    entity.height = 96
  end

  if type == "crystal" then
    entity.width = 87
    entity.height = 87
    entity.heal = 25
    entity.x = entity.x - entity.width / 2
    entity.damages = 0
  end

  if type == "monster" then
    entity.width = 48
    entity.height = 15
    entity.gravity = true
    entity.colide_box = true

    entity.heal = 5 + (delta / 1000)
    entity.damages = 0
  end

  if type == "snowman" then
    entity.width = 21
    entity.height = 40
    entity.gravity = true
    entity.colide_box = true

    entity.heal = 2 + (delta / 1000)
    entity.damages = 0
  end

  if type == "particle" then
    entity.width = 1
    entity.height = 1
    entity.speed_x = attr.sx
    entity.speed_y = attr.sy
    entity.life_time = attr.l
    entity.max_life_time = attr.l
    entity.gravity = attr.gravity
    entity.colide = false
    entity.debug = false
  end

  if type == "melee" then
    entity.life_time = 1
  end

  if type == "coin" then
    entity.width = 3
    entity.height = 3
    entity.speed_x = attr.sx
    entity.speed_y = attr.sy
    entity.gravity = true
  end

  if type == "star" then
    entity.width = 16
    entity.height = 16

    entity.speed_x = 10 * attr.dir
    entity.from = attr.from
    entity.gravity = false
    entity.speed_y = 0.01
    entity.acceleration_y = 1.1
  end

  if type == "snowball" then
    entity.width = 16
    entity.height = 16

    entity.speed_x = 10 * attr.dir
    entity.gravity = false
    entity.speed_y = 0.01
    entity.acceleration_y = 1.1
  end

  if type == "wall" then
    entity.width = 16
    entity.height = 48
    entity.y = -48
    entity.heal = 5
    entity.damages = 0
    entity.Gravity = false
  end

  if type == "hot_plate" then
    entity.width = 48
    entity.height = 16
    entity.y = -16
  end

  if type == "slow_plate" then
    entity.width = 48
    entity.height = 16
    entity.y = -16
  end

  entity_id_counter = entity_id_counter + 1

  return entity
end

function add_entity (entity)
  print("Entity " .. entity.id .. " " .. entity.type .. " Added")
  entities_counter = entities_counter + 1
  entities[entity.id] = entity
end

function remove_entity(entity)
  entities_counter = entities_counter - 1
  entities[entity.id] = nil
end

-- Utils -----------------------------------------------------------------------
function check_collision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

soundmanager_sources = {}

function update_soundmanager()

  local remove = {}
  for _,s in pairs(soundmanager_sources) do
      if s:isStopped() then
          remove[#remove + 1] = s
      end
  end

  for i,s in ipairs(remove) do
      soundmanager_sources[s] = nil
  end
end

function soundmanager_play(source)
  src = love.audio.newSource(source, "stream")
  src:setVolume(config_sound_effect)
  src:play()
  soundmanager_sources[source] = src
end
