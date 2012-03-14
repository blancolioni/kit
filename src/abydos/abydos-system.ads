with Abydos.Environments;
with Abydos.Values;

package Abydos.System is

   type System_Program is
     new Abydos.Environments.Evaluable with private;

   overriding
   function Evaluate (Item : System_Program;
                      Args : Values.Array_Of_Values;
                      Env  : Environments.Environment'Class)
                      return Values.Value;

   procedure Initialise (Top : Environments.Environment);

private

   type System_Executor is
     access function (Args : Values.Array_Of_Values;
                      Env  : Environments.Environment'Class)
                      return Values.Value;

   type System_Program is
     new Abydos.Environments.Evaluable with
      record
         Exec : System_Executor;
      end record;

end Abydos.System;


