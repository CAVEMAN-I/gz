#include <stdint.h>
#include <string.h>
#include "explorer.h"
#include "gz.h"
#include "menu.h"
#include "settings.h"
#include "z64.h"

static void set_entrance_proc(struct menu_item *item, void *data)
{
  z64_file.void_pos = z64_link.common.pos_2;
  z64_file.void_yaw = z64_link.common.rot_2.y;
  z64_file.void_var = z64_link.common.variable;
  z64_file.void_entrance = z64_file.entrance_index;
  z64_file.void_room_index = z64_game.room_ctxt.rooms[0].index;
}

static void clear_scene_flags_proc(struct menu_item *item, void *data)
{
  memset(&z64_game.swch_flags, 0x00, 0x24);
}

static void set_scene_flags_proc(struct menu_item *item, void *data)
{
  memset(&z64_game.swch_flags, 0xFF, 0x24);
}

static void load_room_proc(struct menu_item *item, void *data)
{
  uint8_t new_room_index = menu_intinput_get(data);
  if (new_room_index < z64_game.n_rooms) {
    if (new_room_index == z64_game.room_ctxt.rooms[0].index) {
      z64_game.room_ctxt.rooms[0].index = -1;
      z64_game.room_ctxt.rooms[0].file = NULL;
      z64_UnloadRoom(&z64_game, &z64_game.room_ctxt);
      z64_game.room_ctxt.rooms[0].index = -1;
      z64_game.room_ctxt.rooms[0].file = NULL;
    }
    else {
      z64_game.room_ctxt.rooms[0].index = -1;
      z64_game.room_ctxt.rooms[0].file = NULL;
      z64_UnloadRoom(&z64_game, &z64_game.room_ctxt);
      z64_game.room_ctxt.rooms[0].index = -1;
      z64_game.room_ctxt.rooms[0].file = NULL;
      z64_LoadRoom(&z64_game, &z64_game.room_ctxt, new_room_index);
    }
  }
}

static int col_view_proc(struct menu_item *item,
                         enum menu_callback_reason reason,
                         void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON) {
    if (gz.col_view_state == COLVIEW_INACTIVE)
      gz.col_view_state = COLVIEW_START;
  }
  else if (reason == MENU_CALLBACK_SWITCH_OFF) {
    if (gz.col_view_state != COLVIEW_INACTIVE)
      gz.col_view_state = COLVIEW_STOP;
  }
  else if (reason == MENU_CALLBACK_THINK) {
    _Bool state = gz.col_view_state == COLVIEW_START ||
                  gz.col_view_state == COLVIEW_ACTIVE ||
                  gz.col_view_state == COLVIEW_BEGIN_RESTART ||
                  gz.col_view_state == COLVIEW_RESTART;
    if (menu_checkbox_get(item) != state)
      menu_checkbox_set(item, state);
  }
  return 0;
}

static int hit_view_proc(struct menu_item *item,
                         enum menu_callback_reason reason,
                         void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON) {
    if (gz.hit_view_state == HITVIEW_INACTIVE)
      gz.hit_view_state = HITVIEW_START;
  }
  else if (reason == MENU_CALLBACK_SWITCH_OFF) {
    if (gz.hit_view_state != HITVIEW_INACTIVE)
      gz.hit_view_state = HITVIEW_BEGIN_STOP;
  }
  else if (reason == MENU_CALLBACK_THINK) {
    _Bool state = gz.hit_view_state == HITVIEW_START ||
                  gz.hit_view_state == HITVIEW_ACTIVE;
    if (menu_checkbox_get(item) != state)
      menu_checkbox_set(item, state);
  }
  return 0;
}

static int col_view_mode_proc(struct menu_item *item,
                              enum menu_callback_reason reason,
                              void *data)
{
  if (reason == MENU_CALLBACK_THINK_INACTIVE) {
    if (menu_option_get(item) != settings->bits.col_view_mode)
      menu_option_set(item, settings->bits.col_view_mode);
  }
  else if (reason == MENU_CALLBACK_DEACTIVATE)
    settings->bits.col_view_mode = menu_option_get(item);
  return 0;
}

static int col_view_xlu_proc(struct menu_item *item,
                             enum menu_callback_reason reason,
                             void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.col_view_xlu = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.col_view_xlu = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.col_view_xlu);
  return 0;
}

static int col_view_line_proc(struct menu_item *item,
                              enum menu_callback_reason reason,
                              void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.col_view_line = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.col_view_line = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.col_view_line);
  return 0;
}

static int col_view_shade_proc(struct menu_item *item,
                               enum menu_callback_reason reason,
                               void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.col_view_shade = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.col_view_shade = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.col_view_shade);
  return 0;
}

static int col_view_rd_proc(struct menu_item *item,
                            enum menu_callback_reason reason,
                            void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.col_view_rd = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.col_view_rd = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.col_view_rd);
  return 0;
}

static int col_view_upd_proc(struct menu_item *item,
                             enum menu_callback_reason reason,
                             void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.col_view_upd = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.col_view_upd = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.col_view_upd);
  return 0;
}

static int hit_view_xlu_proc(struct menu_item *item,
                             enum menu_callback_reason reason,
                             void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.hit_view_xlu = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.hit_view_xlu = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.hit_view_xlu);
  return 0;
}

static int hit_view_shade_proc(struct menu_item *item,
                               enum menu_callback_reason reason,
                               void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    settings->bits.hit_view_shade = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    settings->bits.hit_view_shade = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, settings->bits.hit_view_shade);
  return 0;
}

