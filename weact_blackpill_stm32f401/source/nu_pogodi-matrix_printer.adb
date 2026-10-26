--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Drawing;

package body Nu_Pogodi.Matrix_Printer is

   Dot_Step          : constant := 3;
   Dot_Size          : constant := 2;

   Rows_Per_Pass     : constant := 9;
   --  Number of printer needles, shared by drawing and sound generation.
   Columns_Per_Frame : constant := 24;

   type Needle_Mask is mod 2 ** Rows_Per_Pass;

   type Needle_Mask_Array is
     array (Natural range 0 .. Columns_Per_Frame - 1) of Needle_Mask;

   procedure Read_Needles
     (Bitmap : Nu_Pogodi.Bitmaps.Bitmap_Descriptor;
      Frame  : Positive;
      Masks  : out Needle_Mask_Array;
      Count  : out Natural);
   --  Read the columns printed in this frame, in carriage travel order.
   --  Bit 0 is the top needle. Count = 0 denotes a paper feed frame.

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

   procedure Generate_Sound
     (Bitmap  : Nu_Pogodi.Bitmaps.Bitmap_Descriptor;
      Frame   : Positive;
      Samples : out Nu_Pogodi.Hardware.Sound.Sample_Array)
   is
      use type A0B.Types.Unsigned_32;

      function PWM_Sample
        (Frequency : Positive;
         Divisor   : Positive) return Nu_Pogodi.Hardware.Sound.Sample;

      ----------------
      -- PWM_Sample --
      ----------------

      function PWM_Sample
        (Frequency : Positive;
         Divisor   : Positive) return Nu_Pogodi.Hardware.Sound.Sample
      is
         Period : constant Positive := 1_000_000 / Frequency;

      begin
         return
           (ARR    => A0B.Types.Unsigned_16 (Period - 1),
            CCR1   => A0B.Types.Unsigned_16 (Period / Divisor),
            others => <>);
      end PWM_Sample;

      Columns : Needle_Mask_Array;
      Count   : Natural;
      Index   : Natural := 0;

   begin
      Read_Needles (Bitmap, Frame, Columns, Count);

      if Count = 0 then
         for J in Samples'Range loop
            Samples (J) := PWM_Sample (550 + (J * 7) mod 250, 3);
         end loop;

      else
         for Column in 0 .. Count - 1 loop
            for S in 0 .. Samples'Length / Count - 1 loop
               declare
                  Mask : constant A0B.Types.Unsigned_32 :=
                    A0B.Types.Unsigned_32 (Columns (Column));
                  Frequency : constant Positive :=
                    (if Mask = 0 then 300 + S mod 25
                     else 1_600 + Natural
                       ((Mask * 37 + A0B.Types.Unsigned_32 (S) * 65)
                          mod 1_600));

               begin
                  Samples (Index) :=
                    PWM_Sample (Frequency, (if Mask = 0 then 2 else 6));
                  Index := @ + 1;
               end;
            end loop;
         end loop;

         while Index < Samples'Length loop
            Samples (Index) := PWM_Sample (300, 2);
            Index := @ + 1;
         end loop;
      end if;
   end Generate_Sound;

   ------------------
   -- Read_Needles --
   ------------------

   procedure Read_Needles
     (Bitmap : Nu_Pogodi.Bitmaps.Bitmap_Descriptor;
      Frame  : Positive;
      Masks  : out Needle_Mask_Array;
      Count  : out Natural)
   is
      use type A0B.Types.Unsigned_8;
      use type A0B.Types.Unsigned_32;

      Width  : constant Natural := Natural (Bitmap.Width);
      Height : constant Natural := Natural (Bitmap.Height);
      Stride : constant Natural := (Width + 7) / 8;
      Steps  : constant Natural :=
        (Width + Columns_Per_Frame - 1) / Columns_Per_Frame;
      Last   : constant Natural := Frame_Count (Bitmap);
      Pass   : Natural;
      Step   : Natural;
      Column : Natural;
      Row    : Natural;
      Source : A0B.Types.Unsigned_32;
      Bit    : Needle_Mask;

   begin
      Masks := [others => 0];
      Count := 0;

      if Last = 0 or else Frame > Last then
         return;
      end if;

      Pass := (Frame - 1) / (Steps + 1);
      Step := (Frame - 1) mod (Steps + 1);

      if Step = Steps then
         return;
      end if;

      Count :=
        Natural'Min (Columns_Per_Frame, Width - Step * Columns_Per_Frame);

      for J in 0 .. Count - 1 loop
         Column :=
           (if Pass mod 2 = 0 then Step * Columns_Per_Frame + J
            else Width - 1 - Step * Columns_Per_Frame - J);
         Bit := 1;

         for Pin in 0 .. Rows_Per_Pass - 1 loop
            Row := Pass * Rows_Per_Pass + Pin;
            exit when Row >= Height;

            Source := Bitmap.Data'First
              + A0B.Types.Unsigned_32 (Row * Stride + Column / 8);

            if (Bitmap.Data (Source)
                and A0B.Types.Unsigned_8 (2 ** (7 - Column mod 8))) /= 0
            then
               Masks (J) := @ or Bit;
            end if;

            Bit := @ + @;
         end loop;
      end loop;
   end Read_Needles;

end Nu_Pogodi.Matrix_Printer;
