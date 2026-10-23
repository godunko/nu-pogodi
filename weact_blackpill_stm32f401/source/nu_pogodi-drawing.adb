--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Buffers;
with A0B.Types.Arrays;

package body Nu_Pogodi.Drawing is

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
