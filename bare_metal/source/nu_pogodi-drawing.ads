--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Types;

with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Framebuffers;

package Nu_Pogodi.Drawing is

   type Color_Type is (Black, White);

   procedure Fill (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);
   --  Fills framebuffer by 16#FF# bytes.

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      X           : A0B.Types.Unsigned_32;
      Y           : A0B.Types.Unsigned_32;
      Bitmap      : Nu_Pogodi.Bitmaps.Bitmap_Descriptor);

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      X           : A0B.Types.Unsigned_32;
      Y           : A0B.Types.Unsigned_32;
      Bitmap      : Nu_Pogodi.Bitmaps.RLE_Bitmap_Descriptor);
   --  Decode and AND into framebuffer, clipping at framebuffer boundaries.

   procedure Fill_Rectangle
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Left        : A0B.Types.Unsigned_32;
      Top         : A0B.Types.Unsigned_32;
      Width       : A0B.Types.Unsigned_32;
      Height      : A0B.Types.Unsigned_32;
      Color       : Color_Type);
   --  Fills rectangle by the given color, no blending.
   --
   --  XXX for low level implementation it might be better to use
   --  Left/Top/Right/Bottom, Left & Top inclusive, Right & Bottom exclusive.

end Nu_Pogodi.Drawing;
