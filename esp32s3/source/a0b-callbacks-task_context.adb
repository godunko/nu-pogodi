--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

pragma Ada_2022;

package body A0B.Callbacks.Task_Context is

   type Element_Index is mod 4;

   type Callback_Array is array (Element_Index) of Callback;

   task Dispatcher;

   protected Queue is

      procedure Enqueue (Self : Callback);

      entry Dequeue (Self : out Callback);

   private

      Storage : Callback_Array;
      Head    : Element_Index := 0;
      Tail    : Element_Index := 0;

   end Queue;

   ----------------
   -- Dispatcher --
   ----------------

   task body Dispatcher is
      Item : aliased Callback;

   begin
      loop
         Queue.Dequeue (Item);
         A0B.Callbacks.Emit_Once (Item);
      end loop;
   end Dispatcher;

   ----------
   -- Emit --
   ----------

   procedure Emit (Self : Callback) is
   begin
      Queue.Enqueue (Self);
   end Emit;

   ---------------
   -- Emit_Once --
   ---------------

   procedure Emit_Once (Self : aliased in out Callback) is
      Saved : Callback;

   begin
      Take (Self, Saved);
      Unset (Self);
      Queue.Enqueue (Saved);
   end Emit_Once;

   -----------
   -- Queue --
   -----------

   protected body Queue is

      -------------
      -- Enqueue --
      -------------

      procedure Enqueue (Self : Callback) is
      begin
         Storage (Tail) := Self;
         Tail := @ + 1;
      end Enqueue;

      -------------
      -- Dequeue --
      -------------

      entry Dequeue (Self : out Callback) when Head /= Tail is
      begin
         Self := Storage (Head);
         Unset (Storage (Head));
         Head := @ + 1;
      end Dequeue;

   end Queue;

end A0B.Callbacks.Task_Context;