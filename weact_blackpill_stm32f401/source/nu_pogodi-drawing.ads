--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Framebuffers;

package Nu_Pogodi.Drawing is

   procedure Fill (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);
   --  Fills framebuffer by 16#FF# bytes.

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Bitmap      : Nu_Pogodi.Bitmaps.Bitmap_Descriptor);

end Nu_Pogodi.Drawing;
