--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Buffers;

package Nu_Pogodi.States is

   type Abstract_State is abstract tagged limited private;

   not overriding procedure Render
     (Self   : in out Abstract_State;
      Buffer : in out A0B.Buffers.Abstract_Buffer'Class) is abstract;

   not overriding procedure Physics_Tick
     (Self    : in out Abstract_State;
      Refresh : in out Boolean) is abstract;
   --  Do tick of the scene physics. Set `Refresh` to True if the scene needs
   --  to be redrawn, otherwise leave it unchanged.

private

   type Abstract_State is abstract tagged limited null record;

end Nu_Pogodi.States;
