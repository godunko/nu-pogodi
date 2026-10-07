--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with A0B.Types;

with Nu_Pogodi.Hardware.RTC;

package body Nu_Pogodi.Clock is

   type Frame_Buffer is
     array (A0B.Types.Unsigned_32 range 0 .. 299,
            A0B.Types.Unsigned_32 range 0 .. 49)
       of aliased A0B.Types.Unsigned_8
     with Size => 400 * 300, Component_Size => 8;

   type Display_Cell_Content is
     array (A0B.Types.Unsigned_32 range 0 .. 7) of A0B.Types.Unsigned_8;

   Digit_0 : constant Display_Cell_Content :=
     [16#7C#, 16#C6#, 16#CE#, 16#DE#, 16#F6#, 16#E6#, 16#7C#, 16#00#];
   Digit_1 : constant Display_Cell_Content :=
     [16#30#, 16#70#, 16#30#, 16#30#, 16#30#, 16#30#, 16#FC#, 16#00#];
   Digit_2 : constant Display_Cell_Content :=
     [16#78#, 16#CC#, 16#0C#, 16#38#, 16#60#, 16#CC#, 16#FC#, 16#00#];
   Digit_3 : constant Display_Cell_Content :=
     [16#78#, 16#CC#, 16#0C#, 16#38#, 16#0C#, 16#CC#, 16#78#, 16#00#];
   Digit_4 : constant Display_Cell_Content :=
     [16#1C#, 16#3C#, 16#6C#, 16#CC#, 16#FE#, 16#0C#, 16#1E#, 16#00#];
   Digit_5 : constant Display_Cell_Content :=
     [16#FC#, 16#C0#, 16#F8#, 16#0C#, 16#0C#, 16#CC#, 16#78#, 16#00#];
   Digit_6 : constant Display_Cell_Content :=
     [16#38#, 16#60#, 16#C0#, 16#F8#, 16#CC#, 16#CC#, 16#78#, 16#00#];
   Digit_7 : constant Display_Cell_Content :=
     [16#FC#, 16#CC#, 16#0C#, 16#18#, 16#30#, 16#30#, 16#30#, 16#00#];
   Digit_8 : constant Display_Cell_Content :=
     [16#78#, 16#CC#, 16#CC#, 16#78#, 16#CC#, 16#CC#, 16#78#, 16#00#];
   Digit_9 : constant Display_Cell_Content :=
     [16#78#, 16#CC#, 16#CC#, 16#7C#, 16#0C#, 16#18#, 16#70#, 16#00#];
   Digit_Colon : constant Display_Cell_Content :=
     [16#00#, 16#30#, 16#30#, 16#00#, 16#00#, 16#30#, 16#30#, 16#00#];

   ----------
   -- Draw --
   ----------

   procedure Draw (Buffer : in out A0B.Buffers.Abstract_Buffer'Class) is
      use type A0B.Types.Unsigned_32;

      T : constant Nu_Pogodi.Hardware.RTC.Time := Nu_Pogodi.Hardware.RTC.Clock;

      F : Frame_Buffer with Import, Address => Buffer.Address;

      procedure Draw
        (X     : A0B.Types.Unsigned_32;
         Y     : A0B.Types.Unsigned_32;
         Glyph : Display_Cell_Content);

      procedure Draw
        (X     : A0B.Types.Unsigned_32;
         Y     : A0B.Types.Unsigned_32;
         Value : A0B.Types.Unsigned_8);

      ----------
      -- Draw --
      ----------

      procedure Draw
        (X     : A0B.Types.Unsigned_32;
         Y     : A0B.Types.Unsigned_32;
         Glyph : Display_Cell_Content)
      is
         use type A0B.Types.Unsigned_8;

      begin
         for J in Glyph'Range loop
            F (Y + J, X) := not Glyph (J);
         end loop;
      end Draw;

      ----------
      -- Draw --
      ----------

      procedure Draw
        (X     : A0B.Types.Unsigned_32;
         Y     : A0B.Types.Unsigned_32;
         Value : A0B.Types.Unsigned_8) is
      begin
         case Value is
            when 0      => Draw (X, Y, Digit_0);
            when 1      => Draw (X, Y, Digit_1);
            when 2      => Draw (X, Y, Digit_2);
            when 3      => Draw (X, Y, Digit_3);
            when 4      => Draw (X, Y, Digit_4);
            when 5      => Draw (X, Y, Digit_5);
            when 6      => Draw (X, Y, Digit_6);
            when 7      => Draw (X, Y, Digit_7);
            when 8      => Draw (X, Y, Digit_8);
            when 9      => Draw (X, Y, Digit_9);
            when others => raise Program_Error;
         end case;
      end Draw;

   begin
      for J in F'Range (2) loop
         F (F'Last (1) - 10, J) := 16#00#;
      end loop;

      Draw (25, F'Last (1) - 8, A0B.Types.Unsigned_8 (T.Hours_Tens));
      Draw (26, F'Last (1) - 8, A0B.Types.Unsigned_8 (T.Hours_Ones));

      Draw (28, F'Last (1) - 8, A0B.Types.Unsigned_8 (T.Minutes_Tens));
      Draw (29, F'Last (1) - 8, A0B.Types.Unsigned_8 (T.Minutes_Ones));

      Draw (31, F'Last (1) - 8, A0B.Types.Unsigned_8 (T.Seconds_Tens));
      Draw (32, F'Last (1) - 8, A0B.Types.Unsigned_8 (T.Seconds_Ones));

      if A0B.Types.Unsigned_32 (T.Seconds_Ones) mod 2 = 0 then
         Draw (27, F'Last (1) - 8, Digit_Colon);
         Draw (30, F'Last (1) - 8, Digit_Colon);
      end if;
   end Draw;

end Nu_Pogodi.Clock;
