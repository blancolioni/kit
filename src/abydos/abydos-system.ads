private with Ada.Containers.Indefinite_Vectors;

with Abydos.Environments;
with Abydos.Values;

package Abydos.System is

   type System_Program is
     new Abydos.Environments.Evaluable with private;

   overriding
   function Evaluate (Item : System_Program;
                      Args : Environments.Argument_List'Class;
                      Env  : Environments.Environment'Class)
                      return Values.Value;

   overriding
   function Formal_Argument_Count (Item : System_Program) return Natural;

   overriding
   function Formal_Argument_Name (Item : System_Program;
                                  Index : Positive)
                                  return String;

   procedure Initialise (Top : Environments.Environment);

private

   type System_Executor is
     access function (Args : Environments.Argument_List'Class;
                      Env  : Environments.Environment'Class)
                      return Values.Value;

   package Formal_Argument_Vectors is
     new Ada.Containers.Indefinite_Vectors (Positive, String);

   type System_Program is
     new Abydos.Environments.Evaluable with
      record
         Exec : System_Executor;
         Args : Formal_Argument_Vectors.Vector;
      end record;

end Abydos.System;
