--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

with Nu_Pogodi.Sprites;

package body Nu_Pogodi.Scene.Drawing is

   Left_Top_Egg : constant
     array (Lane_Side, Lane_Height, Egg_Step) of Nu_Pogodi.Sprites.Sprite_Id :=
     [Left =>
        [Top =>
           [Nu_Pogodi.Sprites.Path90,
            Nu_Pogodi.Sprites.Path98,
            Nu_Pogodi.Sprites.Path102,
            Nu_Pogodi.Sprites.Path112,
            Nu_Pogodi.Sprites.Path124],
         Bottom =>
           [Nu_Pogodi.Sprites.Path132,
            Nu_Pogodi.Sprites.Path136,
            Nu_Pogodi.Sprites.Path148,
            Nu_Pogodi.Sprites.Path156,
            Nu_Pogodi.Sprites.Path176]],
      Right =>
        [Top =>
           [Nu_Pogodi.Sprites.Path88,
            Nu_Pogodi.Sprites.Path92,
            Nu_Pogodi.Sprites.Path100,
            Nu_Pogodi.Sprites.Path110,
            Nu_Pogodi.Sprites.Path122],
         Bottom =>
           [Nu_Pogodi.Sprites.Path134,
            Nu_Pogodi.Sprites.Path138,
            Nu_Pogodi.Sprites.Path150,
            Nu_Pogodi.Sprites.Path160,
            Nu_Pogodi.Sprites.Path178]]];

   type Indicator_Segment is
     (Top, Left_Top, Right_Top, Middle, Left_Bottom, Right_Bottom, Bottom);

   type Segment_Bitmap is
     array (Indicator_Segment) of Nu_Pogodi.Sprites.Sprite_Id;

   type Segments_State is array (Indicator_Segment) of Boolean;

   Digit_Segments : constant array (Score_Digit) of Segments_State :=
     [0 =>
        [Top          => True,
         Left_Top     => True,
         Right_Top    => True,
         Middle       => False,
         Left_Bottom  => True,
         Right_Bottom => True,
         Bottom       => True],
      1 =>
        [Top          => False,
         Left_Top     => False,
         Right_Top    => True,
         Middle       => False,
         Left_Bottom  => False,
         Right_Bottom => True,
         Bottom       => False],
      2 =>
        [Top          => True,
         Left_Top     => False,
         Right_Top    => True,
         Middle       => True,
         Left_Bottom  => True,
         Right_Bottom => False,
         Bottom       => True],
      3 =>
        [Top          => True,
         Left_Top     => False,
         Right_Top    => True,
         Middle       => True,
         Left_Bottom  => False,
         Right_Bottom => True,
         Bottom       => True],
      4 =>
        [Top          => False,
         Left_Top     => True,
         Right_Top    => True,
         Middle       => True,
         Left_Bottom  => False,
         Right_Bottom => True,
         Bottom       => False],
      5 =>
        [Top          => True,
         Left_Top     => True,
         Right_Top    => False,
         Middle       => True,
         Left_Bottom  => False,
         Right_Bottom => True,
         Bottom       => True],
      6 =>
        [Top          => True,
         Left_Top     => True,
         Right_Top    => False,
         Middle       => True,
         Left_Bottom  => True,
         Right_Bottom => True,
         Bottom       => True],
      7 =>
        [Top          => True,
         Left_Top     => False,
         Right_Top    => True,
         Middle       => False,
         Left_Bottom  => False,
         Right_Bottom => True,
         Bottom       => False],
      8 =>
        [Top          => True,
         Left_Top     => True,
         Right_Top    => True,
         Middle       => True,
         Left_Bottom  => True,
         Right_Bottom => True,
         Bottom       => True],
      9 =>
        [Top          => True,
         Left_Top     => True,
         Right_Top    => True,
         Middle       => True,
         Left_Bottom  => False,
         Right_Bottom => True,
         Bottom       => True]];

   Indicator_0 : constant Segment_Bitmap :=
     [Top          => Nu_Pogodi.Sprites.Path22,
      Left_Top     => Nu_Pogodi.Sprites.Path38,
      Right_Top    => Nu_Pogodi.Sprites.Path36,
      Middle       => Nu_Pogodi.Sprites.Path44_0_1_66,
      Left_Bottom  => Nu_Pogodi.Sprites.Path54,
      Right_Bottom => Nu_Pogodi.Sprites.Path58,
      Bottom       => Nu_Pogodi.Sprites.Path72];
   Indicator_1 : constant Segment_Bitmap :=
     [Top          => Nu_Pogodi.Sprites.Path20,
      Left_Top     => Nu_Pogodi.Sprites.Path34,
      Right_Top    => Nu_Pogodi.Sprites.Path30,
      Middle       => Nu_Pogodi.Sprites.Path44_0_65,
      Left_Bottom  => Nu_Pogodi.Sprites.Path50,
      Right_Bottom => Nu_Pogodi.Sprites.Path56,
      Bottom       => Nu_Pogodi.Sprites.Path68];
   Indicator_2 : constant Segment_Bitmap :=
     [Top          => Nu_Pogodi.Sprites.Path18,
      Left_Top     => Nu_Pogodi.Sprites.Path34_8_63,
      Right_Top    => Nu_Pogodi.Sprites.Path32,
      Middle       => Nu_Pogodi.Sprites.Path44,
      Left_Bottom  => Nu_Pogodi.Sprites.Path48,
      Right_Bottom => Nu_Pogodi.Sprites.Path56_3_64,
      Bottom       => Nu_Pogodi.Sprites.Path66];

   ----------
   -- Draw --
   ----------

   procedure Draw (Framebuffer : in out Nu_Pogodi.Bitmaps.Framebuffer) is

      use type A0B.Types.Unsigned_32;

      procedure Draw_Digit
        (Value     : Score_Digit;
         Indicator : Segment_Bitmap);

      ----------------
      -- Draw_Digit --
      ----------------

      procedure Draw_Digit
        (Value     : Score_Digit;
         Indicator : Segment_Bitmap) is
      begin
         for Segment in Indicator_Segment loop
            if Digit_Segments (Value) (Segment) then
               Nu_Pogodi.Bitmaps.Draw (Framebuffer, Indicator (Segment));
            end if;
         end loop;
      end Draw_Digit;

      Even_Cycle : constant Boolean := (State.Current_Cycle mod 2) = 0;

   begin
      case Wolf.Side is
         when Left =>
            Nu_Pogodi.Bitmaps.Draw (Framebuffer, Nu_Pogodi.Sprites.Path14);

            case Wolf.Height is
               when Top =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Sprites.Path108);

               when Bottom =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Sprites.Path162);
            end case;

         when Right =>
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer, Nu_Pogodi.Sprites.Path10_3_70);

            case Wolf.Height is
               when Top =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Sprites.Path118);

               when Bottom =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Sprites.Path168);
            end case;
      end case;

      --  Eggs on lanes

      for Side in Lane_Side loop
         for Height in Lane_Height loop
            for Step in Egg_Step loop
               if Lanes (Side, Height) (Step) then
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Left_Top_Egg (Side, Height, Step));
               end if;
            end loop;
         end loop;
      end loop;

      --  Score

      Draw_Digit (State.Current_Score mod 10, Indicator_0);

      if (State.Current_Score / 10) /= 0 then
         Draw_Digit (Tens (State.Current_Score), Indicator_1);
      end if;

      if (State.Current_Score / 100) /= 0 then
         Draw_Digit (Hundreds (State.Current_Score), Indicator_2);
      end if;

      --  Chick

      case State.Miss_Animation_Cycle is
         when 0 =>
            null;

         when 1 =>
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer,
               (case State.Miss_Animation_Side is
                   when Left  => Nu_Pogodi.Sprites.Path30_8_71,
                   when Right => Nu_Pogodi.Sprites.Path150_4_67));

         when 2 =>
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer,
               (case State.Miss_Animation_Side is
                   when Left  => Nu_Pogodi.Sprites.Path166,
                   when Right => Nu_Pogodi.Sprites.Path190));

         when 3 =>
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer,
               (case State.Miss_Animation_Side is
                   when Left  => Nu_Pogodi.Sprites.Path168_3_72,
                   when Right => Nu_Pogodi.Sprites.Path164));

         when 4 =>
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer,
               (case State.Miss_Animation_Side is
                   when Left  => Nu_Pogodi.Sprites.G4631,
                   when Right => Nu_Pogodi.Sprites.G4636));
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer,
               (case State.Miss_Animation_Side is
                   when Left  => Nu_Pogodi.Sprites.G4659,
                   when Right => Nu_Pogodi.Sprites.G4648));
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer,
               (case State.Miss_Animation_Side is
                   when Left  => Nu_Pogodi.Sprites.Path202,
                   when Right => Nu_Pogodi.Sprites.Path208));

         when others =>
            raise Program_Error;
      end case;

      --  Rabbit

      if State.Rabbit_Visible then
         Nu_Pogodi.Bitmaps.Draw (Framebuffer, Nu_Pogodi.Sprites.Path16_9_74);
      end if;

      --  Miss count

      if State.Miss_Count > 0
        and (State.Miss_Count /= 1 or not State.Miss_Half or Even_Cycle)
      then
         Nu_Pogodi.Bitmaps.Draw (Framebuffer, Nu_Pogodi.Sprites.Path80);
      end if;

      if State.Miss_Count > 1
        and (State.Miss_Count /= 2 or not State.Miss_Half or Even_Cycle)
      then
         Nu_Pogodi.Bitmaps.Draw (Framebuffer, Nu_Pogodi.Sprites.Path84);
      end if;

      if State.Miss_Count > 2
        and (State.Miss_Count /= 3 or not State.Miss_Half or Even_Cycle)
      then
         Nu_Pogodi.Bitmaps.Draw (Framebuffer, Nu_Pogodi.Sprites.Path82);
      end if;

      --  Nu_Pogodi.Bitmaps.Reconstruct (Framebuffer);
   end Draw;

end Nu_Pogodi.Scene.Drawing;
