--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Buffers;
with A0B.Types.Arrays;

package body Nu_Pogodi.Drawing is

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      X           : A0B.Types.Unsigned_32;
      Y           : A0B.Types.Unsigned_32;
      Bitmap      : Nu_Pogodi.Bitmaps.Bitmap_Descriptor)
   is
      use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

      Bitmap_Row_Bytes : constant A0B.Types.Unsigned_32 := Bitmap.Width / 8;

      Storage     : A0B.Types.Arrays.Unsigned_8_Array
        (0 .. Framebuffer.Stride * Framebuffer.Height - 1)
        with Import, Address => Framebuffer.Buffer.Address;

      Screen_Y    : A0B.Types.Unsigned_32;
      Screen_Byte : A0B.Types.Unsigned_32;
      Target      : A0B.Types.Unsigned_32;
      Source      : A0B.Types.Unsigned_32;

   begin
      for Row in 0 .. Bitmap.Height - 1 loop
         Screen_Y := Y + Row;

         exit when Framebuffer.Height <= Screen_Y;

         for Column in 0 .. Bitmap_Row_Bytes - 1 loop
            Screen_Byte := X / 8 + Column;

            exit when Framebuffer.Stride <= Screen_Byte;

            Target := Screen_Y * Framebuffer.Stride + Screen_Byte;
            Source := Row * Bitmap_Row_Bytes + Column;

            Storage (Target) := @ and Bitmap.Data (Source);
         end loop;
      end loop;
   end Draw;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      X           : A0B.Types.Unsigned_32;
      Y           : A0B.Types.Unsigned_32;
      Bitmap      : Nu_Pogodi.Bitmaps.RLE_Bitmap_Descriptor)
   is
      use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

      Bitmap_Row_Bytes : constant A0B.Types.Unsigned_32 := Bitmap.Width / 8;

      Storage     : A0B.Types.Arrays.Unsigned_8_Array
        (0 .. Framebuffer.Stride * Framebuffer.Height - 1)
        with Import, Address => Framebuffer.Buffer.Address;

      Source      : A0B.Types.Unsigned_32 := Bitmap.Data'First;
      Remaining   : A0B.Types.Unsigned_32 := 0;
      Literal     : Boolean := False;
      Value       : A0B.Types.Unsigned_8  := 0;
      Control     : A0B.Types.Unsigned_32;
      Screen_Y    : A0B.Types.Unsigned_32;
      Screen_Byte : A0B.Types.Unsigned_32;
      Target      : A0B.Types.Unsigned_32;

   begin
      if Bitmap_Row_Bytes = 0 or else Bitmap.Height = 0 then
         return;
      end if;

      for Row in 0 .. Bitmap.Height - 1 loop
         Screen_Y := Y + Row;

         exit when Framebuffer.Height <= Screen_Y;

         for Column in 0 .. Bitmap_Row_Bytes - 1 loop
            if Remaining = 0 then
               Control := A0B.Types.Unsigned_32 (Bitmap.Data (Source));
               Source  := @ + 1;
               Literal := Control < 128;

               if Literal then
                  Remaining := Control + 1;

               else
                  Remaining := Control - 128 + 3;
                  Value     := Bitmap.Data (Source);
                  Source    := @ + 1;
               end if;
            end if;

            if Literal then
               Value  := Bitmap.Data (Source);
               Source := @ + 1;
            end if;

            Remaining   := @ - 1;
            Screen_Byte := X / 8 + Column;

            --  Consume clipped bytes to keep the following rows in sync.

            if Screen_Byte < Framebuffer.Stride then
               Target := Screen_Y * Framebuffer.Stride + Screen_Byte;
               Storage (Target) := @ and Value;
            end if;
         end loop;
      end loop;
   end Draw;

   ----------
   -- Fill --
   ----------

   procedure Fill (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer) is
      use type A0B.Types.Unsigned_32;

      Storage : A0B.Types.Arrays.Unsigned_8_Array
        (0 .. Framebuffer.Height * Framebuffer.Stride - 1)
        with Import, Address => A0B.Buffers.Address (Framebuffer.Buffer.all);

   begin
      Storage := [others => 16#FF#];
   end Fill;

   --------------------
   -- Fill_Rectangle --
   --------------------

   procedure Fill_Rectangle
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Left        : A0B.Types.Unsigned_32;
      Top         : A0B.Types.Unsigned_32;
      Width       : A0B.Types.Unsigned_32;
      Height      : A0B.Types.Unsigned_32;
      Color       : Color_Type)
   is
      use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

      Right      : constant A0B.Types.Unsigned_32 := Left + Width;
      First_Byte : constant A0B.Types.Unsigned_32 := Left / 8;
      Last_Byte  : constant A0B.Types.Unsigned_32 := (Right - 1) / 8;
      First_Mask : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Shift_Right (16#FF#, Natural (Left mod 8));
      Last_Mask  : constant A0B.Types.Unsigned_8 :=
        A0B.Types.Shift_Left
          (16#FF#, Natural (7 - (Right - 1) mod 8));
      Value      : constant A0B.Types.Unsigned_8 :=
        (if Color = Black then 16#00# else 16#FF#);

      Mask    : A0B.Types.Unsigned_8;
      Target  : A0B.Types.Unsigned_32;

      Storage : A0B.Types.Arrays.Unsigned_8_Array
        (0 .. Framebuffer.Stride * Framebuffer.Height - 1)
        with Import, Address => Framebuffer.Buffer.Address;

   begin
      for Row in Top .. Top + Height - 1 loop
         for Column in First_Byte .. Last_Byte loop
            Mask := 16#FF#;

            if Column = First_Byte then
               Mask := @ and First_Mask;
            end if;

            if Column = Last_Byte then
               Mask := @ and Last_Mask;
            end if;

            Target := Row * Framebuffer.Stride + Column;
            Storage (Target) := (@ and not Mask) or (Value and Mask);
         end loop;
      end loop;
   end Fill_Rectangle;

end Nu_Pogodi.Drawing;
