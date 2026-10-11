--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

package Nu_Pogodi.States.Clock is

   type Clock_State is new Abstract_State with private;

private

   type Clock_State is new Abstract_State with null record;

   overriding procedure Render
     (Self   : in out Clock_State;
      Buffer : in out A0B.Buffers.Abstract_Buffer'Class);

   overriding procedure Physics_Tick
     (Self    : in out Clock_State;
      Refresh : out Boolean);

end Nu_Pogodi.States.Clock;
