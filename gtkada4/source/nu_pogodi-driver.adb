--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;

with Nu_Pogodi.Desktop;

procedure Nu_Pogodi.Driver is
begin
   Nu_Pogodi.Desktop.Run;

exception
   when Error : others =>
      Ada.Text_IO.Put_Line
        (Ada.Text_IO.Standard_Error,
         Ada.Exceptions.Exception_Information (Error));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Nu_Pogodi.Driver;