static int hide_rooms_proc(struct menu_item *item,
                           enum menu_callback_reason reason,
                           void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    gz.hide_rooms = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    gz.hide_rooms = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, gz.hide_rooms);
  return 0;
}

static int hide_actors_proc(struct menu_item *item,
                            enum menu_callback_reason reason,
                            void *data)
{
  if (reason == MENU_CALLBACK_SWITCH_ON)
    gz.hide_actors = 1;
  else if (reason == MENU_CALLBACK_SWITCH_OFF)
    gz.hide_actors = 0;
  else if (reason == MENU_CALLBACK_THINK)
    menu_checkbox_set(item, gz.hide_actors);
  return 0;
}

static void teleport_dec_proc(struct menu_item *item, void *data)
{
  settings->teleport_slot += SETTINGS_TELEPORT_MAX - 1;
  settings->teleport_slot %= SETTINGS_TELEPORT_MAX;
}

static void teleport_inc_proc(struct menu_item *item, void *data)
{
  settings->teleport_slot += 1;
  settings->teleport_slot %= SETTINGS_TELEPORT_MAX;
}

struct menu *gz_scene_menu(void)
{
  static struct menu menu;
  static struct menu explorer;
  static struct menu collision;
  struct menu_item *item;

  /* initialize menus */
  menu_init(&menu, MENU_NOVALUE, MENU_NOVALUE, MENU_NOVALUE);
  menu_init(&collision, MENU_NOVALUE, MENU_NOVALUE, MENU_NOVALUE);

  /* populate scene menu */
  menu.selector = menu_add_submenu(&menu, 0, 0, NULL, "return");
  /* explorer */
  explorer_create(&explorer);
  menu_add_submenu(&menu, 0, 1, &explorer, "explorer");
  gz.menu_explorer = &explorer;
  /* scene controls */
  menu_add_button(&menu, 0, 2, "set entrance point", set_entrance_proc, NULL);
  menu_add_button(&menu, 0, 3, "clear flags", clear_scene_flags_proc, NULL);
  menu_add_button(&menu, 0, 4, "set flags", set_scene_flags_proc, NULL);
  item = menu_add_intinput(&menu, 16, 5, 10, 2, NULL, NULL);
  menu_add_button(&menu, 0, 5, "load room", load_room_proc, item);
  /* visuals controls */
  menu_add_submenu(&menu, 0, 6, &collision, "collision");
  menu_add_static(&menu, 0, 7, "hide rooms", 0xC0C0C0);
  menu_add_checkbox(&menu, 16, 7, hide_rooms_proc, NULL);
  menu_add_static(&menu, 0, 8, "hide actors", 0xC0C0C0);
  menu_add_checkbox(&menu, 16, 8, hide_actors_proc, NULL);
  /* teleport controls */
  menu_add_static(&menu, 0, 9, "teleport slot", 0xC0C0C0);
  menu_add_watch(&menu, 18, 9,
                 (uint32_t)&settings->teleport_slot, WATCH_TYPE_U8);
  menu_add_button(&menu, 16, 9, "-", teleport_dec_proc, NULL);
  menu_add_button(&menu, 20, 9, "+", teleport_inc_proc, NULL);
  /* scene info watches */
  menu_add_static(&menu, 0, 10, "current scene", 0xC0C0C0);
  menu_add_watch(&menu, 16, 10,
                 (uint32_t)&z64_game.scene_index, WATCH_TYPE_U16);
  menu_add_static(&menu, 0, 11, "current room", 0xC0C0C0);
  menu_add_watch(&menu, 16, 11,
                 (uint32_t)&z64_game.room_ctxt.rooms[0].index, WATCH_TYPE_U8);
  menu_add_static(&menu, 0, 12, "no. rooms", 0xC0C0C0);
  menu_add_watch(&menu, 16, 12, (uint32_t)&z64_game.n_rooms, WATCH_TYPE_U8);

  /* populate collision menu */
  collision.selector = menu_add_submenu(&collision, 0, 0, NULL, "return");
  /* collision view controls */
  menu_add_static(&collision, 0, 1, "show collision", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 1, col_view_proc, NULL);
  menu_add_static(&collision, 2, 2, "mode", 0xC0C0C0);
  menu_add_option(&collision, 16, 2, "decal\0""surface\0",
                  col_view_mode_proc, NULL);
  menu_add_static(&collision, 2, 3, "translucent", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 3, col_view_xlu_proc, NULL);
  menu_add_static(&collision, 2, 4, "wireframe", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 4, col_view_line_proc, NULL);
  menu_add_static(&collision, 2, 5, "shaded", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 5, col_view_shade_proc, NULL);
  menu_add_static(&collision, 2, 6, "reduced", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 6, col_view_rd_proc, NULL);
  menu_add_static(&collision, 2, 7, "auto update", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 7, col_view_upd_proc, NULL);
  /* hitbox view controls */
  menu_add_static(&collision, 0, 8, "show hitboxes", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 8, hit_view_proc, NULL);
  menu_add_static(&collision, 2, 9, "translucent", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 9, hit_view_xlu_proc, NULL);
  menu_add_static(&collision, 2, 10, "shaded", 0xC0C0C0);
  menu_add_checkbox(&collision, 16, 10, hit_view_shade_proc, NULL);

  return &menu;
}
