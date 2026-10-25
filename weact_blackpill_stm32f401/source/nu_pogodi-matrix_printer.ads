--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Types;

with Nu_Pogodi.Bitmaps;
with Nu_Pogodi.Framebuffers;

package Nu_Pogodi.Matrix_Printer is

   function Frame_Count
     (Bitmap : Nu_Pogodi.Bitmaps.Bitmap_Descriptor) return Natural;

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Left_X      : A0B.Types.Unsigned_32;
      Top_Y       : A0B.Types.Unsigned_32;
      Bitmap      : Nu_Pogodi.Bitmaps.Bitmap_Descriptor;
      Frame       : Natural);
   --  Bitmap contains printer dots, MSB first, 1 = ink. X/Y specify the
   --  final screen position in pixels. Frame 0 is blank; Frame_Count is
   --  the final paper feed. Each pass ends with a separate feed frame.

end Nu_Pogodi.Matrix_Printer;
