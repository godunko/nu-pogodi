--
--  Copyright (C) 2026, Vadim Godunko <vgodunko@gmail.com>
--
--  SPDX-License-Identifier: GPL-3.0-or-later
--

--  This package provides callback mechanisms to execute callback
--  asynchronously in task context. It is designed to redirect callback
--  execution from interrupt context to the appropriate task context.

package A0B.Callbacks.Task_Context is

   procedure Emit (Self : Callback);
   --  Call the callback subprogram when it is set. Exceptions propagated by
   --  the callback subprogram are caught and ignored.

   procedure Emit_Once (Self : aliased in out Callback);
   --  Clear the callback object and invoke the saved callback subprogram. The
   --  callback subprogram may register a new callback during the call.

end A0B.Callbacks.Task_Context;