--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Display_Segments;

generic
package Nu_Pogodi.Generic_Scene.Generic_Screen is

   procedure Get_Visibility
     (Sprites : in out Nu_Pogodi.Display_Segments.Display_Segment_Set);

end Nu_Pogodi.Generic_Scene.Generic_Screen;
