pragma Ada_2022;

with A0B.Types.Arrays;

with Nu_Pogodi.Framebuffers;
with Nu_Pogodi.Sprites;

package Nu_Pogodi.Bitmaps is
   --  Layout: scanlines top-to-bottom, bytes left-to-right.
   --  Each byte holds 8 horizontal pixels; bit 7 is the leftmost.
   --  Black pixels are 0; white/padding pixels are 1.
   Screen_Width   : constant := 400;
   Screen_Height  : constant := 252;
   Row_Bytes      : constant := Screen_Width / 8;

   type Byte_Array_Access is access constant A0B.Types.Arrays.Unsigned_8_Array;

   type Bitmap_Descriptor is record
      X      : A0B.Types.Unsigned_32;
      Y      : A0B.Types.Unsigned_32;
      Width  : A0B.Types.Unsigned_32;
      Height : A0B.Types.Unsigned_32;
      Data   : Byte_Array_Access;
   end record;

   function Metadata
     (Id : Nu_Pogodi.Sprites.Sprite_Id) return Bitmap_Descriptor;

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Id          : Nu_Pogodi.Sprites.Sprite_Id);
   --  AND one bitmap into Buffer, clipping at screen boundaries.
   --  Does not clear Buffer. Process one individual scanline at a time.

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Set         : Nu_Pogodi.Sprites.Sprite_Set);

   procedure Reconstruct
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer);
   --  Fill Buffer with white and draw all 72 artwork components.

end Nu_Pogodi.Bitmaps;
