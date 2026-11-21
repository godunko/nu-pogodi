--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Display_Segments.Sprites;
with Nu_Pogodi.Drawing;

package body Nu_Pogodi.Bitmaps is

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Id          : Nu_Pogodi.Display_Segments.Display_Segment_Identifier)
   is
      Sprite : constant not null access constant
        Nu_Pogodi.Display_Segments.Sprites.Sprite_Descriptor :=
          Nu_Pogodi.Display_Segments.Sprites.Metadata (Id);

   begin
      Nu_Pogodi.Drawing.Draw
        (Framebuffer, Sprite.X, Sprite.Y, Sprite.Bitmap.all);
   end Draw;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Set         : Nu_Pogodi.Display_Segments.Display_Segment_Set) is
   begin
      for Id in Set'Range loop
         if Set (Id) then
            Draw (Framebuffer, Id);
         end if;
      end loop;
   end Draw;

   -----------------
   -- Reconstruct --
   -----------------

   procedure Reconstruct
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer) is
   begin
      Nu_Pogodi.Drawing.Fill (Framebuffer);

      for Id in Nu_Pogodi.Display_Segments.Display_Segment_Identifier loop
         Draw (Framebuffer, Id);
      end loop;
   end Reconstruct;

end Nu_Pogodi.Bitmaps;
