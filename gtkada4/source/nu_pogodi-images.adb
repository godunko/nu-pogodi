--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with System;

with Glib.Error;
with Glib.Object;

package body Nu_Pogodi.Images is

   ----------
   -- Load --
   ----------

   function Load
     (Filename : String;
      Width    : Positive;
      Height   : Positive) return Gdk.Pixbuf.Gdk_Pixbuf
   is
      use type Gdk.Pixbuf.Gdk_Pixbuf;
      use type Glib.Error.GError;

      Error : Glib.Error.GError;
      Result : Gdk.Pixbuf.Gdk_Pixbuf;

   begin
      Gdk.Pixbuf.Gdk_New_From_File_At_Scale
        (Result, Filename, Glib.Gint (Width), Glib.Gint (Height), True, Error);

      if Result = null then
         if Error /= null then
            declare
               Message : constant String := Glib.Error.Get_Message (Error);

            begin
               Glib.Error.Error_Free (Error);

               raise Program_Error with Filename & ": " & Message;
            end;
         end if;

         raise Program_Error with "Cannot load " & Filename;
      end if;

      return Result;
   end Load;

   -----------------------
   -- Set_Source_Pixbuf --
   -----------------------

   procedure Set_Source_Pixbuf
     (Cr    : Cairo.Cairo_Context;
      Image : Gdk.Pixbuf.Gdk_Pixbuf;
      X     : Glib.Gdouble;
      Y     : Glib.Gdouble)
   is
      procedure Internal
        (Cr    : Cairo.Cairo_Context;
         Image : System.Address;
         X     : Glib.Gdouble;
         Y     : Glib.Gdouble)
        with Import, Convention => C,
          External_Name => "gdk_cairo_set_source_pixbuf";

   begin
      Internal (Cr, Glib.Object.Get_Object (Image), X, Y);
   end Set_Source_Pixbuf;

end Nu_Pogodi.Images;
