--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Nu_Pogodi.Drawing;

package body Nu_Pogodi.Matrix_Printer is

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
                  Nu_Pogodi.Drawing.Fill_Rectangle
                    (Framebuffer => Framebuffer,
                     Left        => Left_X
                       + A0B.Types.Unsigned_32 (Column * Dot_Step),
                     Top         => Top_Y
                       + A0B.Types.Unsigned_32 ((Row + Offset) * Dot_Step),
                     Width       => Dot_Size,
                     Height      => Dot_Size,
                     Color       => Nu_Pogodi.Drawing.Black);
               end if;
            end if;
         end loop;
      end loop;

      if Frame < Last then
         Head_X := Integer (Left_X) + Head * Dot_Step;
         Head_Y := Integer (Top_Y) + Passes * Rows_Per_Pass * Dot_Step;

         Nu_Pogodi.Drawing.Fill_Rectangle
           (Framebuffer => Framebuffer,
            Left        => A0B.Types.Unsigned_32 (Head_X),
            Top         => A0B.Types.Unsigned_32 (Head_Y - 2),
            Width       => 1,
            Height      => Rows_Per_Pass * Dot_Step + 4,
            Color       => Nu_Pogodi.Drawing.Black);
         Nu_Pogodi.Drawing.Fill_Rectangle
           (Framebuffer => Framebuffer,
            Left        => A0B.Types.Unsigned_32 (Head_X - 3),
            Top         => A0B.Types.Unsigned_32 (Head_Y - 2),
            Width       => 7,
            Height      => 1,
            Color       => Nu_Pogodi.Drawing.Black);
         Nu_Pogodi.Drawing.Fill_Rectangle
           (Framebuffer => Framebuffer,
            Left        => A0B.Types.Unsigned_32 (Head_X - 3),
            Top         => A0B.Types.Unsigned_32
              (Head_Y + Rows_Per_Pass * Dot_Step + 1),
            Width       => 7,
            Height      => 1,
            Color       => Nu_Pogodi.Drawing.Black);
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

end Nu_Pogodi.Matrix_Printer;
