--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Types;

with Nu_Pogodi.Bitmaps;

package Nu_Pogodi.Display_Segments.Sprites is

   type Sprite_Descriptor is record
      X      : A0B.Types.Unsigned_32;
      Y      : A0B.Types.Unsigned_32;
      Bitmap : not null access constant
        Nu_Pogodi.Bitmaps.RLE_Bitmap_Descriptor;
   end record;

   function Metadata
     (Id : Nu_Pogodi.Display_Segments.Display_Segment_Identifier)
      return not null access constant Sprite_Descriptor;

end Nu_Pogodi.Display_Segments.Sprites;
