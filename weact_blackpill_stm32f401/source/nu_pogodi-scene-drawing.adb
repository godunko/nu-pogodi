--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

package body Nu_Pogodi.Scene.Drawing is

   Left_Top_Egg : constant
     array (Lane_Side, Lane_Height, Egg_Step) of Nu_Pogodi.Bitmaps.Bitmap_Id :=
     [Left =>
        [Top =>
           [Nu_Pogodi.Bitmaps.Path90,
            Nu_Pogodi.Bitmaps.Path98,
            Nu_Pogodi.Bitmaps.Path102,
            Nu_Pogodi.Bitmaps.Path112,
            Nu_Pogodi.Bitmaps.Path124],
         Bottom =>
           [Nu_Pogodi.Bitmaps.Path132,
            Nu_Pogodi.Bitmaps.Path136,
            Nu_Pogodi.Bitmaps.Path148,
            Nu_Pogodi.Bitmaps.Path156,
            Nu_Pogodi.Bitmaps.Path176]],
      Right =>
        [Top =>
           [Nu_Pogodi.Bitmaps.Path88,
            Nu_Pogodi.Bitmaps.Path92,
            Nu_Pogodi.Bitmaps.Path100,
            Nu_Pogodi.Bitmaps.Path110,
            Nu_Pogodi.Bitmaps.Path122],
         Bottom =>
           [Nu_Pogodi.Bitmaps.Path134,
            Nu_Pogodi.Bitmaps.Path138,
            Nu_Pogodi.Bitmaps.Path150,
            Nu_Pogodi.Bitmaps.Path160,
            Nu_Pogodi.Bitmaps.Path178]]];

   ----------
   -- Draw --
   ----------

   procedure Draw (Framebuffer : in out Nu_Pogodi.Bitmaps.Framebuffer) is
   begin
      case Wolf.Side is
         when Left =>
            Nu_Pogodi.Bitmaps.Draw (Framebuffer, Nu_Pogodi.Bitmaps.Path14);

            case Wolf.Height is
               when Top =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Bitmaps.Path108);

               when Bottom =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Bitmaps.Path162);
            end case;

         when Right =>
            Nu_Pogodi.Bitmaps.Draw
              (Framebuffer, Nu_Pogodi.Bitmaps.Path10_3_70);

            case Wolf.Height is
               when Top =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Bitmaps.Path118);

               when Bottom =>
                  Nu_Pogodi.Bitmaps.Draw
                    (Framebuffer, Nu_Pogodi.Bitmaps.Path168);
            end case;
      end case;

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

      --  Nu_Pogodi.Bitmaps.Reconstruct (Framebuffer);
   end Draw;

end Nu_Pogodi.Scene.Drawing;
