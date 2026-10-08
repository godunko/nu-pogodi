pragma Ada_2022;

with Interfaces;

package Nu_Pogodi.Bitmaps is
   --  Layout: scanlines top-to-bottom, bytes left-to-right.
   --  Each byte holds 8 horizontal pixels; bit 0 is the leftmost.
   --  Black pixels are 0; white/padding pixels are 1.
   Screen_Width   : constant := 400;
   Screen_Height  : constant := 252;
   Row_Bytes      : constant := Screen_Width / 8;

   subtype Byte is Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte
     with Component_Size => 8;
   subtype Framebuffer is Byte_Array (0 .. Row_Bytes * Screen_Height - 1);
   type Byte_Array_Access is access constant Byte_Array;

   type Bitmap_Id is
     (G4671,
      G4663,
      G4667,
      G4675,
      G4631,
      G4636,
      G4659,
      G4648,
      G4641,
      G4652,
      G4486,
      Path16,
      Path18,
      Path20,
      Path22,
      Path30,
      Path32,
      Path34,
      Path36,
      Path38,
      Path42,
      Path44,
      Path48,
      Path50,
      Path54,
      Path56,
      Path58,
      Path66,
      Path68,
      Path72,
      Path80,
      Path82,
      Path84,
      Path88,
      Path90,
      Path92,
      Path98,
      Path100,
      Path102,
      Path108,
      Path110,
      Path112,
      Path118,
      Path122,
      Path124,
      Path132,
      Path134,
      Path136,
      Path138,
      Path148,
      Path150,
      Path156,
      Path160,
      Path162,
      Path168,
      Path176,
      Path178,
      Path190,
      Path202,
      Path208,
      Path34_8_63,
      Path56_3_64,
      Path44_0_65,
      Path44_0_1_66,
      Path150_4_67,
      Path164,
      Path14,
      Path10_3_70,
      Path30_8_71,
      Path168_3_72,
      Path166,
      Path16_9_74);

   type Bitmap_Descriptor is record
      X, Y          : Integer;
      Width, Height : Positive;
      Data          : Byte_Array_Access;
   end record;

   function Metadata (Id : Bitmap_Id) return Bitmap_Descriptor;

   --  AND one bitmap into Buffer, clipping at screen boundaries.
   --  Does not clear Buffer. Process one individual scanline at a time.
   procedure Draw (Buffer : in out Framebuffer; Id : Bitmap_Id);

   --  Fill Buffer with white and draw all 72 artwork components.
   procedure Reconstruct (Buffer : out Framebuffer);
end Nu_Pogodi.Bitmaps;
