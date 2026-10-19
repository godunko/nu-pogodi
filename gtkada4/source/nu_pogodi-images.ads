--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Cairo;
with Gdk.Pixbuf;
with Glib;

package Nu_Pogodi.Images is

   function Load
     (Filename : String;
      Width    : Positive;
      Height   : Positive) return Gdk.Pixbuf.Gdk_Pixbuf;

   procedure Set_Source_Pixbuf
     (Cr    : Cairo.Cairo_Context;
      Image : Gdk.Pixbuf.Gdk_Pixbuf;
      X     : Glib.Gdouble;
      Y     : Glib.Gdouble);
   --  GtkAda4 does not yet expose the GDK Cairo helper.

end Nu_Pogodi.Images;
