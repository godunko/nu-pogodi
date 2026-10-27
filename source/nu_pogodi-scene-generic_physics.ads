--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Types;

with Nu_Pogodi.Keyboard;
with Nu_Pogodi.Sounds;

generic
   with function Timer return A0B.Types.Unsigned_4;

   type Time is private;

   with function Clock return Time;

   with function Seconds_Ones (Item : Time) return A0B.Types.Unsigned_4;

   with function Seconds_Tens (Item : Time) return A0B.Types.Unsigned_4;

   with function Minutes_Ones (Item : Time) return A0B.Types.Unsigned_4;

   with function Minutes_Tens (Item : Time) return A0B.Types.Unsigned_4;

   with function Hours_Ones (Item : Time) return A0B.Types.Unsigned_4;

   with function Hours_Tens (Item : Time) return A0B.Types.Unsigned_4;

package Nu_Pogodi.Scene.Generic_Physics is

   procedure Initialize (Mode : Game_Mode)
     with Pre => Mode /= None;

   procedure Update_Physics_Tick
     (Refresh : in out Boolean;
      Sound   : out Nu_Pogodi.Sounds.Sound_Identifier);

   procedure Update_Keyboad_State
     (State : Nu_Pogodi.Keyboard.Keyboard_State;
      Sound : out Nu_Pogodi.Sounds.Sound_Identifier);

end Nu_Pogodi.Scene.Generic_Physics;
