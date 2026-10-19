pragma Ada_2022;

with A0B.Types;

with Nu_Pogodi.Sprites;

package Nu_Pogodi.Bitmaps is
   --  Layout: scanlines top-to-bottom, bytes left-to-right.
   --  Each byte holds 8 horizontal pixels; bit 7 is the leftmost.
   --  Black pixels are 0; white/padding pixels are 1.
   Screen_Width   : constant := 400;
   Screen_Height  : constant := 252;
   Row_Bytes      : constant := Screen_Width / 8;

   subtype Byte is A0B.Types.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte
     with Component_Size => 8;
   subtype Framebuffer is Byte_Array (0 .. Row_Bytes * Screen_Height - 1);
   type Byte_Array_Access is access constant Byte_Array;

   type Bitmap_Descriptor is record
      X, Y          : Integer;
      Width, Height : Positive;
      Data          : Byte_Array_Access;
   end record;

   function Metadata
     (Id : Nu_Pogodi.Sprites.Sprite_Id) return Bitmap_Descriptor;

   --  AND one bitmap into Buffer, clipping at screen boundaries.
   --  Does not clear Buffer. Process one individual scanline at a time.
   procedure Draw
     (Buffer : in out Framebuffer; Id : Nu_Pogodi.Sprites.Sprite_Id);

   procedure Draw
     (Buffer : in out Framebuffer; Set : Nu_Pogodi.Sprites.Sprite_Set);

   --  Fill Buffer with white and draw all 72 artwork components.
   procedure Reconstruct (Buffer : out Framebuffer);

end Nu_Pogodi.Bitmaps;
