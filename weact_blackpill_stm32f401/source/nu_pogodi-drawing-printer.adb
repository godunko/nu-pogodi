--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Types.Arrays;

package body Nu_Pogodi.Drawing.Printer is

   Rows_Per_Pass     : constant := 9;
   Columns_Per_Frame : constant := 24;
   Dot_Step          : constant := 3;
   Dot_Size          : constant := 2;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Framebuffer : in out Nu_Pogodi.Framebuffers.Framebuffer;
      Left_X      : A0B.Types.Unsigned_32;
      Top_Y       : A0B.Types.Unsigned_32;
      Bitmap      : Nu_Pogodi.Bitmaps.Bitmap_Descriptor;
      Frame       : Natural)
   is
      use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

      Width  : constant Natural := Natural (Bitmap.Width);
      Height : constant Natural := Natural (Bitmap.Height);
      Stride : constant Natural := (Width + 7) / 8;
      Passes : constant Natural :=
        (Height + Rows_Per_Pass - 1) / Rows_Per_Pass;
      Steps  : constant Natural :=
        (Width + Columns_Per_Frame - 1) / Columns_Per_Frame;
      Last   : constant Natural := Frame_Count (Bitmap);

      Storage : A0B.Types.Arrays.Unsigned_8_Array
        (0 .. Framebuffer.Stride * Framebuffer.Height - 1)
        with Import, Address => Framebuffer.Buffer.Address;

      Pass       : Natural;
      Step       : Natural;
      Printed    : Natural;
      Offset     : Natural;
      Head       : Natural;
      Head_X     : Integer;
      Head_Y     : Integer;
      Forward    : Boolean;
      Feeding    : Boolean;
      Visible    : Boolean;
      Source     : A0B.Types.Unsigned_32;
      Mask       : A0B.Types.Unsigned_8;

      procedure Pixel
        (X : Integer;
         Y : Integer);

      -----------
      -- Pixel --
      -----------

      procedure Pixel
        (X : Integer;
         Y : Integer)
      is
         Target : A0B.Types.Unsigned_32;

      begin
         if X < 0 or else Y < 0
           or else X >= Integer (Framebuffer.Width)
           or else Y >= Integer (Framebuffer.Height)
         then
            return;
         end if;

         Target := A0B.Types.Unsigned_32 (Y) * Framebuffer.Stride
           + A0B.Types.Unsigned_32 (X / 8);
         Storage (Target) := @ and not
           A0B.Types.Unsigned_8 (2 ** (7 - X mod 8));
      end Pixel;

   begin
      if Frame = 0 or else Last = 0 then
         return;
      end if;

      Pass    := (Natural'Min (Frame, Last) - 1) / (Steps + 1);
      Step    := (Natural'Min (Frame, Last) - 1) mod (Steps + 1);
      Feeding := Step = Steps;
      Forward := Pass mod 2 = 0;
      Printed := Natural'Min ((Step + 1) * Columns_Per_Frame, Width);
      Offset  := (Passes - Pass - Boolean'Pos (Feeding)) * Rows_Per_Pass;
      Head    := (if Forward then Printed else Width - Printed);

      for Row in 0 .. Natural'Min (Height, (Pass + 1) * Rows_Per_Pass) - 1
      loop
         for Column in 0 .. Width - 1 loop
            Visible := Row < Pass * Rows_Per_Pass or else Feeding
              or else (if Forward then Column < Head else Column >= Head);

            if Visible then
               Source := Bitmap.Data'First
                 + A0B.Types.Unsigned_32 (Row * Stride + Column / 8);
               Mask := A0B.Types.Unsigned_8 (2 ** (7 - Column mod 8));

               if (Bitmap.Data (Source) and Mask) /= 0 then
                  for Y in 0 .. Dot_Size - 1 loop
                     for X in 0 .. Dot_Size - 1 loop
                        Pixel
                          (Integer (Left_X) + Column * Dot_Step + X,
                           Integer (Top_Y)
                             + (Row + Offset) * Dot_Step + Y);
                     end loop;
                  end loop;
               end if;
            end if;
         end loop;
      end loop;

      if Frame < Last then
         Head_X := Integer (Left_X) + Head * Dot_Step;
         Head_Y := Integer (Top_Y) + Passes * Rows_Per_Pass * Dot_Step;

         for Y in -2 .. Rows_Per_Pass * Dot_Step + 1 loop
            Pixel (Head_X, Head_Y + Y);
         end loop;

         for X in -3 .. 3 loop
            Pixel (Head_X + X, Head_Y - 2);
            Pixel (Head_X + X, Head_Y + Rows_Per_Pass * Dot_Step + 1);
         end loop;
      end if;
   end Draw;

   -----------------
   -- Frame_Count --
   -----------------

   function Frame_Count
     (Bitmap : Nu_Pogodi.Bitmaps.Bitmap_Descriptor) return Natural
   is
      Width  : constant Natural := Natural (Bitmap.Width);
      Height : constant Natural := Natural (Bitmap.Height);

   begin
      if Width = 0 or else Height = 0 then
         return 0;
      end if;

      return ((Height + Rows_Per_Pass - 1) / Rows_Per_Pass)
        * ((Width + Columns_Per_Frame - 1) / Columns_Per_Frame + 1);
   end Frame_Count;

end Nu_Pogodi.Drawing.Printer;
