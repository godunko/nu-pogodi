--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with A0B.Buffers;
with A0B.Types;

package Nu_Pogodi.Framebuffers is

   type Framebuffer is limited record
      Buffer : access A0B.Buffers.Abstract_Buffer'Class;
      Width  : A0B.Types.Unsigned_32;
      Height : A0B.Types.Unsigned_32;
      Stride : A0B.Types.Unsigned_32;
   end record;

end Nu_Pogodi.Framebuffers;
