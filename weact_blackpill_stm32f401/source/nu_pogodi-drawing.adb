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
         Screen_Y := Bitmap.Y + Row;

         exit when Framebuffer.Height <= Screen_Y;

         for Column in 0 .. Bitmap_Row_Bytes - 1 loop
            Screen_Byte := Bitmap.X / 8 + Column;

            exit when Framebuffer.Stride <= Screen_Byte;

            Target := Screen_Y * Framebuffer.Stride + Screen_Byte;
            Source := Row * Bitmap_Row_Bytes + Column;

            Storage (Target) := @ and Bitmap.Data (Source);
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
      Storage := (others => 16#FF#);
   end Fill;

end Nu_Pogodi.Drawing;
