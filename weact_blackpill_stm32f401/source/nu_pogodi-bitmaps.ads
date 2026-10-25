--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Types.Arrays;

with Nu_Pogodi.Framebuffers;
with Nu_Pogodi.Display_Segments;

package Nu_Pogodi.Bitmaps is

   type Byte_Array_Access is access constant A0B.Types.Arrays.Unsigned_8_Array;

   type RLE_Bitmap_Descriptor is record
      X      : A0B.Types.Unsigned_32;
      Y      : A0B.Types.Unsigned_32;
      Width  : A0B.Types.Unsigned_32;
      Height : A0B.Types.Unsigned_32;
      Data   : Byte_Array_Access;
   end record;
   --  Byte RLE in scanline order; runs may cross scanline boundaries.
   --  Control 0 .. 127: copy the next Control + 1 bytes.
   --  Control 128 .. 255: repeat the next byte Control - 128 + 3 times.
   --  X and Width must be multiples of eight.

   type Bitmap_Descriptor is record
      X      : A0B.Types.Unsigned_32;
      Y      : A0B.Types.Unsigned_32;
      Width  : A0B.Types.Unsigned_32;
      Height : A0B.Types.Unsigned_32;
      Data   : Byte_Array_Access;
   end record;

   function Metadata
     (Id : Nu_Pogodi.Display_Segments.Display_Segment_Identifier)
      return RLE_Bitmap_Descriptor;

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Id          : Nu_Pogodi.Display_Segments.Display_Segment_Identifier);
   --  AND one bitmap into Buffer, clipping at screen boundaries.
   --  Does not clear Buffer. Process one individual scanline at a time.

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Set         : Nu_Pogodi.Display_Segments.Display_Segment_Set);

   procedure Reconstruct
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);
   --  Fill Buffer with white and draw all 72 artwork components.

end Nu_Pogodi.Bitmaps;
